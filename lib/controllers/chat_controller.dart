import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

import '../constants/app_constants.dart';
import '../constants/app_languages.dart';
import '../models/chat_message.dart';
import '../models/knowledge_document.dart';
import '../models/knowledge_overview.dart';
import '../models/knowledge_search_result.dart';
import '../services/knowledge_api.dart';

class ChatController extends GetxController {
  // ---------- State ----------
  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final isListening = false.obs;
  final isTranslating = false.obs;
  final hasText = false.obs;
  final selectedLang = defaultLanguage.obs;
  final originalText = ''.obs;
  final selectedAudioFileName = Rxn<String>();

  // ---------- Helpers ----------
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  final _speech = SpeechToText();
  final _translator = GoogleTranslator();
  final KnowledgeApi _knowledgeApi;
  late final Future<String> Function(String text) _translateKhmer;
  late final Future<String> Function(String text) _translateToKhmer;
  PlatformFile? _selectedAudioFile;
  bool _speechReady = false;
  bool _speechCompletionHandled = false;
  String? _greetingMessageId;

  ChatController({
    KnowledgeApi? knowledgeApi,
    Future<String> Function(String text)? translateKhmer,
    Future<String> Function(String text)? translateToKhmer,
  }) : _knowledgeApi = knowledgeApi ?? KnowledgeApi() {
    _translateKhmer = translateKhmer ?? _translateWithGoogle;
    _translateToKhmer = translateToKhmer ?? _translateWithGoogleToKhmer;
  }

  // ---------- Lifecycle ----------
  @override
  void onInit() {
    super.onInit();
    inputController.addListener(
      () => hasText.value = inputController.text.trim().isNotEmpty,
    );
    final greeting = ChatMessage.bot(
      AppStrings.greetingFor(selectedLang.value),
      responseLanguage: selectedLang.value,
    );
    messages.add(greeting);
    _greetingMessageId = greeting.id;
    _initSpeech();
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    _speech.cancel();
    _knowledgeApi.close();
    super.onClose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          isListening.value = false;
          _handleSpeechFinished();
        }
      },
      onError: (_) => isListening.value = false,
    );
  }

  // ---------- Language ----------
  void setLanguage(String code) {
    if (isListening.value) return; // locked while recording
    selectedLang.value = code;
    final greetingIndex = messages.indexWhere(
      (message) => message.id == _greetingMessageId,
    );
    if (greetingIndex >= 0) {
      final greeting = ChatMessage.bot(
        AppStrings.greetingFor(code),
        responseLanguage: code,
      );
      messages[greetingIndex] = greeting;
      _greetingMessageId = greeting.id;
    }
  }

  // ---------- Audio file ----------
  Future<void> pickAudioFile() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.audio);
      if (files.isNotEmpty) {
        final file = files.first;
        final size = await file.length();
        if (size == null || size <= 0) {
          Get.snackbar(
            'Invalid audio',
            'The selected file is empty or unreadable.',
          );
          return;
        }
        if (size > 25 * 1024 * 1024) {
          Get.snackbar('Audio too large', 'Choose an audio file up to 25 MB.');
          return;
        }
        _selectedAudioFile = file;
        selectedAudioFileName.value = file.name;
      }
    } on PlatformException catch (error) {
      Get.snackbar('File selection failed', error.message ?? error.code);
    }
  }

  void clearSelectedAudioFile() {
    _selectedAudioFile = null;
    selectedAudioFileName.value = null;
  }

  Future<KnowledgeDocument> loadKnowledge(
    String id, {
    bool translateToKhmer = false,
  }) async {
    final document = await _knowledgeApi.getKnowledge(id);
    if (!translateToKhmer) return document;

    final text = await Future.wait([
      _toKhmer(document.title),
      _toKhmer(document.description),
      ...document.segments.expand(
        (segment) => [
          _toKhmer(segment.title),
          _toKhmer(segment.summary),
          _toKhmer(segment.transcript),
        ],
      ),
    ]);
    var textIndex = 2;
    final segments = document.segments.map((segment) {
      final translated = KnowledgeDocumentSegment(
        id: segment.id,
        segmentIndex: segment.segmentIndex,
        title: text[textIndex++],
        summary: text[textIndex++],
        transcript: text[textIndex++],
        pageStart: segment.pageStart,
        pageEnd: segment.pageEnd,
        startTimeSeconds: segment.startTimeSeconds,
        endTimeSeconds: segment.endTimeSeconds,
      );
      return translated;
    }).toList();

    return KnowledgeDocument(
      id: document.id,
      title: text[0],
      description: text[1],
      sourceType: document.sourceType,
      sources: document.sources,
      segments: segments,
    );
  }

  // ---------- Voice: speak -> translate to English -> fill input ----------
  Future<void> toggleListening() async {
    if (!_speechReady) {
      Get.snackbar('Microphone', 'Speech recognition is not available.');
      return;
    }
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
      _handleSpeechFinished();
      return;
    }

    originalText.value = '';
    _speechCompletionHandled = false;
    isListening.value = true;
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: speechLocales[selectedLang.value],
      ),
      onResult: (r) {
        originalText.value = r.recognizedWords;
      },
    );
  }

  void _handleSpeechFinished() {
    if (_speechCompletionHandled) return;
    final text = originalText.value.trim();
    if (text.isEmpty) return;
    _speechCompletionHandled = true;
    originalText.value = '';
    submitVoiceTranscript(text);
  }

  // ---------- Send ----------
  Future<void> send() async {
    final text = inputController.text.trim();
    if (isTyping.value || isTranslating.value) return;

    if (text.isEmpty) {
      // only an audio file was chosen: there is no transcription endpoint yet
      if (_selectedAudioFile != null) {
        Get.snackbar(
          'Audio transcription unavailable',
          'Use the microphone to speak your question, or type it here.',
        );
      }
      return;
    }
    await _submitQuestion(text);
  }

  Future<void> submitVoiceTranscript(String transcript) async {
    final text = transcript.trim();
    if (text.isEmpty || isTyping.value || isTranslating.value) return;
    await _submitQuestion(text, fromVoice: true);
  }

  Future<void> _submitQuestion(String text, {bool fromVoice = false}) async {
    if (isTyping.value || isTranslating.value) return;
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }

    final spoken = originalText.value.trim(); // set when the user used voice
    final responseLanguage = _containsKhmer(text) || _containsKhmer(spoken)
        ? 'km'
        : 'en';
    isTyping.value = true;

    try {
      late final String english;
      final original = _containsKhmer(text)
          ? text
          : _containsKhmer(spoken)
          ? spoken
          : null;
      ChatMessage? voiceMessage;
      if (fromVoice) {
        voiceMessage = ChatMessage.user(
          text,
          original: original,
          responseLanguage: responseLanguage,
        );
        _add(voiceMessage);
      }

      if (_containsKhmer(text)) {
        english = await _toEnglish(text);
      } else {
        english = text;
      }

      if (!fromVoice) inputController.clear();
      originalText.value = '';
      clearSelectedAudioFile();
      if (voiceMessage == null) {
        _add(
          ChatMessage.user(
            english,
            original: original,
            responseLanguage: responseLanguage,
          ),
        );
      } else {
        final messageIndex = messages.indexWhere(
          (message) => message.id == voiceMessage!.id,
        );
        if (messageIndex >= 0) {
          messages[messageIndex] = ChatMessage(
            id: voiceMessage.id,
            text: english,
            sender: Sender.user,
            original: original,
            responseLanguage: responseLanguage,
          );
        }
      }
      _add(await _fetchReply(english, responseLanguage));
    } on QuestionTranslationException catch (error) {
      _add(
        ChatMessage.bot(
          responseLanguage == 'km'
              ? 'សូមអភ័យទោស មិនអាចបកប្រែចម្លើយជាភាសាខ្មែរបានទេ។ សូមព្យាយាមម្តងទៀត។'
              : AppStrings.error,
          responseLanguage: responseLanguage,
        ),
      );
      Get.snackbar('Translation failed', error.message);
    } on KnowledgeApiException catch (error) {
      _add(
        ChatMessage.bot(
          AppStrings.errorFor(responseLanguage),
          responseLanguage: responseLanguage,
        ),
      );
      Get.snackbar('Search failed', error.message);
    } catch (error) {
      _add(
        ChatMessage.bot(
          AppStrings.errorFor(responseLanguage),
          responseLanguage: responseLanguage,
        ),
      );
      Get.snackbar('Search failed', error.toString());
    } finally {
      isTyping.value = false;
    }
  }

  Future<String> _toEnglish(String text) async {
    if (!_containsKhmer(text)) return text;
    try {
      final translated = await _translateKhmer(text);
      if (translated.trim().isEmpty) {
        throw const QuestionTranslationException(
          'No English translation was returned.',
        );
      }
      return translated.trim();
    } catch (error) {
      if (error is QuestionTranslationException) rethrow;
      throw QuestionTranslationException(error.toString());
    }
  }

  Future<String> _translateWithGoogle(String text) async =>
      (await _translator.translate(text, from: 'km', to: 'en')).text;

  Future<String> _translateWithGoogleToKhmer(String text) async =>
      (await _translator.translate(text, from: 'en', to: 'km')).text;

  Future<String> _toKhmer(String text) async {
    final value = text.trim();
    if (value.isEmpty || _containsKhmer(value)) return value;
    try {
      final translated = await _translateToKhmer(value);
      if (translated.trim().isEmpty) {
        throw const QuestionTranslationException(
          'No Khmer translation was returned.',
        );
      }
      return translated.trim();
    } catch (error) {
      if (error is QuestionTranslationException) rethrow;
      throw QuestionTranslationException(error.toString());
    }
  }

  bool _containsKhmer(String text) => RegExp(r'[\u1780-\u17FF]').hasMatch(text);

  String _khmerStepLabel(int number) {
    const digits = '០១២៣៤៥៦៧៨៩';
    final khmerNumber = number
        .toString()
        .split('')
        .map((digit) => digits[int.parse(digit)])
        .join();
    return 'ជំហានទី$khmerNumber៖';
  }

  // ---------- Knowledge search ----------
  Future<ChatMessage> _fetchReply(
    String question,
    String responseLanguage,
  ) async {
    final overview = await _knowledgeApi.searchOverview(
      question: question,
      language: 'en',
    );
    final results = overview.results;
    if (results.isEmpty) {
      return ChatMessage.bot(
        AppStrings.noResultFor(responseLanguage),
        responseLanguage: responseLanguage,
      );
    }

    final summary = overview.summary?.trim() ?? '';
    final steps = overview.steps
        .map(
          (step) => (
            number: step.stepNumber,
            segmentId: step.segmentId,
            title: step.title.trim(),
            instruction: step.instruction.trim(),
          ),
        )
        .where((step) => step.title.isNotEmpty || step.instruction.isNotEmpty)
        .toList();
    var translatedSteps = steps;
    var displayResults = results;
    if (responseLanguage == 'km') {
      translatedSteps = await Future.wait(
        steps.map(
          (step) async => (
            number: step.number,
            segmentId: step.segmentId,
            title: await _toKhmer(step.title),
            instruction: await _toKhmer(step.instruction),
          ),
        ),
      );
      displayResults = await Future.wait(results.map(_translateResultToKhmer));
    }
    final displaySummary = summary.isEmpty
        ? ''
        : responseLanguage == 'km'
        ? await _toKhmer(summary)
        : summary;
    final displayOverview = responseLanguage == 'km'
        ? KnowledgeOverview(
            summary: displaySummary,
            steps: translatedSteps
                .map(
                  (step) => KnowledgeOverviewStep(
                    stepNumber: step.number,
                    title: step.title,
                    instruction: step.instruction,
                    segmentId: step.segmentId,
                  ),
                )
                .toList(),
            results: displayResults,
          )
        : overview;
    final answerParts = [
      if (displaySummary.isNotEmpty) displaySummary,
      ...translatedSteps.map(
        (step) => responseLanguage == 'km'
            ? '${_khmerStepLabel(step.number)} '
                  '${step.title}'
                  '${step.title.isNotEmpty && step.instruction.isNotEmpty ? '៖ ' : ''}'
                  '${step.instruction}'
            : 'Step ${step.number}: '
                  '${step.title}'
                  '${step.title.isNotEmpty && step.instruction.isNotEmpty ? ': ' : ''}'
                  '${step.instruction}',
      ),
    ];
    final answer = answerParts.join('\n\n');
    if (answer.isNotEmpty) {
      return ChatMessage.bot(
        answer,
        overview: displayOverview,
        searchResults: displayResults,
        responseLanguage: responseLanguage,
      );
    }

    var answers = results
        .map((result) {
          final summary = result.summary.trim();
          final transcript = result.transcript.trim();
          final title = result.title.trim().isNotEmpty
              ? result.title.trim()
              : result.knowledgeTitle.trim();
          final content = summary.isNotEmpty ? summary : transcript;

          if (content.isEmpty) return title;
          if (results.length == 1 || title.isEmpty) return content;
          return '$title: $content';
        })
        .where((answer) => answer.isNotEmpty)
        .toList();

    if (responseLanguage == 'km') {
      answers = await Future.wait(answers.map(_toKhmer));
    }
    if (answers.isEmpty) {
      return ChatMessage.bot(
        AppStrings.noResultFor(responseLanguage),
        responseLanguage: responseLanguage,
      );
    }
    return ChatMessage.bot(
      answers.join('\n\n'),
      overview: overview,
      searchResults: displayResults,
      responseLanguage: responseLanguage,
    );
  }

  Future<KnowledgeSearchResult> _translateResultToKhmer(
    KnowledgeSearchResult result,
  ) async {
    final values = await Future.wait([
      _toKhmer(result.title),
      _toKhmer(result.knowledgeTitle),
      _toKhmer(result.summary),
      _toKhmer(result.transcript),
    ]);
    return KnowledgeSearchResult(
      segmentId: result.segmentId,
      knowledgeId: result.knowledgeId,
      knowledgeTitle: values[1],
      sourceType: result.sourceType,
      segmentIndex: result.segmentIndex,
      title: values[0],
      summary: values[2],
      transcript: values[3],
      pageStart: result.pageStart,
      pageEnd: result.pageEnd,
      startTimeSeconds: result.startTimeSeconds,
      endTimeSeconds: result.endTimeSeconds,
      score: result.score,
      fileUrl: result.fileUrl,
    );
  }

  // ---------- Scroll ----------
  void _add(ChatMessage m) {
    messages.add(m);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class QuestionTranslationException implements Exception {
  final String message;

  const QuestionTranslationException(this.message);

  @override
  String toString() => message;
}

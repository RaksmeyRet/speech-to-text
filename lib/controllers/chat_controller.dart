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
  PlatformFile? _selectedAudioFile;
  bool _speechReady = false;
  String? _greetingMessageId;

  ChatController({
    KnowledgeApi? knowledgeApi,
    Future<String> Function(String text)? translateKhmer,
  }) : _knowledgeApi = knowledgeApi ?? KnowledgeApi() {
    _translateKhmer = translateKhmer ?? _translateWithGoogle;
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
      final greeting = ChatMessage.bot(AppStrings.greetingFor(code));
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

  Future<KnowledgeDocument> loadKnowledge(String id) =>
      _knowledgeApi.getKnowledge(id);

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
    isListening.value = true;
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: speechLocales[selectedLang.value],
      ),
      onResult: (r) {
        originalText.value = r.recognizedWords;
        if (r.finalResult) _translateToEnglish(r.recognizedWords);
      },
    );
  }

  void _handleSpeechFinished() {
    final text = originalText.value.trim();
    if (text.isNotEmpty && inputController.text.trim().isEmpty) {
      _translateToEnglish(text);
    }
  }

  Future<void> _translateToEnglish(String text) async {
    if (text.trim().isEmpty) return;

    if (selectedLang.value == 'en') {
      _setInput(text);
      return;
    }

    isTranslating.value = true;
    try {
      _setInput(await _toEnglish(text));
    } catch (_) {
      Get.snackbar('Translation failed', 'Check your internet and try again.');
    } finally {
      isTranslating.value = false;
    }
  }

  void _setInput(String text) {
    inputController.text = text;
    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
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
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }

    final spoken = originalText.value.trim(); // set when the user used voice
    isTyping.value = true;

    try {
      late final String english;
      String? original;
      if (_containsKhmer(text)) {
        english = await _toEnglish(text);
        original = text;
      } else {
        english = text;
        original = _containsKhmer(spoken) ? spoken : null;
      }

      inputController.clear();
      originalText.value = '';
      clearSelectedAudioFile();
      _add(ChatMessage.user(english, original: original));
      _add(await _fetchReply(english));
    } on QuestionTranslationException catch (error) {
      Get.snackbar('Translation failed', error.message);
    } on KnowledgeApiException catch (error) {
      _add(ChatMessage.bot(AppStrings.error));
      Get.snackbar('Search failed', error.message);
    } catch (error) {
      _add(ChatMessage.bot(AppStrings.error));
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

  bool _containsKhmer(String text) => RegExp(r'[\u1780-\u17FF]').hasMatch(text);

  // ---------- Knowledge search ----------
  Future<ChatMessage> _fetchReply(String question) async {
    final overview = await _knowledgeApi.searchOverview(
      question: question,
      language: selectedLang.value,
    );
    final results = overview.results;
    if (results.isEmpty) return ChatMessage.bot(AppStrings.noResult);

    final summary = overview.summary?.trim() ?? '';
    final steps = overview.steps
        .map((step) {
          final title = step.title.trim();
          final instruction = step.instruction.trim();
          final content = [
            title,
            instruction,
          ].where((part) => part.isNotEmpty).join(': ');
          return content.isEmpty ? '' : '${step.stepNumber}. $content';
        })
        .where((step) => step.isNotEmpty)
        .join('\n');
    final answer = [
      summary,
      steps,
    ].where((part) => part.isNotEmpty).join('\n\n');
    if (answer.isNotEmpty) {
      return ChatMessage.bot(
        answer,
        overview: overview,
        searchResults: results,
      );
    }

    final answers = results
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

    if (answers.isEmpty) return ChatMessage.bot(AppStrings.noResult);
    return ChatMessage.bot(
      answers.join('\n\n'),
      overview: overview,
      searchResults: results,
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

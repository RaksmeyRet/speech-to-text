import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

import '../constants/app_constants.dart';
import '../constants/app_languages.dart';
import '../models/chat_message.dart';
import '../models/video_segment.dart';

class ChatController extends GetxController {
  // ---------- State ----------
  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final isListening = false.obs;
  final isTranslating = false.obs;
  final hasText = false.obs;
  final selectedLang = defaultLanguage.obs;
  final originalText = ''.obs;

  // ---------- Helpers ----------
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  final _speech = SpeechToText();
  final _translator = GoogleTranslator();
  final _segments = <VideoSegment>[];
  bool _speechReady = false;

  // ---------- Lifecycle ----------
  @override
  void onInit() {
    super.onInit();
    inputController.addListener(
      () => hasText.value = inputController.text.trim().isNotEmpty,
    );
    messages.add(ChatMessage.bot(AppStrings.greeting));
    _initSpeech();
    _loadSegments();
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    _speech.cancel();
    super.onClose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') isListening.value = false;
      },
      onError: (_) => isListening.value = false,
    );
  }

  Future<void> _loadSegments() async {
    try {
      final raw = await rootBundle.loadString(AppConfig.segmentsAsset);
      _segments.addAll(
        (jsonDecode(raw) as List).map(
          (e) => VideoSegment.fromJson(e as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      // no segments file: replies fall back to the dummy text
    }
  }

  // ---------- Language ----------
  void setLanguage(String code) {
    if (isListening.value) return; // locked while recording
    selectedLang.value = code;
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

  Future<void> _translateToEnglish(String text) async {
    if (text.trim().isEmpty) return;

    if (selectedLang.value == 'en') {
      _setInput(text);
      return;
    }

    isTranslating.value = true;
    try {
      final result = await _translator.translate(
        text,
        from: selectedLang.value,
        to: 'en',
      );
      _setInput(result.text);
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
    if (text.isEmpty || isTyping.value || isTranslating.value) return;
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }

    final spoken = originalText.value.trim(); // set when the user used voice
    inputController.clear();
    originalText.value = '';
    isTyping.value = true;

    String english = text;
    String? original = spoken.isNotEmpty ? spoken : null;

     // Typed text: auto-detect the language and translate to English
    if (original == null) {
      try {
        final r = await _translator.translate(text, to: 'en');
        if (r.sourceLanguage.code != 'en') {
          english = r.text;
          original = text;
        }
      } catch (_) {
        // offline: keep the text as typed
      }
    }
    _add(ChatMessage.user(english, original: original));

    try {
      _add(await _fetchReply(english));
    } catch (_) {
      _add(ChatMessage.bot(AppStrings.error));
    } finally {
      isTyping.value = false;
    }
  }

  // ---------- Reply (dummy now; replace with Django later) ----------
  Future<ChatMessage> _fetchReply(String question) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final found = _matchMany(question);
    if (found.isEmpty) {
      return ChatMessage.bot('This is a dummy reply to: "$question"');
    }

    final text = found.length == 1
        ? found.first.summary
        : 'I found ${found.length} clips that can help:';
    return ChatMessage.bot(
      text,
      videoUrl: AppConfig.demoVideoUrl,
      segments: found,
    );
  }

  List<VideoSegment> _matchMany(String question) {
    final words = question
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2 && !AppConfig.stopWords.contains(w))
        .toSet();

    final scored = <MapEntry<VideoSegment, int>>[];
    for (final s in _segments) {
      final searchText = [
        s.title,
        ...s.keywords,
        ...s.possibleQuestions,
      ].join(' ').toLowerCase();
      final score = words.where(searchText.contains).length;
      if (score > 0) scored.add(MapEntry(s, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored
        .take(AppConfig.maxSegmentsPerAnswer)
        .map((e) => e.key)
        .toList();
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

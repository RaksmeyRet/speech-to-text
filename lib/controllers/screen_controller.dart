import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

class ScreenController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();

  final isTextMode = false.obs;

  // Speak mode: Khmer -> English only
  final lang = 'km'.obs;

  // Type mode: any language
  final textFrom = 'en'.obs;
  final textTo = 'km'.obs;

  final inputController = TextEditingController();
  Timer? _debounce;

  final isAvailable = false.obs;
  final isListening = false.obs;
  final text = ''.obs;
  final localeId = 'km_KH'.obs;
  final locales = <LocaleName>[].obs;
  final _translator = GoogleTranslator();
  final translatedText = ''.obs;
  final isTranslating = false.obs;

  String get sourceCode => isTextMode.value ? textFrom.value : lang.value;
  String get targetCode => isTextMode.value ? textTo.value : 'en';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final ok = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (error) {
        isListening.value = false;
        Get.snackbar('Speech recognition error', error.errorMsg);
      },
    );
    isAvailable.value = ok;
    if (ok) {
      locales.assignAll(await _speechToText.locales());
      localeId.value = _findLocale('km') ?? 'km_KH';
      lang.value = 'km';
    }
  }

  String? _findLocale(String code) {
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(code)) return l.localeId;
    }
    return null;
  }

  Future<void> translateText(String text) async {
    if (text.trim().isEmpty) return;
    isTranslating.value = true;
    try {
      final result = await _translator.translate(
        text,
        from: sourceCode,
        to: targetCode,
      );
      translatedText.value = result.text;
    } catch (e) {
      translatedText.value = 'Translation failed. Check internet.';
    } finally {
      isTranslating.value = false;
    }
  }

  // ---------- Mode ----------
  Future<void> setMode(bool textMode) async {
    if (isListening.value) await stop();
    _debounce?.cancel();
    inputController.clear();
    text.value = '';
    translatedText.value = '';
    isTextMode.value = textMode;
  }

  // ---------- Speak mode ----------
  Future<void> _listen() async {
    isListening.value = true;
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId.value,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 5),
      ),
      onResult: (result) {
        text.value = result.recognizedWords;
        if (result.finalResult) {
          translateText(result.recognizedWords);
        }
      },
    );
  }

  Future<void> start() async {
    if (isListening.value) return;

    text.value = '';
    translatedText.value = '';

    if (!isAvailable.value) {
      Get.snackbar(
        'Not available',
        'Speech recognition is not available. Please allow microphone access.',
      );
      return;
    }

    if (!await _speechToText.hasPermission) {
      Get.snackbar(
        'Microphone permission',
        'Please allow access to the microphone in your device settings.',
      );
      return;
    }

    await _listen();
  }

  Future<void> stop() async {
    if (isListening.value) {
      await _speechToText.stop();
    }
    isListening.value = false;
  }

  Future<void> toggle() async {
    if (isListening.value) {
      await stop();
    } else {
      await start();
    }
  }

  // ---------- Type mode ----------
  void onTyped(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      text.value = '';
      translatedText.value = '';
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () {
      text.value = v;
      translateText(v);
    });
  }

  void _retranslate() {
    final v = inputController.text;
    if (v.trim().isEmpty) {
      translatedText.value = '';
    } else {
      translateText(v);
    }
  }

  void setTextFrom(String code) {
    if (code == textTo.value) textTo.value = textFrom.value;
    textFrom.value = code;
    _retranslate();
  }

  void setTextTo(String code) {
    if (code == textFrom.value) textFrom.value = textTo.value;
    textTo.value = code;
    _retranslate();
  }

  // swap works in Type mode only
  Future<void> swap() async {
    if (!isTextMode.value) return;
    final old = textFrom.value;
    textFrom.value = textTo.value;
    textTo.value = old;
    _retranslate();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _speechToText.cancel();
    inputController.dispose();
    super.onClose();
  }
}
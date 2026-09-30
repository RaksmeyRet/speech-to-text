import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ScreenController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();

  final isAvailable = false.obs;
  final isListening = false.obs;
  final text = ''.obs;
  final lang = 'en'.obs; // 'en' or 'km'
  final localeId = 'en_US'.obs;
  final locales = <LocaleName>[].obs;

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
      final en = _findLocale('en');
      if (en != null) {
        localeId.value = en;
      } else {
        localeId.value = 'en_US';
      }
      lang.value = 'en';
    }
  }

  String? _findLocale(String code) {
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(code)) return l.localeId;
    }
    return null;
  }

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
      },
    );
  }

  Future<void> start() async {
    if (isListening.value) return;

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

  Future<void> setLanguage(String code) async {
    if (isListening.value) await stop();

    final id = _findLocale(code);
    if (id == null) {
      if (locales.isNotEmpty) {
        Get.snackbar(
          'Not supported',
          'This language is not available on your phone',
        );
        return;
      }

      localeId.value = code == 'km' ? 'km_KH' : 'en_US';
      lang.value = code;
      return;
    }

    localeId.value = id;
    lang.value = code;
  }

  @override
  void onClose() {
    _speechToText.cancel();
    super.onClose();
  }
}

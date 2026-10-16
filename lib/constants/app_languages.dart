const Map<String, String> appLanguages = {
  'en': 'English',
  'km': 'Khmer',
  'zh-cn': 'Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'vi': 'Vietnamese',
  'fr': 'French',
};

// speech_to_text needs locale ids, not translator codes
const Map<String, String> speechLocales = {
  'en': 'en_US',
  'km': 'km_KH',
  'zh-cn': 'zh_CN',
  'ja': 'ja_JP',
  'ko': 'ko_KR',
  'vi': 'vi_VN',
  'fr': 'fr_FR',
};

const String defaultLanguage = 'km';
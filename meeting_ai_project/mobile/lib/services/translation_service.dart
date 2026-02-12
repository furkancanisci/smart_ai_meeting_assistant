import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static const String _languageKey = 'selected_language';
  
  final Map<String, Map<String, String>> _translations = {
    'tr': {
      'profile': 'Profil',
      'record': 'Kayıt',
      'history': 'Geçmiş',
      'ai_assistant': 'AI Asistan',
      'settings': 'Ayarlar',
      'user_profile': 'Kullanıcı Profili',
      'pro_member': 'Pro Üye',
      'assistant_settings': 'Asistan Ayarları',
      'language_setting': 'Dil Ayarı',
      'smart_voice_alerts': 'Smart Sesli Uyarılar',
      'voice_profile_intro': 'Toplantılarda seni tanıması için sesini kaydet.',
      'calendar_integration': 'Takvim Entegrasyonu',
      'logout': 'Çıkış Yap',
      'logout_confirmation': 'Hesabınızdan çıkmak istediğinizden emin misiniz?',
      'cancel': 'İptal',
      'secure_logout': 'Hesabınızdan güvenli çıkış yapın',
      'start_listening': 'Dinlemeye Başla',
      'listening': 'Dinliyorum...',
      'analyzing': 'Analiz Ediliyor...',
      'analysis_complete': 'Analiz Tamamlandı',
      'meeting_summary': 'Toplantı Özeti',
      'smart_ai': 'Smart AI',
      'chat_with_assistant': 'Smart AI Asistan ile konuşmaya başla!',
      'ask_questions_copy': 'Sorularını sor, cevaplarını kopyala!',
      'message_hint': 'Mesajını yaz...',
      'copy': 'Kopyala',
      'copied': 'Metin kopyalandı!',
      'global_assistant': 'Global Asistan',
      'meeting_assistant': 'Toplantı Asistanı',
      'notification_reminder': 'Bildirim sorununu çöz için 2 gün kaldı',
    },
    'en': {
      'profile': 'Profile',
      'record': 'Record',
      'history': 'History',
      'ai_assistant': 'AI Assistant',
      'settings': 'Settings',
      'user_profile': 'User Profile',
      'pro_member': 'Pro Member',
      'assistant_settings': 'Assistant Settings',
      'language_setting': 'Language Setting',
      'smart_voice_alerts': 'Smart Voice Alerts',
      'voice_profile_intro': 'Record your voice so meetings can recognize you.',
      'calendar_integration': 'Calendar Integration',
      'logout': 'Logout',
      'logout_confirmation': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'secure_logout': 'Secure logout from your account',
      'start_listening': 'Start Listening',
      'listening': 'Listening...',
      'analyzing': 'Analyzing...',
      'analysis_complete': 'Analysis Complete',
      'meeting_summary': 'Meeting Summary',
      'smart_ai': 'Smart AI',
      'chat_with_assistant': 'Start chatting with Smart AI Assistant!',
      'ask_questions_copy': 'Ask questions, copy answers!',
      'message_hint': 'Type your message...',
      'copy': 'Copy',
      'copied': 'Text copied!',
      'global_assistant': 'Global Assistant',
      'meeting_assistant': 'Meeting Assistant',
      'notification_reminder': '2 days left to solve notification issue',
    },
    'de': {
      'profile': 'Profil',
      'record': 'Aufnahme',
      'history': 'Verlauf',
      'ai_assistant': 'KI Assistent',
      'settings': 'Einstellungen',
      'user_profile': 'Benutzerprofil',
      'pro_member': 'Pro Mitglied',
      'assistant_settings': 'Assistent-Einstellungen',
      'language_setting': 'Spracheinstellung',
      'smart_voice_alerts': 'Smart Sprachbenachrichtigungen',
      'voice_profile_intro': 'Nimm deine Stimme auf, damit Meetings dich erkennen können.',
      'calendar_integration': 'Kalender-Integration',
      'logout': 'Abmelden',
      'logout_confirmation': 'Möchten Sie sich wirklich abmelden?',
      'cancel': 'Abbrechen',
      'secure_logout': 'Sichere Abmeldung von Ihrem Konto',
      'start_listening': 'Zuhören starten',
      'listening': 'Höre zu...',
      'analyzing': 'Analysiere...',
      'analysis_complete': 'Analyse Abgeschlossen',
      'meeting_summary': 'Meeting-Zusammenfassung',
      'smart_ai': 'Smart AI',
      'chat_with_assistant': 'Beginne zu chatten mit Smart KI Assistent!',
      'ask_questions_copy': 'Stelle Fragen, kopiere Antworten!',
      'message_hint': 'Nachricht eingeben...',
      'copy': 'Kopieren',
      'copied': 'Text kopiert!',
      'global_assistant': 'Global Assistent',
      'meeting_assistant': 'Meeting Assistent',
      'notification_reminder': '2 Tage übrig, um das Benachrichtigungsproblem zu lösen',
    },
  };

  Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'tr';
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  String translate(String key, {String? languageCode}) {
    final lang = languageCode ?? _translations.keys.first;
    return _translations[lang]?[key] ?? _translations['tr']?[key] ?? key;
  }

  // Static method for easy access
  static String t(String key, {String? languageCode}) {
    final service = TranslationService();
    return service.translate(key, languageCode: languageCode);
  }
}

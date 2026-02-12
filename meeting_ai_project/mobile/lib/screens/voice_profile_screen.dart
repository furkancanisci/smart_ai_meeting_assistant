import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../main.dart';
import 'login_screen.dart';

class VoiceProfileScreen extends StatefulWidget {
  const VoiceProfileScreen({super.key});

  @override
  State<VoiceProfileScreen> createState() => _VoiceProfileScreenState();
}

class _VoiceProfileScreenState extends State<VoiceProfileScreen> {
  bool _isVoiceEnabled = true;
  bool _isCalendarEnabled = false; // Takvim entegrasyonu durumu
  String _selectedLanguage = 'tr';
  final ApiService _apiService = ApiService();
  final TranslationService _translationService = TranslationService();
  
  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Ayarları Yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVoiceEnabled = prefs.getBool('smart_voice_enabled') ?? true;
      _isCalendarEnabled = prefs.getBool('calendar_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'tr';
    });
  }

  // Ayarı Kaydet
  Future<void> _toggleVoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_voice_enabled', value);
    setState(() {
      _isVoiceEnabled = value;
    });
  }

  // Takvim Entegrasyonunu Aç/Kapat
  Future<void> _toggleCalendar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_enabled', value);
    setState(() {
      _isCalendarEnabled = value;
    });
  }

  // Dil Değiştir
  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  // Logout
  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translationService.translate('profile', languageCode: _selectedLanguage)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // PROFİL KARTI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                  child: const Icon(Icons.person, size: 32, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_translationService.translate('user_profile', languageCode: _selectedLanguage), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_translationService.translate('pro_member', languageCode: _selectedLanguage), style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text(_translationService.translate('assistant_settings', languageCode: _selectedLanguage).toUpperCase(), style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // --- DİL AYARI ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF6C63FF), size: 20),
                  ),
                  title: Text(_translationService.translate('language_setting', languageCode: _selectedLanguage), style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _languages.firstWhere((lang) => lang['code'] == _selectedLanguage)['name']!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _languages.firstWhere((lang) => lang['code'] == _selectedLanguage)['flag']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Language Options
                ..._languages.map((language) => RadioListTile<String>(
                  value: language['code']!,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      _changeLanguage(value);
                    }
                  },
                  title: Row(
                    children: [
                      Text(language['flag']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(language['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  activeColor: const Color(0xFF6C63FF),
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- SESLİ BİLDİRİM AYARI ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: const Color(0xFF6C63FF),
                  title: Text(_translationService.translate('smart_voice_alerts', languageCode: _selectedLanguage), style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text("Uygulama açılışında ve sohbetlerde sesli yanıt verir.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, 
                      color: const Color(0xFF6C63FF)
                    ),
                  ),
                  value: _isVoiceEnabled,
                  onChanged: _toggleVoice,
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  title: const Text("Ses Profili Tanıt"),
                  subtitle: const Text("Toplantılarda seni tanıması için sesini kaydet."),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.record_voice_over_rounded, color: Colors.orange),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Buraya ileride Ses Tanıtma ekranı gelecek
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çok yakında!")));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text("UYGULAMA", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: const Text("Takvim Entegrasyonu"),
              leading: const Icon(Icons.calendar_today_rounded, color: Colors.blue),
              trailing: Switch(
                value: _isCalendarEnabled, 
                onChanged: _toggleCalendar,
                activeColor: const Color(0xFF6C63FF),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // --- ÇIKIŞ BUTONU ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              title: Text(_translationService.translate('logout', languageCode: _selectedLanguage), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: Text(_translationService.translate('secure_logout', languageCode: _selectedLanguage), style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_translationService.translate('logout', languageCode: _selectedLanguage)),
                    content: Text(_translationService.translate('logout_confirmation', languageCode: _selectedLanguage)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(_translationService.translate('cancel', languageCode: _selectedLanguage)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _logout();
                        },
                        child: Text(_translationService.translate('logout', languageCode: _selectedLanguage), style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
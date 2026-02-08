import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceProfileScreen extends StatefulWidget {
  const VoiceProfileScreen({super.key});

  @override
  State<VoiceProfileScreen> createState() => _VoiceProfileScreenState();
}

class _VoiceProfileScreenState extends State<VoiceProfileScreen> {
  bool _isVoiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Ayarları Yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVoiceEnabled = prefs.getBool('terra_voice_enabled') ?? true;
    });
  }

  // Ayarı Kaydet
  Future<void> _toggleVoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terra_voice_enabled', value);
    setState(() {
      _isVoiceEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar main.dart içinde tanımlı olduğu için buraya gerek yok, body direkt başlar
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kullanıcı Profili", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Pro Üye", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("ASİSTAN AYARLARI", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

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
                  title: const Text("Terra Sesli Uyarılar", style: TextStyle(fontWeight: FontWeight.w500)),
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
              trailing: Switch(value: false, onChanged: (val) {}), // Şimdilik dummy
            ),
          ),
        ],
      ),
    );
  }
}
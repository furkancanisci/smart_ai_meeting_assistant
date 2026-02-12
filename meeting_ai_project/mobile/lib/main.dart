import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:add_2_calendar/add_2_calendar.dart'; 

import 'services/api_service.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'screens/voice_profile_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // Bildirim Servisini Başlat
  await NotificationService().init();

  final apiService = ApiService();
  final bool isLoggedIn = await apiService.checkLoginStatus();

  runApp(MyApp(startScreen: isLoggedIn ? const MainContainer() : const LoginScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          background: const Color(0xFFF9F9FB),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF2D2D3A), 
            fontSize: 20, 
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: startScreen,
    );
  }
}

// --- ANA İSKELET ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService(); 
  final FlutterTts _flutterTts = FlutterTts();

  final List<Widget> _pages = [
    const RecordPage(),
    const HistoryPage(),
    const ChatScreen(),
    const VoiceProfileScreen(), 
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    
    // Uygulama açılınca sırayla kontrol et
    Future.delayed(const Duration(seconds: 1), () async {
      // 1. Önce Pil Ayarını Garantiye Al
      await _forceDisableBatteryOptimization();
      
      // 2. Sonra diğer izinlere bak (Bildirim vs.)
      await _checkCriticalPermissions();
      
      // 3. Veri çekme işlemi RecordPage içinde yapılacak
      print("🚀 Smart AI hazır! Bildirim sistemi aktif.");
    });
  }

  // --- GARANTİ ÇÖZÜM: PİL KISITLAMASINI KALDIR ---
  Future<void> _forceDisableBatteryOptimization() async {
    // 1. Durumu Kontrol Et
    // "ignoreBatteryOptimizations" izni "Granted" ise, kısıtlama YOK demektir (İyi durum).
    // "Denied" veya "Restricted" ise, pil tasarrufu açık demektir (Kötü durum).
    var status = await Permission.ignoreBatteryOptimizations.status;

    if (!status.isGranted) {
      if (!mounted) return;

      // 2. Kullanıcıya Bilgi Ver ve Yönlendir
      await showDialog(
        context: context,
        barrierDismissible: false, // Boşluğa basınca kapanmasın (ZORUNLU)
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_alert_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text("Kritik Ayar Gerekli"),
            ],
          ),
          content: const Text(
            "SmartAI'in size zamanında bildirim gönderebilmesi için 'Pil Kısıtlaması'nın kaldırılması gerekiyor.\n\n"
            "Açılacak pencerede SmartAI'i bulup 'Kısıtlama Yok' veya 'İzin Ver' seçeneğini işaretleyin.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context); // Dialogu kapat
                
                // 3. DİREKT AYAR SAYFASINI AÇ
                // Bu komut telefonun "Pil Optimizasyonunu Yoksay" penceresini açar.
                await Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text("Ayarları Düzelt"),
            ),
          ],
        ),
      );
    }
  }

  // --- KRİTİK İZİNLERİ KONTROL ET ---
  Future<void> _checkCriticalPermissions() async {
    // 1. Bildirim İzni (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Alarm ve Zamanlama İzni (Android 12+)
    // Bu izin "Schedule Exact Alarm" iznidir. Eğer verilmezse zamanlı bildirim çalışmaz.
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    // Eğer hala izin verilmediyse kullanıcıyı bilgilendir
    if (await Permission.scheduleExactAlarm.isDenied) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Hatırlatıcılar İçin İzin Gerekli"),
          content: const Text(
            "Smart AI'in size görev zamanında bildirim gönderebilmesi için 'Alarm ve Hatırlatıcı' iznine ihtiyacı var. Lütfen açılan ekranda izin verin."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Daha Sonra"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Direkt ayar sayfasını açar
              },
              child: const Text("Ayarları Aç"),
            ),
          ],
        ),
      );
    }
    
    // 3. Ses kayıt izni kontrolü
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  // --- GLOBAL CHAT PENCERESİ ---
  void _showGlobalChat(BuildContext context) async {
    TextEditingController _chatController = TextEditingController();
    List<Map<String, String>> _chatHistory = [];
    bool _isLoading = false;
    
    final prefs = await SharedPreferences.getInstance();
    final bool isVoiceEnabled = prefs.getBool('smart_voice_enabled') ?? true;

    _flutterTts.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF6C63FF),
                        child: Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Smart Asistan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            isVoiceEnabled ? "Sesli yanıt açık" : "Sessiz mod", 
                            style: TextStyle(fontSize: 12, color: isVoiceEnabled ? Colors.green : Colors.grey)
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close), 
                        onPressed: () {
                          _flutterTts.stop();
                          Navigator.pop(context);
                        }
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _chatHistory.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spatial_audio_off_rounded, size: 60, color: Colors.grey[200]),
                          const SizedBox(height: 10),
                          const Text("Sorunu yaz, Smart cevaplasın.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _chatHistory[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF6C63FF) : Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                            child: Text(msg['text']!, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                          ),
                        );
                      },
                    ),
                ),

                if (_isLoading) const LinearProgressIndicator(color: Color(0xFF6C63FF), backgroundColor: Colors.white),

                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16, 
                    left: 16, right: 16, top: 8
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: "Bir şeyler sor...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onSubmitted: (val) async {}, 
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF6C63FF),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () async {
                          final text = _chatController.text.trim();
                          if (text.isEmpty) return;

                          setModalState(() {
                            _chatHistory.add({"role": "user", "text": text});
                            _isLoading = true;
                          });
                          _chatController.clear();
                          _flutterTts.stop();

                          final answer = await _apiService.askGlobalBot(text);

                          if (mounted) {
                            setModalState(() {
                              _isLoading = false;
                              _chatHistory.add({"role": "bot", "text": answer ?? "Bağlantı hatası."});
                            });

                            if (isVoiceEnabled && answer != null && answer.isNotEmpty) {
                              await _flutterTts.speak(answer);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      _flutterTts.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF6C63FF).withOpacity(0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.mic_none_rounded),
              selectedIcon: Icon(Icons.mic_rounded, color: Color(0xFF6C63FF)),
              label: 'Kayıt',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF6C63FF)),
              label: 'Geçmiş',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF6C63FF)),
              label: 'AI Asistan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6C63FF)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: KAYIT EKRANI (DÜZENLENDİ: İÇERİK KARTLARI EKLENDİ) ---
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TranslationService _translationService = TranslationService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isCalendarEnabled = false; // Takvim entegrasyonu durumu
  
  File? _audioFile;
  String? _audioPath;
  Map<String, dynamic>? _result;
  List<dynamic> _smartNudges = []; // Dürtme Mesajları
  bool _isLoadingNudges = true;
  int _currentNudgeIndex = 0; // Hangi nudge'ın okunduğunu takip et
  
  // Eksik değişkenler
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _selectedLanguage = 'tr';
  String _statusMessage = 'Başlatılıyor...';

  Future<void> _loadLanguage() async {
    final language = await _translationService.getCurrentLanguage();
    if (mounted) {
      setState(() {
        _selectedLanguage = language;
        _statusMessage = _translationService.translate('start_listening', languageCode: language);
      });
    }
  }

  // Takvim ayarlarını yükle
  Future<void> _loadCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCalendarEnabled = prefs.getBool('calendar_enabled') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadCalendarSettings(); // Takvim ayarlarını yükle
    _requestPermissions();
    _loadSmartNudges(); // Açılışta verileriçek
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // YENİ: Belirli bir nudge'ı sesli oku
  Future<void> _speakNudge(int index) async {
    if (_smartNudges.isEmpty || index >= _smartNudges.length) return;
    
    final prefs = await SharedPreferences.getInstance();
    final bool isVoiceEnabled = prefs.getBool('smart_voice_enabled') ?? true;
    final String selectedLanguage = prefs.getString('selected_language') ?? 'tr';
    
    if (isVoiceEnabled) {
      // Önceki konuşmayı durdur
      await _flutterTts.stop();
      
      String msg = _smartNudges[index]['message'] ?? "";
      await _flutterTts.setLanguage(selectedLanguage == 'tr' ? "tr-TR" : selectedLanguage == 'de' ? "de-DE" : "en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(msg); // Sadece mesajı oku, "hatırlatıcı" deme
    }
  }

  // --- TAKVİME EKLEME FONKSİYONU (RECORD PAGE İÇİN) ---
  void _addToCalendar(Map<String, dynamic> task) {
    String title = task['description'] ?? "Görev";
    String dateStr = task['due_date'];
    
    // Eğer tarih yoksa ekleme yapma
    if (dateStr == null || dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu görevin tarihi yok!")));
      return;
    }

    try {
      // Tarihi Parse Et
      DateTime dueDate = DateTime.parse(dateStr);
      
      final Event event = Event(
        title: "Smart Görevi: $title",
        description: "Bu görev Smart Asistan tarafından oluşturuldu.\nToplantı ID: Kayıt",
        location: 'Ofis / Online',
        startDate: dueDate,
        endDate: dueDate.add(const Duration(hours: 1)),
        iosParams: const IOSParams(reminder: Duration(minutes: 30)),
        androidParams: const AndroidParams(emailInvites: []),
      );

      Add2Calendar.addEvent2Cal(event);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tarih formatı hatası: $e")));
    }
  }

  // YENİ: Smart Verilerini Çek ve UI'da Göster
  Future<void> _loadSmartNudges() async {
    print("🔄 SMART NUDGES YÜKLENİYOR...");
    // 1. API'den tüm verileri çek
    // Not: getNudges() backend tarafında zaten "status != completed" olanları getiriyordu.
    // Backend'de "30 günlük" pencere açtığımız için veri gelecektir.
    final nudges = await _apiService.getNudges();
    
    final prefs = await SharedPreferences.getInstance();
    final bool isVoiceEnabled = prefs.getBool('smart_voice_enabled') ?? true;
    final String selectedLanguage = prefs.getString('selected_language') ?? 'tr';
    
    print("📊 GELEN NUDGE SAYISI: ${nudges.length}");
    
    // --- YENİ SİSTEM: LİSTEYİ KOMPLE GÖNDER ---
    // SmartAI servisi, bu liste içinden sadece 10 gün kalanları seçecek
    // ve saat 15:45'e (veya hemen sonrasına) alarm kuracak.
    final notifService = NotificationService();
    await notifService.scheduleDailyStatusCheck(nudges); 
    // ------------------------------------------

    if (mounted) {
      setState(() {
        _smartNudges = nudges;
        _isLoadingNudges = false;
        _currentNudgeIndex = 0; // İlk nudge'dan başla
      });

      // Eğer ses açıksa ve veri varsa, ilk nudge'ı oku
      if (nudges.isNotEmpty && isVoiceEnabled) {
        await _speakNudge(0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.storage].request();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/meeting_rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      const config = RecordConfig(encoder: AudioEncoder.wav);
      
      await _audioRecorder.start(config, path: filePath);
      
      setState(() {
        _isRecording = true;
        _statusMessage = _translationService.translate('listening', languageCode: _selectedLanguage);
        _result = null;
      });
    } else {
      _requestPermissions();
    }
  }

  Future<void> _stopRecordingAndUpload() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isUploading = true;
      _statusMessage = _translationService.translate('analyzing', languageCode: _selectedLanguage);
    });

    if (path != null) {
      int? meetingId = await _apiService.uploadMeeting(path);
      
      if (meetingId != null) {
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(seconds: 2));
          var details = await _apiService.getMeetingDetails(meetingId);
          
          if (details != null && details['status'] == 'completed') {
            if (mounted) {
              setState(() {
                _result = details;
                _isUploading = false;
                _statusMessage = _translationService.translate('analysis_complete', languageCode: _selectedLanguage);
              });
            }
            return;
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _isUploading = false;
        _statusMessage = "İşlem zaman aşımına uğradı.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Smart AI")),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Spacer(flex: 1), // Üst boşluk
            
            // --- MİKROFON BUTONU ---
            GestureDetector(
              onTap: _isRecording ? _stopRecordingAndUpload : _startRecording,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _scaleAnimation.value : 1.0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isRecording 
                              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5253)] 
                              : [const Color(0xFF6C63FF), const Color(0xFF3F3D56)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : const Color(0xFF6C63FF)).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 TEST BUTONU
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              icon: const Icon(Icons.notifications_active),
              label: const Text("TEST BİLDİRİMİ GÖNDER"),
              onPressed: () async {
                await NotificationService().showImmediateNotification();
              },
            ),
            const SizedBox(height: 30),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusMessage,
                key: ValueKey(_statusMessage),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ),
            
            if (_isUploading) ...[
              const SizedBox(height: 20),
              const SizedBox(
                width: 40, 
                height: 40, 
                child: CircularProgressIndicator(strokeWidth: 3)
              ),
            ],

            const Spacer(flex: 1),
            
            // --- SMART INSIGHTS (KARTLAR) ---
            if (!_isRecording && !_isUploading && _smartNudges.isNotEmpty)
              Container(
                height: 160, // Kart yüksekliği
                margin: const EdgeInsets.only(bottom: 30),
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.85),
                  itemCount: _smartNudges.length,
                  onPageChanged: (index) {
                    // Kullanıcı yana kaydırınca yeni nudge'ı sesli oku
                    setState(() {
                      _currentNudgeIndex = index;
                    });
                    _speakNudge(index);
                  },
                  itemBuilder: (context, index) {
                    var item = _smartNudges[index];
                    bool isCritical = item['priority'] == 'critical';
                    bool isHigh = item['priority'] == 'high';
                    
                    Color cardColor = isCritical ? const Color(0xFFFFEBEE) : (isHigh ? const Color(0xFFFFF3E0) : Colors.white);
                    Color accentColor = isCritical ? Colors.red : (isHigh ? Colors.orange : const Color(0xFF6C63FF));
                    IconData icon = isCritical ? Icons.warning_rounded : (isHigh ? Icons.access_time_filled : Icons.lightbulb);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isCritical ? "ACİL DURUM" : (isHigh ? "DİKKAT" : "HATIRLATMA"),
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                "${index + 1}/${_smartNudges.length}",
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              item['message'] ?? "",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w500
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
            // Sayfa göstergesi (noktalar)
            if (_smartNudges.length > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _smartNudges.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentNudgeIndex 
                            ? const Color(0xFF6C63FF) 
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
              
            // Eğer Toplantı Sonucu Geldiyse Göster
             if (_result != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_translationService.translate('meeting_summary', languageCode: _selectedLanguage), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => setState(() => _result = null),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: (_result!['action_items'] as List).length,
                          itemBuilder: (context, index) {
                            var task = _result!['action_items'][index];
                            String assignee = task['assignee_name'] ?? "Belirsiz";
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                    child: Text(
                                      assignee.isNotEmpty ? assignee[0] : "?",
                                      style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(task['description'] ?? "", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        if(task['due_date'] != null)
                                          Text("📅 ${task['due_date']}", style: TextStyle(color: Colors.red[300], fontSize: 12))
                                        else
                                          Text("Sorumlu: $assignee", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  // SAĞ TARAFTAKİ TAKVİM BUTONU
                                  if (_isCalendarEnabled && task['due_date'] != null && task['due_date'].toString().isNotEmpty) // Sadece takvim aktifse ve tarihi olanlarda göster
                                    IconButton(
                                      icon: const Icon(Icons.event_available_rounded, color: Colors.blueAccent),
                                      tooltip: "Takvime Ekle",
                                      onPressed: () => _addToCalendar(task),
                                    ),
                                  // Debug için tarih kontrolü - HER ZAMAN GÖSTER
                                  IconButton(
                                    icon: const Icon(Icons.calendar_today, color: Colors.red),
                                    tooltip: "DEBUG: Tarih Durumu",
                                    onPressed: () {
                                      print("=== DEBUG INFO ===");
                                      print("Task due_date: ${task['due_date']}");
                                      print("Task due_date type: ${task['due_date'].runtimeType}");
                                      print("Task due_date isNull: ${task['due_date'] == null}");
                                      print("Task due_date isEmpty: ${task['due_date'].toString().isEmpty}");
                                      print("Calendar Enabled: $_isCalendarEnabled");
                                      print("Task full: $task");
                                      print("==================");
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: GEÇMİŞ EKRANI (DEĞİŞİKLİK YOK, AYNEN KALACAK) ---
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _meetingsFuture = _apiService.fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geçmiş Toplantılar")),
      body: FutureBuilder<List<dynamic>>(
        future: _meetingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Henüz kayıt bulunmuyor", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          var meetings = snapshot.data!;
          meetings.sort((a, b) => b['id'].compareTo(a['id']));

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                var meeting = meetings[index];
                var status = meeting['status'];
                var dateStr = meeting['created_at'];
                String formattedDate = "Tarih Yok";
                if (dateStr != null) {
                   try {
                     var date = DateTime.parse(dateStr);
                     formattedDate = DateFormat('dd MMM, HH:mm').format(date);
                   } catch (_) {}
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingDetailScreen(
                          meetingId: meeting['id'],
                          title: meeting['title'] ?? "Detay",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: status == 'completed' 
                                ? const Color(0xFFE0F7FA) 
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            status == 'completed' ? Icons.check_circle_outline : Icons.sync,
                            color: status == 'completed' ? const Color(0xFF00ACC1) : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting['title'] ?? "İsimsiz Toplantı",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D2D3A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- DETAY EKRANI (AYNI KALACAK) ---
class MeetingDetailScreen extends StatefulWidget {
  final int meetingId;
  final String title;

  const MeetingDetailScreen({super.key, required this.meetingId, required this.title});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>?> _detailFuture;
  bool _isCalendarEnabled = false; // Takvim entegrasyonu durumu

  @override
  void initState() {
    super.initState();
    _loadCalendarSettings(); // Takvim ayarlarını yükle
    _detailFuture = _apiService.getMeetingDetails(widget.meetingId);
  }

  // Takvim ayarlarını yükle
  Future<void> _loadCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCalendarEnabled = prefs.getBool('calendar_enabled') ?? false;
    });
  }

  // --- TAKVİME EKLEME FONKSİYONU ---
  void _addToCalendar(Map<String, dynamic> task) {
    String title = task['description'] ?? "Görev";
    String dateStr = task['due_date'];
    
    // Eğer tarih yoksa ekleme yapma
    if (dateStr == null || dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu görevin tarihi yok!")));
      return;
    }

    try {
      // Tarihi Parse Et (Backend'den "2026-02-14 17:00:00" gibi geliyor)
      DateTime dueDate = DateTime.parse(dateStr);
      
      final Event event = Event(
        title: "Smart Görevi: $title",
        description: "Bu görev Smart Asistan tarafından oluşturuldu.\nToplantı ID: ${widget.meetingId}",
        location: 'Ofis / Online',
        startDate: dueDate,
        endDate: dueDate.add(const Duration(hours: 1)), // Varsayılan 1 saat sürsün
        iosParams: const IOSParams(reminder: Duration(minutes: 30)),
        androidParams: const AndroidParams(emailInvites: []), // Gerekirse katılımcı eklenebilir
      );

      Add2Calendar.addEvent2Cal(event);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tarih formatı hatası: $e")));
    }
  }

  // --- PDF OLUŞTUR VE PAYLAŞ ---
  Future<void> _generateAndSharePdf(Map<String, dynamic> data) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Raporu hazırlanıyor...')));

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    var tasks = data['action_items'] as List;
    var transcript = data['transcript'] as List;
    var summary = data['executive_summary'] ?? {};
    var sentiment = data['sentiment'] ?? {};
    
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Toplantı Tutanağı", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.Text(DateFormat('dd.MM.yyyy').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.grey)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Genel Durum: ${sentiment['mood'] ?? 'Bilinmiyor'} (${sentiment['score'] ?? 5}/10)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  if (summary['decisions'] != null) ...[
                     pw.Text("Alınan Kararlar:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                     ...(summary['decisions'] as List).map((e) => pw.Bullet(text: e.toString())),
                  ]
                ]
              )
            ),
            pw.SizedBox(height: 20),

            pw.Text("Aksiyon Planı ve Görevler", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Görev', 'Sorumlu', 'Tarih'],
              data: tasks.map((t) => [
                t['description'] ?? "",
                t['assignee_name'] ?? "Belirsiz",
                t['due_date'] ?? "-"
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),
            
            pw.SizedBox(height: 20),
            pw.Text("Konuşma Dökümü (Özet)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.Divider(),
            ...transcript.take(20).map((t) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text("${t['speaker_label']}: ${t['text']}", style: const pw.TextStyle(fontSize: 10))
            )),
          ];
        },
      ),
    );

    // Kaydet ve Paylaş
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/Toplanti_Raporu_${widget.meetingId}.pdf");
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Printing.sharePdf(bytes: bytes, filename: 'Toplanti_Tutanagi.pdf');
  }

  Map<String, dynamic> _getSentimentStyle(String mood) {
    mood = mood.toLowerCase();
    if (mood.contains("neşeli") || mood.contains("verimli") || mood.contains("pozitif")) {
      return {"color": Colors.green, "icon": Icons.sentiment_very_satisfied};
    } else if (mood.contains("gergin") || mood.contains("negatif")) {
      return {"color": Colors.redAccent, "icon": Icons.sentiment_very_dissatisfied};
    } else if (mood.contains("resmi") || mood.contains("ciddi")) {
      return {"color": Colors.blueGrey, "icon": Icons.business_center};
    }
    return {"color": Colors.blue, "icon": Icons.sentiment_neutral};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF6C63FF), size: 48),
                  tooltip: "PDF İndir",
                  onPressed: () => _generateAndSharePdf(snapshot.data!),
                );
              },
            )
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: "Özet"),
              Tab(icon: Icon(Icons.task_alt_rounded), text: "Görevler"),
              Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: "Döküm"),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Detaylar yüklenemedi."));
            }

            var data = snapshot.data!;
            var tasks = data['action_items'] as List;
            var transcript = data['transcript'] as List;
            var summary = data['executive_summary'] ?? {};
            var sentiment = data['sentiment'] ?? {};

            return TabBarView(
              children: [
                // TAB 1: ÖZET
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sentiment.isNotEmpty) ...[
                        _buildSentimentCard(sentiment),
                        const SizedBox(height: 20),
                      ],
                      if (summary.isNotEmpty) ...[
                        _buildSectionTitle("📌 Tartışılan Konular"),
                        _buildSummaryList(summary['discussions']),
                        const SizedBox(height: 20),
                        _buildSectionTitle("🤝 Alınan Kararlar"),
                        _buildSummaryList(summary['decisions']),
                        const SizedBox(height: 20),
                        _buildSectionTitle("🚀 Aksiyon Planı"),
                        _buildSummaryList(summary['action_plan']),
                        const SizedBox(height: 20),
                        if (summary['deadlines'] != null && (summary['deadlines'] as List).isNotEmpty) ...[
                           _buildSectionTitle("⏰ Kritik Tarihler"),
                           _buildSummaryList(summary['deadlines']),
                        ]
                      ] else ...[
                        const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("Özet hazırlanıyor...", style: TextStyle(color: Colors.grey))))
                      ]
                    ],
                  ),
                ),
                // TAB 2: GÖREVLER
                tasks.isEmpty
                    ? Center(child: Text("Görev bulunamadı", style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          var task = tasks[index];
                          String assignee = task['assignee_name'] ?? "Belirsiz";
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
                            child: Row(
                              children: [
                                CircleAvatar(backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1), child: Text(assignee.isNotEmpty ? assignee[0] : "?", style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold))),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task['description'] ?? "", style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), if(task['due_date'] != null) Text("📅 ${task['due_date']} • $assignee", style: TextStyle(color: Colors.red[300], fontSize: 12, fontWeight: FontWeight.bold)) else Text("Sorumlu: $assignee", style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
                                // SAĞ TARAFTAKİ TAKVİM BUTONU
                                if (_isCalendarEnabled && task['due_date'] != null && task['due_date'].toString().isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.event_available_rounded, color: Colors.blueAccent),
                                    tooltip: "Takvime Ekle",
                                    onPressed: () => _addToCalendar(task),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                // TAB 3: DÖKÜM
                transcript.isEmpty
                    ? const Center(child: Text("Ses dökümü yok."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: transcript.length,
                        itemBuilder: (context, index) {
                          var seg = transcript[index];
                          String speaker = seg['speaker_label'] ?? "Misafir";
                          bool isGuest = speaker == "Misafir";
                          return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 18, backgroundColor: isGuest ? Colors.grey[200] : const Color(0xFF6C63FF).withOpacity(0.2), child: Icon(Icons.person, size: 20, color: isGuest ? Colors.grey : const Color(0xFF6C63FF))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(speaker, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 6), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isGuest ? Colors.white : const Color(0xFF6C63FF).withOpacity(0.05), borderRadius: BorderRadius.circular(16)), child: Text(seg['text'] ?? "", style: const TextStyle(fontSize: 15, height: 1.4)))]))]));
                        },
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSentimentCard(Map<String, dynamic> sentiment) {
    String mood = sentiment['mood'] ?? "Nötr";
    int score = sentiment['score'] ?? 5;
    var style = _getSentimentStyle(mood);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: style['color'].withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))], border: Border.all(color: style['color'].withOpacity(0.2))),
      child: Column(children: [Row(children: [Icon(style['icon'], color: style['color'], size: 32), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Toplantı Havası", style: TextStyle(color: Colors.grey[500], fontSize: 12)), Text(mood, style: TextStyle(color: style['color'], fontSize: 20, fontWeight: FontWeight.bold))]), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: style['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("$score/10", style: TextStyle(color: style['color'], fontWeight: FontWeight.bold)))]), const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: score / 10, minHeight: 8, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(style['color'])))]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))));
  }

  Widget _buildSummaryList(dynamic items) {
    if (items == null || (items is List && items.isEmpty)) return const Padding(padding: EdgeInsets.only(left: 4), child: Text("- Bilgi yok", style: TextStyle(color: Colors.grey)));
    return Column(children: (items as List).map((item) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: Color(0xFF6C63FF))), const SizedBox(width: 10), Expanded(child: Text(item.toString(), style: TextStyle(color: Colors.grey[800], height: 1.4)))],))).toList());
  }
}
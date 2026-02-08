import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  
  bool _isRecording = false;
  bool _isUploading = false;
  String? _statusMessage;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/meeting_rec.m4a';
      
      // Kaydı başlat
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      
      setState(() {
        _isRecording = true;
        _statusMessage = "Dinliyorum... 🎙️";
        _result = null; // Eski sonucu temizle
      });
    }
  }

  Future<void> _stopRecordingAndUpload() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isUploading = true;
      _statusMessage = "Sunucuya gönderiliyor... 🚀";
    });

    if (path != null) {
      // 1. Dosyayı Yükle
      int? meetingId = await _apiService.uploadMeeting(path);
      
      if (meetingId != null) {
        setState(() => _statusMessage = "Analiz ediliyor... 🤖");
        
        // 2. Sonucu Bekle (Basit Polling - 5 kere dene)
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 2));
          var details = await _apiService.getMeetingDetails(meetingId);
          
          if (details != null && details['status'] == 'completed') {
            setState(() {
              _result = details;
              _isUploading = false;
              _statusMessage = "Analiz Tamamlandı! ✅";
            });
            return;
          }
        }
      }
    }
    
    setState(() {
      _isUploading = false;
      _statusMessage = "Bir hata oluştu veya zaman aşımı.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meeting AI")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Durum Mesajı
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_statusMessage!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

          // Kayıt Butonu
          Center(
            child: GestureDetector(
              onTap: _isRecording ? _stopRecordingAndUpload : _startRecording,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sonuç Listesi (Action Items)
          if (_result != null && _result!['action_items'] != null)
            Expanded(
              child: ListView.builder(
                itemCount: (_result!['action_items'] as List).length,
                itemBuilder: (context, index) {
                  var task = _result!['action_items'][index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(task['assignee_name'][0] ?? "?")),
                      title: Text(task['description']),
                      subtitle: Text("Sorumlu: ${task['assignee_name']} • Tarih: ${task['due_date']}"),
                      trailing: const Icon(Icons.check_circle_outline),
                    ),
                  );
                },
              ),
            ),
            
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )
        ],
      ),
    );
  }
}

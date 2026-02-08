import 'dart:convert'; // jsonEncode, jsonDecode, utf8 için GEREKLİ
import 'dart:io';
import 'package:http/http.dart' as http; // http istekleri için GEREKLİ

class ApiService {
  // Eğer emülatör kullanıyorsan: 'http://10.0.2.2:8000/api/v1'
  // Gerçek cihaz kullanıyorsan bilgisayarının IP'si: 'http://192.168.1.XX:8000/api/v1'
  // Loglardan gördüğüm kadarıyla senin IP:
  final String baseUrl = 'http://192.168.1.19:8000/api/v1'; 

  // 1. Toplantı Yükleme
  Future<int?> uploadMeeting(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/meetings/upload'));
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      // İsteğe başlık ekleyebiliriz (Gerekirse)
      // request.fields['title'] = 'Mobil Yükleme';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        return data['id'];
      } else {
        print("Yükleme Hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Bağlantı Hatası (Upload): $e");
    }
    return null;
  }

  // 2. Toplantı Listesini Getir
  Future<List<dynamic>> fetchMeetings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/meetings/'));

      if (response.statusCode == 200) {
        // UTF-8 decode işlemi Türkçe karakterler için kritik
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Bağlantı Hatası (Liste): $e");
    }
    return [];
  }

  // 3. Toplantı Detayını Getir
  Future<Map<String, dynamic>?> getMeetingDetails(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/meetings/$id'));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Bağlantı Hatası (Detay): $e");
    }
    return null;
  }

  // 4. Chatbot'a Sor (Tekil Toplantı)
  Future<String?> askMeetingBot(int meetingId, String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/$meetingId/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'];
      }
    } catch (e) {
      print("Chat Hatası: $e");
    }
    return null;
  }

  // 5. Global Asistana Sor (Tüm Veritabanı)
  Future<String?> askGlobalBot(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/global-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'];
      }
    } catch (e) {
      print("Global Chat Hatası: $e");
    }
    return null;
  }
}
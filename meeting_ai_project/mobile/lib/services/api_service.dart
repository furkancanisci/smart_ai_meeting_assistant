import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // GÜNCEL IP ADRESİN (Bilgisayarının IP'si)
  final String baseUrl = 'http://192.168.1.19:8000/api/v1'; 

  // --- TOKEN YÖNETİMİ ---
  
  // Token'ı ve Header'ları her istekte taze okuyan yardımcı fonksiyon
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Token var mı kontrolü (Splash Screen için)
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // --- AUTH İŞLEMLERİ ---

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: {'username': email, 'password': password}, 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        return true;
      }
    } catch (e) {
      print("Login Hatası: $e");
    }
    return false;
  }

  Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register Hatası: $e");
      return false;
    }
  }

  // --- TAKIM (TEAMS) İŞLEMLERİ ---

  Future<List<dynamic>> getMyTeams() async {
    try {
      final headers = await _getHeaders(); // <--- HER SEFERİNDE TAZE TOKEN
      final response = await http.get(
        Uri.parse('$baseUrl/teams/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Teams Hata Kodu: ${response.statusCode}");
      }
    } catch (e) {
      print("Get Teams Hatası: $e");
    }
    return [];
  }

  Future<bool> createTeam(String name) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teams/'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Create Team Hatası: $e");
      return false;
    }
  }

  Future<String?> addMemberToTeam(int teamId, String email) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teams/$teamId/members'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );
      
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200) {
        return data['message'];
      } else {
        return "Hata: ${data['detail'] ?? 'Bilinmeyen hata'}";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }

  // --- TOPLANTI İŞLEMLERİ ---

  Future<int?> uploadMeeting(String filePath) async {
    try {
      final headers = await _getHeaders();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/meetings/upload'));
      request.headers.addAll(headers);
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        return data['id'];
      }
    } catch (e) {
      print("Upload Hatası: $e");
    }
    return null;
  }

  Future<List<dynamic>> fetchMeetings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/meetings/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Fetch Hatası: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getMeetingDetails(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/meetings/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Detail Hatası: $e");
    }
    return null;
  }

  Future<String?> askMeetingBot(int meetingId, String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/$meetingId/chat'),
        headers: headers,
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

  Future<String?> askGlobalBot(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/meetings/global-chat'),
        headers: headers,
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

  // --- BİLDİRİM (NUDGE) ---
  Future<List<dynamic>> getNudges() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/nudges'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Nudge Hatası: $e");
    }
    return [];
  }
}
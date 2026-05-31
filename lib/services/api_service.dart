import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';
import '../models/diary_entry.dart';

class ApiService {
  // Global active session state
  static Map<String, dynamic>? currentUser;

  // Smart dynamic resolution for Web, Android Emulator, and general connections
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    } catch (_) {}
    return 'http://localhost:5000';
  }
  
  // POST /register — user signup
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Sign up execution failed with status: ${response.statusCode}');
    }
  }

  // POST /login — user signin
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      currentUser = data; // Set active session
      return data;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Invalid sign in credentials');
    }
  }

  // Sign out user session cleanly
  static void logout() {
    currentUser = null;
  }
  
  // POST /predict — multipart image upload
  static Future<PredictionResult> predict(Uint8List bytes, String name) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);
    
    final multipartFile = http.MultipartFile.fromBytes(
      'image', 
      bytes, 
      filename: name,
    );
    request.files.add(multipartFile);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PredictionResult.fromJson(data);
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'API Prediction failed with status: ${response.statusCode}');
    }
  }
  
  // POST /save-diary — save scan result  
  static Future<bool> saveDiary(DiaryEntry entry) async {
    final uri = Uri.parse('$baseUrl/save-diary');
    
    // Map current user ID dynamically (default to 1 if anonymous/fallback)
    final Map<String, dynamic> payload = entry.toJson();
    payload['user_id'] = currentUser != null ? currentUser!['id'] : 1;

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['saved'] as bool? ?? false;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to save to diary database');
    }
  }
  
  // GET /diary — fetch all entries
  static Future<List<DiaryEntry>> getDiary() async {
    final int userId = currentUser != null ? currentUser!['id'] as int : 1;
    final uri = Uri.parse('$baseUrl/diary?user_id=$userId');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to load skin diary from backend');
    }
  }
}

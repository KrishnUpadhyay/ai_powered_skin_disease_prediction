import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';
import '../models/diary_entry.dart';

class ApiService {
  // Global active session state
  static Map<String, dynamic>? currentUser;

  // Fitzpatrick Skin Type (Type I to VI)
  static String? fitzpatrickSkinType;

  // Smart dynamic resolution for Web, Emulator, and physical devices
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    // NOTE: 10.0.2.2 is the special IP that allows the Android Emulator to access the host PC's localhost.
    // If you are testing on a physical phone, change this to your PC's local Wi-Fi IP (e.g. 'http://192.168.1.15:5000') 
    // or your public ngrok URL (e.g. 'https://xxxx.ngrok-free.app').
    return 'http://10.0.2.2:5000';
  }
  
  // POST /register — user signup
  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? phoneNumber}) async {
    final uri = Uri.parse('$baseUrl/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phone_number': phoneNumber,
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

  // POST /request-otp — request verification code
  static Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/request-otp');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to request OTP code');
    }
  }

  // POST /verify-otp — verify verification code and login/register
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String code) async {
    final uri = Uri.parse('$baseUrl/verify-otp');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      currentUser = data; // Set active session
      return data;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Invalid OTP verification code');
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

  // POST /chat — conversational triage assistant
  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final uri = Uri.parse('$baseUrl/chat');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Chat response execution failed');
    }
  }

  // GET /uv-index — fetch local UV index details
  static Future<Map<String, dynamic>> getUvIndex({double? latitude, double? longitude, double? hour}) async {
    final Map<String, String> queryParams = {};
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (hour != null) queryParams['hour'] = hour.toString();

    final queryString = Uri(queryParameters: queryParams).query;
    final uri = Uri.parse('$baseUrl/uv-index${queryString.isNotEmpty ? '?$queryString' : ''}');
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to retrieve UV index details');
    }
  }

  // POST /validate-image — pre-scan quality check
  static Future<Map<String, dynamic>> validateImage(Uint8List bytes, String name) async {
    final uri = Uri.parse('$baseUrl/validate-image');
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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Image validation failed with status: ${response.statusCode}');
    }
  }

  // POST /save-symptoms — log daily symptoms
  static Future<bool> saveSymptoms(int itch, int red, int water, String date) async {
    final uri = Uri.parse('$baseUrl/save-symptoms');
    final int userId = currentUser != null ? currentUser!['id'] as int : 1;
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'date': date,
        'itchiness': itch,
        'redness': red,
        'hydration': water,
      }),
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['saved'] as bool? ?? false;
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to save daily symptoms');
    }
  }

  // GET /symptoms — fetch historical symptom logs
  static Future<List<Map<String, dynamic>>> getSymptoms() async {
    final int userId = currentUser != null ? currentUser!['id'] as int : 1;
    final uri = Uri.parse('$baseUrl/symptoms?user_id=$userId');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      final Map<String, dynamic> errData = jsonDecode(response.body);
      throw Exception(errData['error'] ?? 'Failed to load historical symptoms');
    }
  }
}

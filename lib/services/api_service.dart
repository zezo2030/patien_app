import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class ApiService {
  // Base URL from config
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Helper method for POST requests
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
    };
    
    try {
      print('🌐 API Request: POST $url');
      print('📤 Request Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: defaultHeaders,
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // Helper method for GET requests
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
    };
    
    try {
      print('🌐 API Request: GET $url');
      
      final response = await http.get(url, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await post('/auth/login', request.toJson());
      
      // Accept both 200 and 201 as success status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body);
          
          // Validate response structure
          if (jsonData['access_token'] == null || jsonData['user'] == null) {
            print('❌ Invalid response structure: missing access_token or user');
            print('Response: ${response.body}');
            throw Exception('استجابة غير صحيحة من الخادم');
          }
          
          print('✅ Login successful');
          return AuthResponse.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing login response: $e');
          print('Response body: ${response.body}');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 401) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          throw Exception(message);
        } catch (e) {
          throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تسجيل الدخول';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تسجيل الدخول (${response.statusCode})');
        }
      }
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  // Register - returns User object (not AuthResponse)
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await post('/auth/register/patient', request.toJson());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          
          // Validate response structure
          if (jsonData['id'] == null && jsonData['_id'] == null) {
            throw Exception('استجابة غير صحيحة من الخادم');
          }
          
          return jsonData;
        } catch (e) {
          print('❌ Error parsing register response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 409) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل';
          throw Exception(message);
        } catch (e) {
          throw Exception('البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل');
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'البيانات المدخلة غير صحيحة';
          throw Exception(message);
        } catch (e) {
          throw Exception('البيانات المدخلة غير صحيحة');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل التسجيل';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل التسجيل (${response.statusCode})');
        }
      }
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }
}


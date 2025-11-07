import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/department.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../models/doctor.dart' hide DoctorService;
import '../models/service.dart';
import '../models/doctor_service.dart';
import '../models/user.dart';
import '../models/video_session.dart';

class ApiService {
  // Base URL from config
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Health check method to test server connectivity
  Future<bool> checkServerHealth() async {
    try {
      print('🏥 Checking server health at: ${baseUrl}/health');
      final response = await http.get(
        Uri.parse('${baseUrl}/health'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('❌ Health check timeout');
          return http.Response('Timeout', 408);
        },
      );
      
      final isHealthy = response.statusCode == 200;
      print('🏥 Health check result: ${isHealthy ? "✅ Server is reachable" : "❌ Server returned ${response.statusCode}"}');
      return isHealthy;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  // Helper method for POST requests
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
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
          print('⏱️ Request timeout after ${ApiConfig.requestTimeout}s');
          throw TimeoutException(
            'انتهت مهلة الاتصال بعد ${ApiConfig.requestTimeout} ثانية.\n'
            'الخادم: $url\n'
            'تأكد من:\n'
            '1. أن الخادم يعمل على ${baseUrl}\n'
            '2. أن IP العنوان صحيح (${url.host})\n'
            '3. أن الجهاز والكمبيوتر على نفس الشبكة\n'
            '4. أن Firewall لا يمنع الاتصال',
            Duration(seconds: ApiConfig.requestTimeout),
          );
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception(
        'لا يمكن الاتصال بالخادم.\n'
        'الخادم: $url\n'
        'تأكد من:\n'
        '1. أن الخادم يعمل: cd new/clinic-api && npm run start:dev\n'
        '2. أن IP العنوان صحيح: ${url.host}\n'
        '3. أن الجهاز والكمبيوتر على نفس الشبكة WiFi\n'
        '4. أن Firewall يسمح بالاتصال على المنفذ 3000'
      );
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      rethrow;
    } on HttpException catch (e) {
      print('❌ HttpException: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (e.toString().contains('timeout') || e is TimeoutException) {
        throw Exception(
          'انتهت مهلة الاتصال.\n'
          'الخادم: $url\n'
          'تأكد من أن الخادم يعمل وأن IP العنوان صحيح.'
        );
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // Helper method for GET requests
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
    };
    
    try {
      print('🌐 API Request: GET $url');
      
      final response = await http.get(url, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          print('⏱️ GET request timeout after ${ApiConfig.requestTimeout}s');
          throw TimeoutException(
            'انتهت مهلة الاتصال بعد ${ApiConfig.requestTimeout} ثانية.\n'
            'الخادم: $url\n'
            'تأكد من أن الخادم يعمل وأن IP العنوان صحيح.',
            Duration(seconds: ApiConfig.requestTimeout),
          );
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception(
        'لا يمكن الاتصال بالخادم.\n'
        'الخادم: $url\n'
        'تأكد من أن الخادم يعمل على ${baseUrl}'
      );
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      rethrow;
    } on HttpException catch (e) {
      print('❌ HttpException: $e');
      throw Exception('خطأ في الاتصال بالخادم: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (e.toString().contains('timeout') || e is TimeoutException) {
        throw Exception(
          'انتهت مهلة الاتصال.\n'
          'الخادم: $url\n'
          'تأكد من أن الخادم يعمل وأن IP العنوان صحيح.'
        );
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Optional: Check server health before login (can be disabled for faster login)
      // Uncomment the following lines to enable health check:
      // print('🔍 Checking server connectivity...');
      // final isHealthy = await checkServerHealth();
      // if (!isHealthy) {
      //   throw Exception('الخادم غير متاح. تأكد من أن Backend يعمل على ${baseUrl}');
      // }
      
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
  
  // Get current user profile from backend
  Future<User> getCurrentUserProfile(String token) async {
    try {
      final response = await getWithAuth('/auth/me', token);
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          
          // Validate response structure
          if (jsonData['id'] == null && jsonData['_id'] == null) {
            print('❌ Invalid response structure: missing id');
            print('Response: ${response.body}');
            throw Exception('استجابة غير صحيحة من الخادم');
          }
          
          print('✅ User profile retrieved successfully');
          return User.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing user profile response: $e');
          print('Response body: ${response.body}');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 401) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
          throw Exception(message);
        } catch (e) {
          throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
        }
      } else if (response.statusCode == 404) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'المستخدم غير موجود';
          throw Exception(message);
        } catch (e) {
          throw Exception('المستخدم غير موجود');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل بيانات المستخدم';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل بيانات المستخدم (${response.statusCode})');
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
  
  // GET request with Authorization header
  Future<http.Response> getWithAuth(
    String endpoint,
    String token, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    if (token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    Uri url;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      // If endpoint already has query parameters, merge them
      final uri = Uri.parse('$baseUrl$endpoint');
      final existingParams = Map<String, String>.from(uri.queryParameters);
      existingParams.addAll(queryParameters);
      url = uri.replace(queryParameters: existingParams);
    } else {
      url = Uri.parse('$baseUrl$endpoint');
    }
    
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    try {
      print('🌐 API Request: GET $url');
      print('🔐 With Authorization header');
      
      final response = await http.get(url, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }
      
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
        rethrow;
      }
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // POST request with Authorization header
  Future<http.Response> postWithAuth(
    String endpoint,
    Map<String, dynamic> body,
    String token, {
    Map<String, String>? headers,
  }) async {
    if (token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    try {
      print('🌐 API Request: POST $url');
      print('🔐 With Authorization header');
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
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }
      
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
        rethrow;
      }
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // PATCH request with Authorization header
  Future<http.Response> patchWithAuth(
    String endpoint,
    Map<String, dynamic> body,
    String token, {
    Map<String, String>? headers,
  }) async {
    if (token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    try {
      print('🌐 API Request: PATCH $url');
      print('🔐 With Authorization header');
      print('📤 Request Body: ${jsonEncode(body)}');
      
      final response = await http.patch(
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
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }
      
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
        rethrow;
      }
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // DELETE request with Authorization header
  Future<http.Response> deleteWithAuth(
    String endpoint,
    String token, {
    Map<String, String>? headers,
  }) async {
    if (token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    try {
      print('🌐 API Request: DELETE $url');
      print('🔐 With Authorization header');
      
      final response = await http.delete(url, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }
      
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
        rethrow;
      }
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  
  // Get public departments (no authentication required)
  Future<List<Department>> getPublicDepartments() async {
    try {
      final response = await get('/departments/public');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          
          // Handle both array response and wrapped response
          final List<dynamic> departmentsList = jsonData is List 
              ? jsonData 
              : (jsonData['data'] is List ? jsonData['data'] : []);
          
          return departmentsList
              .map((json) => Department.fromJson(json))
              .toList();
        } catch (e) {
          print('❌ Error parsing departments response: $e');
          print('Response body: ${response.body}');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل التخصصات';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل التخصصات (${response.statusCode})');
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
  
  // Get patient appointments with optional filters
  Future<PaginatedAppointments> getPatientAppointments({
    String? status,
    int page = 1,
    int limit = 100,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }
      
      // Build query parameters map
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      // Build URI with query parameters
      final baseUri = Uri.parse(baseUrl);
      final path = '/patient/appointments';
      
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '${baseUri.path}$path',
        queryParameters: queryParams,
      );
      
      // Make the request directly
      final defaultHeaders = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };
      
      try {
        print('🌐 API Request: GET $uri');
        print('🔐 With Authorization header');
        
        final response = await http.get(uri, headers: defaultHeaders).timeout(
          Duration(seconds: ApiConfig.requestTimeout),
          onTimeout: () {
            throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
          },
        );
        
        print('📥 Response Status: ${response.statusCode}');
        
        // Handle 401 Unauthorized
        if (response.statusCode == 401) {
          throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
        }
        
        print('📥 Response Body: ${response.body}');
        
        // Process response
        if (response.statusCode == 200) {
          try {
            final jsonData = jsonDecode(response.body);
            
            // Handle different response formats
            // The backend might return: { appointments: [], total, page, limit, totalPages }
            // Or: { data: { appointments: [], ... }, ... }
            Map<String, dynamic> paginatedData;
            
            if (jsonData['appointments'] != null) {
              paginatedData = jsonData;
            } else if (jsonData['data'] != null && jsonData['data'] is Map) {
              paginatedData = jsonData['data'];
            } else if (jsonData is List) {
              // If response is a direct list, wrap it
              return PaginatedAppointments(
                appointments: jsonData
                    .map((item) => Appointment.fromJson(item))
                    .toList(),
                total: jsonData.length,
                page: page,
                limit: limit,
                totalPages: 1,
              );
            } else {
              paginatedData = jsonData;
            }
            
            return PaginatedAppointments.fromJson(paginatedData);
          } catch (e) {
            print('❌ Error parsing appointments response: $e');
            print('Response body: ${response.body}');
            throw Exception('خطأ في معالجة استجابة الخادم');
          }
        } else {
          try {
            final error = jsonDecode(response.body);
            final message = error['message'] ?? 'فشل تحميل المواعيد';
            throw Exception(message);
          } catch (e) {
            throw Exception('فشل تحميل المواعيد (${response.statusCode})');
          }
        }
      } on SocketException {
        throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
      } on HttpException {
        throw Exception('خطأ في الاتصال بالخادم');
      } catch (e) {
        if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
          rethrow;
        }
        if (e.toString().contains('timeout')) {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        }
        // Re-throw if it's already an Exception with a message
        if (e is Exception) {
          rethrow;
        }
        throw Exception('خطأ غير متوقع: ${e.toString()}');
      }
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Get patient medical records with optional pagination
  Future<PaginatedMedicalRecords> getPatientMedicalRecords({
    int page = 1,
    int limit = 100,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }
      
      // Build query parameters map
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Build URI with query parameters
      final baseUri = Uri.parse(baseUrl);
      final path = '/patient/records';
      
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '${baseUri.path}$path',
        queryParameters: queryParams,
      );
      
      // Make the request directly
      final defaultHeaders = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };
      
      try {
        print('🌐 API Request: GET $uri');
        print('🔐 With Authorization header');
        
        final response = await http.get(uri, headers: defaultHeaders).timeout(
          Duration(seconds: ApiConfig.requestTimeout),
          onTimeout: () {
            throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
          },
        );
        
        print('📥 Response Status: ${response.statusCode}');
        
        // Handle 401 Unauthorized
        if (response.statusCode == 401) {
          throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
        }
        
        print('📥 Response Body: ${response.body}');
        
        // Process response
        if (response.statusCode == 200) {
          try {
            final jsonData = jsonDecode(response.body);
            
            // Handle different response formats
            Map<String, dynamic> paginatedData;
            
            if (jsonData['records'] != null) {
              paginatedData = jsonData;
            } else if (jsonData['data'] != null && jsonData['data'] is Map) {
              paginatedData = jsonData['data'];
            } else if (jsonData is List) {
              // If response is a direct list, wrap it
              return PaginatedMedicalRecords(
                records: jsonData
                    .map((item) => MedicalRecord.fromJson(item))
                    .toList(),
                total: jsonData.length,
                page: page,
                limit: limit,
                totalPages: 1,
              );
            } else {
              paginatedData = jsonData;
            }
            
            return PaginatedMedicalRecords.fromJson(paginatedData);
          } catch (e) {
            print('❌ Error parsing medical records response: $e');
            print('Response body: ${response.body}');
            throw Exception('خطأ في معالجة استجابة الخادم');
          }
        } else {
          try {
            final error = jsonDecode(response.body);
            final message = error['message'] ?? 'فشل تحميل السجلات الطبية';
            throw Exception(message);
          } catch (e) {
            throw Exception('فشل تحميل السجلات الطبية (${response.statusCode})');
          }
        }
      } on SocketException {
        throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${baseUrl}');
      } on HttpException {
        throw Exception('خطأ في الاتصال بالخادم');
      } catch (e) {
        if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
          rethrow;
        }
        if (e.toString().contains('timeout')) {
          throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
        }
        // Re-throw if it's already an Exception with a message
        if (e is Exception) {
          rethrow;
        }
        throw Exception('خطأ غير متوقع: ${e.toString()}');
      }
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  /// إنشاء موعد جديد
  /// 
  /// [doctorId] معرف الطبيب
  /// [serviceId] معرف الخدمة
  /// [startAt] وقت بداية الموعد
  /// [type] نوع الموعد: 'IN_PERSON', 'VIDEO', 'CHAT'
  /// [metadata] بيانات إضافية (اختياري)
  /// [idempotencyKey] مفتاح منع التكرار (اختياري)
  /// [token] رمز المصادقة
  Future<Appointment> createAppointment({
    required String doctorId,
    required String serviceId,
    required DateTime startAt,
    required String type,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      // التحقق من نوع الموعد
      if (!['IN_PERSON', 'VIDEO', 'CHAT'].contains(type)) {
        throw Exception('نوع الموعد غير صحيح');
      }

      final body = {
        'doctorId': doctorId,
        'serviceId': serviceId,
        'startAt': startAt.toUtc().toIso8601String(),
        'type': type,
        if (metadata != null) 'metadata': metadata,
      };

      final headers = <String, String>{};
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        headers['idempotency-key'] = idempotencyKey;
      }

      final response = await postWithAuth(
        '/patient/appointments',
        body,
        token,
        headers: headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Appointment.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing create appointment response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          String message = error['message'] ?? 'فشل إنشاء الموعد';
          
          // تحسين رسالة الخطأ إذا كان السبب هو عدم وجود schedule
          if (message.toLowerCase().contains('schedule not found') || 
              message.toLowerCase().contains('doctor schedule')) {
            message = 'لا يمكن حجز موعد: الطبيب لم يضبط جدوله الزمني بعد. يرجى المحاولة لاحقاً أو التواصل مع الطبيب.';
          }
          
          throw Exception(message);
        } catch (e) {
          // إذا كان الخطأ في parsing JSON، نتحقق من status code
          if (response.statusCode == 404) {
            throw Exception('لا يمكن حجز موعد: الطبيب لم يضبط جدوله الزمني بعد. يرجى المحاولة لاحقاً أو التواصل مع الطبيب.');
          }
          throw Exception('فشل إنشاء الموعد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إنشاء الموعد: ${e.toString()}');
    }
  }

  /// إلغاء موعد
  /// 
  /// [appointmentId] معرف الموعد
  /// [reason] سبب الإلغاء (اختياري)
  /// [token] رمز المصادقة
  Future<Appointment> cancelAppointment({
    required String appointmentId,
    String? reason,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await postWithAuth(
        '/patient/appointments/$appointmentId/cancel',
        body,
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Appointment.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing cancel appointment response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل إلغاء الموعد';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل إلغاء الموعد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إلغاء الموعد: ${e.toString()}');
    }
  }

  /// إعادة جدولة موعد
  /// 
  /// [appointmentId] معرف الموعد
  /// [newStartAt] وقت البداية الجديد
  /// [metadata] بيانات إضافية (اختياري)
  /// [token] رمز المصادقة
  Future<Appointment> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartAt,
    Map<String, dynamic>? metadata,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = {
        'newStartAt': newStartAt.toUtc().toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      final response = await postWithAuth(
        '/patient/appointments/$appointmentId/reschedule',
        body,
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Appointment.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing reschedule appointment response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل إعادة جدولة الموعد';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل إعادة جدولة الموعد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إعادة جدولة الموعد: ${e.toString()}');
    }
  }

  /// جلب أوقات التوفر للطبيب
  /// 
  /// [doctorId] معرف الطبيب
  /// [serviceId] معرف الخدمة
  /// [weekStart] تاريخ بداية الأسبوع (اختياري)
  /// [token] رمز المصادقة
  Future<Map<String, dynamic>> getDoctorAvailability({
    required String doctorId,
    required String serviceId,
    String? weekStart,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final queryParams = <String, String>{
        'serviceId': serviceId,
        if (weekStart != null && weekStart.isNotEmpty) 'weekStart': weekStart,
      };

      final baseUri = Uri.parse(baseUrl);
      final path = '/patient/doctors/$doctorId/availability';
      
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '${baseUri.path}$path',
        queryParameters: queryParams,
      );

      final defaultHeaders = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('❌ Error parsing availability response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب أوقات التوفر');
        } catch (e) {
          throw Exception('فشل جلب أوقات التوفر (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب أوقات التوفر: ${e.toString()}');
    }
  }

  /// جلب قائمة الأطباء
  /// 
  /// [departmentId] فلترة حسب التخصص (اختياري)
  /// [serviceId] فلترة حسب الخدمة (اختياري)
  /// [status] فلترة حسب الحالة (افتراضياً APPROVED)
  /// [token] رمز المصادقة
  Future<List<Doctor>> getDoctors({
    String? departmentId,
    String? serviceId,
    String? status,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final queryParams = <String, String>{};
      if (departmentId != null && departmentId.isNotEmpty) {
        queryParams['departmentId'] = departmentId;
      }
      if (serviceId != null && serviceId.isNotEmpty) {
        queryParams['serviceId'] = serviceId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final baseUri = Uri.parse(baseUrl);
      final path = '/patient/doctors';
      
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '${baseUri.path}$path',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final defaultHeaders = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: defaultHeaders).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          final List<dynamic> doctorsList = jsonData is List 
              ? jsonData 
              : (jsonData['data'] is List ? jsonData['data'] : []);
          
          return doctorsList
              .map((json) => Doctor.fromJson(json))
              .toList();
        } catch (e) {
          print('❌ Error parsing doctors response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب قائمة الأطباء');
        } catch (e) {
          throw Exception('فشل جلب قائمة الأطباء (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب قائمة الأطباء: ${e.toString()}');
    }
  }

  /// جلب تفاصيل طبيب محدد
  /// 
  /// [doctorId] معرف الطبيب
  /// [token] رمز المصادقة
  Future<Doctor> getDoctorById({
    required String doctorId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await getWithAuth(
        '/patient/doctors/$doctorId',
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Doctor.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing doctor details response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب تفاصيل الطبيب');
        } catch (e) {
          throw Exception('فشل جلب تفاصيل الطبيب (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب تفاصيل الطبيب: ${e.toString()}');
    }
  }
}

extension DoctorApi on ApiService {
  // Doctor: Get current doctor profile
  Future<Map<String, dynamic>> getCurrentDoctorProfile({
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await getWithAuth('/doctor/me', token);
      
      if (response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing doctor profile: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل بيانات الطبيب';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل بيانات الطبيب (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Doctor: Get appointments
  Future<PaginatedAppointments> getDoctorAppointments({
    String? status,
    int page = 1,
    int limit = 100,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await getWithAuth(
        '/doctor/appointments',
        token,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          Map<String, dynamic> paginatedData;
          if (jsonData['appointments'] != null) {
            paginatedData = jsonData;
          } else if (jsonData['data'] != null && jsonData['data'] is Map) {
            paginatedData = jsonData['data'];
          } else if (jsonData is List) {
            return PaginatedAppointments(
              appointments: jsonData
                  .map((item) => Appointment.fromJson(item))
                  .toList(),
              total: jsonData.length,
              page: page,
              limit: limit,
              totalPages: 1,
            );
          } else {
            paginatedData = jsonData;
          }
          return PaginatedAppointments.fromJson(paginatedData);
        } catch (e) {
          print('❌ Error parsing doctor appointments: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل المواعيد';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل المواعيد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Doctor: Confirm appointment
  Future<Appointment> confirmAppointment({
    required String appointmentId,
    String? notes,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await postWithAuth(
        '/doctor/appointments/$appointmentId/confirm',
        body,
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Appointment.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing confirm response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تأكيد الموعد';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تأكيد الموعد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في تأكيد الموعد: ${e.toString()}');
    }
  }

  // Doctor: Reject appointment
  Future<Appointment> rejectAppointment({
    required String appointmentId,
    required String reason,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{'reason': reason};

      final response = await postWithAuth(
        '/doctor/appointments/$appointmentId/reject',
        body,
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return Appointment.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing reject response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل رفض الموعد';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل رفض الموعد (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في رفض الموعد: ${e.toString()}');
    }
  }

  // Doctor: Get schedule
  Future<Map<String, dynamic>> getDoctorSchedule({
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await getWithAuth('/doctor/schedule', token);
      if (response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing schedule response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      }

      // Treat first-time (no schedule) as empty schedule
      if (response.statusCode == 404) {
        return {
          'weeklyTemplate': [],
          'exceptions': [],
          'holidays': [],
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب الجدول');
        } catch (e) {
          throw Exception('فشل جلب الجدول (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب الجدول: ${e.toString()}');
    }
  }

  // Doctor: Create or update schedule (POST)
  Future<Map<String, dynamic>> createOrUpdateSchedule({
    required Map<String, dynamic> scheduleData,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await postWithAuth(
        '/doctor/schedule',
        scheduleData,
        token,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing schedule upsert response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل حفظ الجدول');
        } catch (e) {
          throw Exception('فشل حفظ الجدول (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في حفظ الجدول: ${e.toString()}');
    }
  }

  // Doctor: Update schedule (PATCH)
  Future<Map<String, dynamic>> updateSchedule({
    required Map<String, dynamic> updateData,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await patchWithAuth(
        '/doctor/schedule',
        updateData,
        token,
      );
      if (response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing schedule update response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل تحديث الجدول');
        } catch (e) {
          throw Exception('فشل تحديث الجدول (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في تحديث الجدول: ${e.toString()}');
    }
  }

  // Doctor: Add schedule exception
  Future<Map<String, dynamic>> addScheduleException({
    required String date,
    required bool isAvailable,
    List<Map<String, String>>? slots,
    String? reason,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{
        'date': date,
        'isAvailable': isAvailable,
        if (slots != null) 'slots': slots,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response = await postWithAuth(
        '/doctor/schedule/exceptions',
        body,
        token,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing add exception response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل إضافة الاستثناء');
        } catch (e) {
          throw Exception('فشل إضافة الاستثناء (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إضافة الاستثناء: ${e.toString()}');
    }
  }

  // Doctor: Remove schedule exception
  Future<void> removeScheduleException({
    required String date,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await deleteWithAuth(
        '/doctor/schedule/exceptions/$date',
        token,
      );
      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل حذف الاستثناء');
        } catch (e) {
          throw Exception('فشل حذف الاستثناء (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في حذف الاستثناء: ${e.toString()}');
    }
  }

  // Doctor: Add holiday
  Future<Map<String, dynamic>> addHoliday({
    required String startDate,
    required String endDate,
    String? reason,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{
        'startDate': startDate,
        'endDate': endDate,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response = await postWithAuth(
        '/doctor/schedule/holidays',
        body,
        token,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return Map<String, dynamic>.from(jsonDecode(response.body));
        } catch (e) {
          print('❌ Error parsing add holiday response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل إضافة العطلة');
        } catch (e) {
          throw Exception('فشل إضافة العطلة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إضافة العطلة: ${e.toString()}');
    }
  }

  // Doctor: Remove holiday
  Future<void> removeHoliday({
    required String holidayId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await deleteWithAuth(
        '/doctor/schedule/holidays/$holidayId',
        token,
      );
      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل حذف العطلة');
        } catch (e) {
          throw Exception('فشل حذف العطلة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في حذف العطلة: ${e.toString()}');
    }
  }

  // PUT request with Authorization header
  Future<http.Response> putWithAuth(
    String endpoint,
    Map<String, dynamic> body,
    String token, {
    Map<String, String>? headers,
  }) async {
    if (token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    try {
      print('🌐 API Request: PUT $url');
      print('🔐 With Authorization header');
      print('📤 Request Body: ${jsonEncode(body)}');
      
      final response = await http.put(
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
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      }
      
      print('📥 Response Body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('لا يمكن الاتصال بالخادم. تأكد من أن الباك اند يعمل على ${ApiService.baseUrl}');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e.toString().contains('غير مصرح') || e.toString().contains('انتهت صلاحية')) {
        rethrow;
      }
      if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت');
      }
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  // Doctor: Get services
  Future<List<DoctorService>> getDoctorServices({
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await getWithAuth('/doctor/me/services', token);
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          List<dynamic> servicesList;
          
          if (jsonData is List) {
            servicesList = jsonData;
          } else if (jsonData['services'] != null && jsonData['services'] is List) {
            servicesList = jsonData['services'];
          } else if (jsonData['data'] != null && jsonData['data'] is List) {
            servicesList = jsonData['data'];
          } else {
            servicesList = [];
          }
          
          return servicesList
              .map((item) => DoctorService.fromJson(item))
              .toList();
        } catch (e) {
          print('❌ Error parsing doctor services: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل الخدمات';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل الخدمات (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Doctor: Get department services
  Future<List<Service>> getDepartmentServices({
    required String departmentId,
    String? token,
  }) async {
    try {
      // استخدام endpoint عام للقسم للحصول على الخدمات (لا يحتاج authentication)
      final response = await get(
        '/departments/public/$departmentId',
      );
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          List<dynamic> servicesList = [];
          
          // endpoint يعيد department مع services في property منفصل
          if (jsonData['services'] != null && jsonData['services'] is List) {
            servicesList = jsonData['services'];
          } else if (jsonData is List) {
            servicesList = jsonData;
          } else if (jsonData['data'] != null && jsonData['data'] is List) {
            servicesList = jsonData['data'];
          }
          
          return servicesList
              .map((item) => Service.fromJson(item))
              .toList();
        } catch (e) {
          print('❌ Error parsing department services: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحميل الخدمات';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحميل الخدمات (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Doctor: Update doctor service (add or update)
  Future<DoctorService> updateDoctorService({
    required String serviceId,
    double? customPrice,
    int? customDuration,
    bool? isActive,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final body = <String, dynamic>{};
      if (customPrice != null) body['customPrice'] = customPrice;
      if (customDuration != null) body['customDuration'] = customDuration;
      if (isActive != null) body['isActive'] = isActive;

      final response = await putWithAuth(
        '/doctor/me/services/$serviceId',
        body,
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body);
          return DoctorService.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing update service response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل تحديث الخدمة';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل تحديث الخدمة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في تحديث الخدمة: ${e.toString()}');
    }
  }

  // Doctor: Remove doctor service
  Future<void> removeDoctorService({
    required String serviceId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await deleteWithAuth(
        '/doctor/me/services/$serviceId',
        token,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'فشل حذف الخدمة';
          throw Exception(message);
        } catch (e) {
          throw Exception('فشل حذف الخدمة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في حذف الخدمة: ${e.toString()}');
    }
  }
}

// Video Session API Methods
extension VideoSessionApi on ApiService {
  /// Get Agora App ID (public endpoint)
  Future<AgoraAppIdResponse> getAgoraAppId() async {
    try {
      final response = await get('/sessions/video/app-id');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return AgoraAppIdResponse.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing Agora App ID response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 503) {
        throw Exception('خدمة Agora غير مفعلة. يرجى التواصل مع الدعم');
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب App ID');
        } catch (e) {
          throw Exception('فشل جلب App ID (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب App ID: ${e.toString()}');
    }
  }

  /// Get video token for appointment
  Future<VideoTokenResponse> getVideoToken({
    required String appointmentId,
    required String role,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final request = VideoTokenRequest(
        appointmentId: appointmentId,
        role: role,
      );

      final response = await postWithAuth(
        '/sessions/video/token',
        request.toJson(),
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body);
          return VideoTokenResponse.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing video token response: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 400) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'لا يمكن بدء مكالمة الفيديو الآن';
          throw Exception(message);
        } catch (e) {
          throw Exception('لا يمكن بدء مكالمة الفيديو الآن');
        }
      } else if (response.statusCode == 403) {
        throw Exception('غير مصرح لك بالوصول إلى هذه المكالمة');
      } else if (response.statusCode == 500) {
        try {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'خطأ في الخادم. يرجى المحاولة مرة أخرى';
          throw Exception(message);
        } catch (e) {
          throw Exception('خطأ في الخادم. تأكد من أن إعدادات Agora صحيحة في الباكند');
        }
      } else if (response.statusCode == 404) {
        throw Exception('الموعد غير موجود');
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل الحصول على token');
        } catch (e) {
          throw Exception('فشل الحصول على token (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في الحصول على token: ${e.toString()}');
    }
  }

  /// Get video session information
  Future<VideoSessionInfo> getVideoSessionInfo({
    required String appointmentId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await getWithAuth(
        '/sessions/video/$appointmentId',
        token,
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return VideoSessionInfo.fromJson(jsonData);
        } catch (e) {
          print('❌ Error parsing video session info: $e');
          throw Exception('خطأ في معالجة استجابة الخادم');
        }
      } else if (response.statusCode == 403) {
        throw Exception('غير مصرح لك بالوصول إلى هذه الجلسة');
      } else if (response.statusCode == 404) {
        throw Exception('الجلسة غير موجودة');
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل جلب معلومات الجلسة');
        } catch (e) {
          throw Exception('فشل جلب معلومات الجلسة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في جلب معلومات الجلسة: ${e.toString()}');
    }
  }

  /// Join video session
  Future<void> joinVideoSession({
    required String appointmentId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await postWithAuth(
        '/sessions/video/$appointmentId/join',
        {},
        token,
      );

      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل الانضمام للجلسة');
        } catch (e) {
          throw Exception('فشل الانضمام للجلسة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في الانضمام للجلسة: ${e.toString()}');
    }
  }

  /// Leave video session
  Future<void> leaveVideoSession({
    required String appointmentId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await postWithAuth(
        '/sessions/video/$appointmentId/leave',
        {},
        token,
      );

      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل مغادرة الجلسة');
        } catch (e) {
          throw Exception('فشل مغادرة الجلسة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في مغادرة الجلسة: ${e.toString()}');
    }
  }

  /// End video session (doctor only)
  Future<void> endVideoSession({
    required String appointmentId,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        throw Exception('غير مصرح - يرجى تسجيل الدخول');
      }

      final response = await postWithAuth(
        '/sessions/video/$appointmentId/end',
        {},
        token,
      );

      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'فشل إنهاء الجلسة');
        } catch (e) {
          throw Exception('فشل إنهاء الجلسة (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('خطأ في إنهاء الجلسة: ${e.toString()}');
    }
  }
}

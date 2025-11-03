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
    
    final url = Uri.parse('$baseUrl$endpoint');
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
    
    final url = Uri.parse('$baseUrl$endpoint');
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
    
    final url = Uri.parse('$baseUrl$endpoint');
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
}


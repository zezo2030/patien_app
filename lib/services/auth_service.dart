import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('🔐 Attempting login for: ${request.email}');
      final response = await _apiService.login(request);
      print('✅ Login API call successful');
      
      await _saveAuthData(response);
      print('💾 Auth data saved to local storage');
      
      return response;
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow;
    }
  }
  
  // Register - returns User (register doesn't return access_token)
  Future<User> register(RegisterRequest request) async {
    try {
      final response = await _apiService.register(request);
      // Register endpoint returns User object, not AuthResponse
      final user = User.fromJson(response);
      // Don't save auth data since register doesn't provide token
      // User needs to login after registration
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Save auth data to local storage
  Future<void> _saveAuthData(AuthResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response.accessToken);
      await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
      print('💾 Token saved: ${response.accessToken.substring(0, 20)}...');
      print('💾 User saved: ${response.user.name} (${response.user.email})');
    } catch (e) {
      print('❌ Error saving auth data: $e');
      throw Exception('فشل حفظ بيانات تسجيل الدخول');
    }
  }
  
  // Get current user - tries API first, falls back to local storage
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    final token = await getToken();
    
    // If no token, return null
    if (token == null || token.isEmpty) {
      return null;
    }
    
    // If forceRefresh is true, only fetch from API
    if (forceRefresh) {
      try {
        final user = await _apiService.getCurrentUserProfile(token);
        await _saveUserData(user);
        return user;
      } catch (e) {
        print('❌ Error fetching user from API: $e');
        // If API fails, try local storage as fallback
        return _getUserFromLocalStorage();
      }
    }
    
    // Try API first, fallback to local storage
    try {
      final user = await _apiService.getCurrentUserProfile(token);
      await _saveUserData(user);
      return user;
    } catch (e) {
      print('⚠️ API call failed, using local storage: $e');
      // Check if it's a 401 error (unauthorized)
      if (e.toString().contains('401') || 
          e.toString().contains('انتهت صلاحية') ||
          e.toString().contains('غير مصرح')) {
        // Clear local data on 401
        await logout();
        return null;
      }
      // For other errors (network, etc.), use local storage as fallback
      return _getUserFromLocalStorage();
    }
  }
  
  // Refresh current user from server only
  Future<User> refreshCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }
    
    final user = await _apiService.getCurrentUserProfile(token);
    await _saveUserData(user);
    return user;
  }
  
  // Get user from local storage (helper method)
  Future<User?> _getUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return User.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  // Save user data to local storage (helper method)
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('💾 User data saved to local storage: ${user.name} (${user.email})');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }
  
  // Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}


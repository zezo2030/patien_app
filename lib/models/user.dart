import '../config/api_config.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? avatar;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.avatar,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    // معالجة avatar - تحويل المسار النسبي إلى URL كامل
    String? avatar = json['avatar'];
    if (avatar != null && avatar.isNotEmpty) {
      avatar = ApiConfig.buildFullUrl(avatar);
    }
    
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'PATIENT',
      avatar: avatar,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar': avatar,
    };
  }
}


class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? avatar;
  
  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.avatar,
  });
  
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
    
    if (avatar != null && avatar!.isNotEmpty) {
      json['avatar'] = avatar!;
    }
    
    return json;
  }
}


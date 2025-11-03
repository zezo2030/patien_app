import '../config/api_config.dart';

class Department {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String? logoUrl;
  final String? icon;

  Department({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.logoUrl,
    this.icon,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    // تحويل logoUrl النسبي إلى URL كامل
    String? logoUrl = json['logoUrl'];
    if (logoUrl != null && logoUrl.isNotEmpty) {
      logoUrl = ApiConfig.buildFullUrl(logoUrl);
    }
    
    // تحويل icon أيضاً إذا كان مسار نسبي
    String? icon = json['icon'];
    if (icon != null && icon.isNotEmpty && (icon.startsWith('/static') || icon.startsWith('/'))) {
      icon = ApiConfig.buildFullUrl(icon);
    }
    
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? false,
      logoUrl: logoUrl,
      icon: icon,
    );
  }
}


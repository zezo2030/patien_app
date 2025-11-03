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
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? false,
      logoUrl: json['logoUrl'],
      icon: json['icon'],
    );
  }
}


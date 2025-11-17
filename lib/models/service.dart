class Service {
  final String id;
  final String name;
  final String? description;
  final String departmentId;
  final double? basePrice;
  final int? baseDuration;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.departmentId,
    this.basePrice,
    this.baseDuration,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // معالجة departmentId - قد يكون string أو object
    String departmentId;
    if (json['departmentId'] != null) {
      if (json['departmentId'] is Map) {
        departmentId = json['departmentId']['_id']?.toString() ?? 
                      json['departmentId']['id']?.toString() ?? '';
      } else {
        departmentId = json['departmentId']?.toString() ?? '';
      }
    } else {
      departmentId = '';
    }

    return Service(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      departmentId: departmentId,
      basePrice: json['basePrice']?.toDouble() ?? json['defaultPrice']?.toDouble(),
      baseDuration: json['baseDuration']?.toInt() ?? json['defaultDurationMin']?.toInt(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'departmentId': departmentId,
      'basePrice': basePrice,
      'baseDuration': baseDuration,
      'isActive': isActive,
    };
  }
}











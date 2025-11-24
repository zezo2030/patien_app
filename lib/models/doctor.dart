import '../config/api_config.dart';

class Doctor {
  final String id;
  final String name;
  final String? licenseNumber;
  final int? yearsOfExperience;
  final String? departmentId;
  final String? departmentName;
  final String? bio;
  final String status; // APPROVED, PENDING, SUSPENDED
  final List<DoctorService>? services;
  final String? avatar;

  Doctor({
    required this.id,
    required this.name,
    this.licenseNumber,
    this.yearsOfExperience,
    this.departmentId,
    this.departmentName,
    this.bio,
    required this.status,
    this.services,
    this.avatar,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // معالجة departmentId - قد يكون string أو object
    String? departmentId;
    String? departmentName;
    
    if (json['departmentId'] != null) {
      if (json['departmentId'] is Map) {
        departmentId = json['departmentId']['_id']?.toString() ?? 
                       json['departmentId']['id']?.toString();
        departmentName = json['departmentId']['name'];
      } else {
        departmentId = json['departmentId']?.toString();
      }
    }
    
    departmentName ??= json['departmentName'];

    // معالجة avatar - تحويل المسار النسبي إلى URL كامل
    String? avatar = json['avatar'];
    if (avatar != null && avatar.isNotEmpty) {
      avatar = ApiConfig.buildFullUrl(avatar);
    }

    // معالجة services
    List<DoctorService>? services;
    if (json['services'] != null && json['services'] is List) {
      services = (json['services'] as List)
          .map((s) => DoctorService.fromJson(s))
          .toList();
    }

    return Doctor(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      name: json['name'] ?? '',
      licenseNumber: json['licenseNumber'],
      yearsOfExperience: json['yearsOfExperience']?.toInt(),
      departmentId: departmentId,
      departmentName: departmentName,
      bio: json['bio'],
      status: json['status'] ?? 'APPROVED',
      services: services,
      avatar: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'bio': bio,
      'status': status,
      'services': services?.map((s) => s.toJson()).toList(),
      'avatar': avatar,
    };
  }
}

class DoctorService {
  final String serviceId;
  final String serviceName;
  final double? customPrice;
  final int? customDuration;
  final bool isActive;

  DoctorService({
    required this.serviceId,
    required this.serviceName,
    this.customPrice,
    this.customDuration,
    required this.isActive,
  });

  factory DoctorService.fromJson(Map<String, dynamic> json) {
    // معالجة serviceId - قد يكون string أو object
    String serviceId;
    String serviceName;
    
    if (json['serviceId'] != null) {
      if (json['serviceId'] is Map) {
        serviceId = json['serviceId']['_id']?.toString() ?? 
                    json['serviceId']['id']?.toString() ?? '';
        serviceName = json['serviceId']['name'] ?? '';
      } else {
        serviceId = json['serviceId']?.toString() ?? '';
        serviceName = json['serviceName'] ?? '';
      }
    } else {
      serviceId = '';
      serviceName = json['serviceName'] ?? '';
    }

    return DoctorService(
      serviceId: serviceId,
      serviceName: serviceName,
      customPrice: json['customPrice']?.toDouble(),
      customDuration: json['customDuration']?.toInt(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'customPrice': customPrice,
      'customDuration': customDuration,
      'isActive': isActive,
    };
  }
}













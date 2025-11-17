import 'service.dart';

class DoctorService {
  final String id;
  final String doctorId;
  final String serviceId;
  final double? customPrice;
  final int? customDuration;
  final bool isActive;
  final Service? service; // Service object بعد populate
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DoctorService({
    required this.id,
    required this.doctorId,
    required this.serviceId,
    this.customPrice,
    this.customDuration,
    required this.isActive,
    this.service,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorService.fromJson(Map<String, dynamic> json) {
    // معالجة doctorId - قد يكون string أو object
    String doctorId;
    if (json['doctorId'] != null) {
      if (json['doctorId'] is Map) {
        doctorId = json['doctorId']['_id']?.toString() ?? 
                  json['doctorId']['id']?.toString() ?? '';
      } else {
        doctorId = json['doctorId']?.toString() ?? '';
      }
    } else {
      doctorId = '';
    }

    // معالجة serviceId - قد يكون string أو object
    String serviceId;
    if (json['serviceId'] != null) {
      if (json['serviceId'] is Map) {
        serviceId = json['serviceId']['_id']?.toString() ?? 
                   json['serviceId']['id']?.toString() ?? '';
      } else {
        serviceId = json['serviceId']?.toString() ?? '';
      }
    } else {
      serviceId = '';
    }

    // معالجة service object (populated)
    Service? service;
    if (json['serviceId'] is Map && json['serviceId'] != null) {
      service = Service.fromJson(json['serviceId']);
    } else if (json['service'] != null && json['service'] is Map) {
      service = Service.fromJson(json['service']);
    }

    // معالجة التواريخ
    DateTime? createdAt;
    DateTime? updatedAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt']);
    }
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.parse(json['updatedAt']);
    }

    return DoctorService(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      doctorId: doctorId,
      serviceId: serviceId,
      customPrice: json['customPrice']?.toDouble(),
      customDuration: json['customDuration']?.toInt(),
      isActive: json['isActive'] ?? true,
      service: service,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'serviceId': serviceId,
      'customPrice': customPrice,
      'customDuration': customDuration,
      'isActive': isActive,
      'service': service?.toJson(),
    };
  }
}











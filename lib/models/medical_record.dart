import 'appointment.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final String? prescription;
  final VitalSigns? vitalSigns;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DoctorInfo? doctor;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    this.prescription,
    this.vitalSigns,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.doctor,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['_id'] ?? json['id'] ?? '',
      patientId: json['patientId'].toString(),
      doctorId: json['doctorId'].toString(),
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'],
      vitalSigns: json['vitalSigns'] != null 
          ? VitalSigns.fromJson(json['vitalSigns'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      doctor: json['doctorId'] is Map 
          ? DoctorInfo.fromJson(json['doctorId'])
          : null,
    );
  }
}

class VitalSigns {
  final double? bloodPressure;
  final double? heartRate;
  final double? temperature;
  final double? weight;
  final double? height;

  VitalSigns({
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
  });

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      bloodPressure: json['bloodPressure']?.toDouble(),
      heartRate: json['heartRate']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
    );
  }
}

class PaginatedMedicalRecords {
  final List<MedicalRecord> records;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedMedicalRecords({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedMedicalRecords.fromJson(Map<String, dynamic> json) {
    return PaginatedMedicalRecords(
      records: (json['records'] as List?)
          ?.map((item) => MedicalRecord.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}


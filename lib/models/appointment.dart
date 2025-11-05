// Enum للحالات
enum AppointmentStatus {
  pendingConfirm('PENDING_CONFIRM', 'في انتظار التأكيد'),
  confirmed('CONFIRMED', 'مؤكد'),
  cancelled('CANCELLED', 'ملغى'),
  completed('COMPLETED', 'مكتمل'),
  noShow('NO_SHOW', 'لم يحضر'),
  rejected('REJECTED', 'مرفوض');

  final String value;
  final String arabicLabel;
  const AppointmentStatus(this.value, this.arabicLabel);

  static AppointmentStatus? fromString(String? status) {
    if (status == null) return null;
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => AppointmentStatus.pendingConfirm,
    );
  }
}

// Enum للأنواع
enum AppointmentType {
  inPerson('IN_PERSON', 'حضور شخصي'),
  video('VIDEO', 'مكالمة فيديو'),
  chat('CHAT', 'محادثة نصية');

  final String value;
  final String arabicLabel;
  const AppointmentType(this.value, this.arabicLabel);

  static AppointmentType? fromString(String? type) {
    if (type == null) return null;
    return AppointmentType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => AppointmentType.inPerson,
    );
  }
}

class Appointment {
  final String id;
  final String doctorId;
  final String serviceId;
  final String patientId;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String type;
  final double? price;
  final String? paymentStatus;
  final String? location;
  final String? notes;
  final DoctorInfo? doctor;
  final ServiceInfo? service;
  
  // الحقول الجديدة
  final int? duration;
  final DateTime? holdExpiresAt;
  final String? idempotencyKey;
  final Map<String, dynamic>? metadata;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final bool? requiresPayment;
  final String? paymentId;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.serviceId,
    required this.patientId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.type,
    this.price,
    this.paymentStatus,
    this.location,
    this.notes,
    this.doctor,
    this.service,
    this.duration,
    this.holdExpiresAt,
    this.idempotencyKey,
    this.metadata,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    this.requiresPayment,
    this.paymentId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Extract doctor info - check for populated 'doctor' field first, then fall back to 'doctorId' as Map
    DoctorInfo? doctor;
    if (json['doctor'] != null && json['doctor'] is Map) {
      doctor = DoctorInfo.fromJson(json['doctor']);
    } else if (json['doctorId'] is Map && (json['doctorId']['name'] != null || json['doctorId']['_id'] != null)) {
      doctor = DoctorInfo.fromJson(json['doctorId']);
    }
    
    // Extract service info - check for populated 'service' field first, then fall back to 'serviceId' as Map
    ServiceInfo? service;
    if (json['service'] != null && json['service'] is Map) {
      service = ServiceInfo.fromJson(json['service']);
    } else if (json['serviceId'] is Map && (json['serviceId']['name'] != null || json['serviceId']['_id'] != null)) {
      service = ServiceInfo.fromJson(json['serviceId']);
    }
    
    // Extract IDs - handle both string and Map formats
    String doctorIdStr = '';
    if (json['doctorId'] is Map) {
      doctorIdStr = json['doctorId']['_id']?.toString() ?? 
                    json['doctorId']['id']?.toString() ?? '';
    } else {
      doctorIdStr = json['doctorId']?.toString() ?? '';
    }
    
    String serviceIdStr = '';
    if (json['serviceId'] is Map) {
      serviceIdStr = json['serviceId']['_id']?.toString() ?? 
                     json['serviceId']['id']?.toString() ?? '';
    } else {
      serviceIdStr = json['serviceId']?.toString() ?? '';
    }
    
    return Appointment(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: doctorIdStr,
      serviceId: serviceIdStr,
      patientId: json['patientId']?.toString() ?? '',
      startAt: DateTime.parse(json['startAt']),
      endAt: DateTime.parse(json['endAt']),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      price: json['price']?.toDouble(),
      paymentStatus: json['paymentStatus'],
      location: json['location'],
      notes: json['notes'],
      doctor: doctor,
      service: service,
      duration: json['duration']?.toInt(),
      holdExpiresAt: json['holdExpiresAt'] != null 
          ? DateTime.parse(json['holdExpiresAt']) 
          : null,
      idempotencyKey: json['idempotencyKey'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      cancellationReason: json['cancellationReason'],
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      cancelledBy: json['cancelledBy']?.toString(),
      requiresPayment: json['requiresPayment'] ?? false,
      paymentId: json['paymentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'serviceId': serviceId,
      'startAt': startAt.toUtc().toIso8601String(),
      'type': type,
      if (metadata != null) 'metadata': metadata,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }
}

class DoctorInfo {
  final String id;
  final String name;
  final String? licenseNumber;

  DoctorInfo({
    required this.id,
    required this.name,
    this.licenseNumber,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      name: json['name'] ?? '',
      licenseNumber: json['licenseNumber'],
    );
  }
}

class ServiceInfo {
  final String id;
  final String name;

  ServiceInfo({
    required this.id,
    required this.name,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PaginatedAppointments {
  final List<Appointment> appointments;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedAppointments({
    required this.appointments,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedAppointments.fromJson(Map<String, dynamic> json) {
    return PaginatedAppointments(
      appointments: (json['appointments'] as List?)
          ?.map((item) => Appointment.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}


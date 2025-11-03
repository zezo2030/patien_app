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
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: json['doctorId']['_id']?.toString() ?? 
                json['doctorId'].toString(),
      serviceId: json['serviceId']['_id']?.toString() ?? 
                 json['serviceId'].toString(),
      patientId: json['patientId'].toString(),
      startAt: DateTime.parse(json['startAt']),
      endAt: DateTime.parse(json['endAt']),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      price: json['price']?.toDouble(),
      paymentStatus: json['paymentStatus'],
      location: json['location'],
      notes: json['notes'],
      doctor: json['doctorId'] is Map 
          ? DoctorInfo.fromJson(json['doctorId'])
          : null,
      service: json['serviceId'] is Map
          ? ServiceInfo.fromJson(json['serviceId'])
          : null,
    );
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


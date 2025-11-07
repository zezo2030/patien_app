# خطة تنفيذ نظام المواعيد في تطبيق Flutter

## 📋 نظرة عامة

هذا المستند يوضح الخطة الشاملة لإضافة وظائف المواعيد الكاملة في تطبيق Flutter للمرضى، بناءً على نظام الباك اند الموجود.

---

## 🎯 الأهداف

### الميزات المطلوبة:
1. ✅ **عرض المواعيد** (موجود حالياً)
2. ❌ **إنشاء موعد جديد**
3. ❌ **إلغاء موعد**
4. ❌ **إعادة جدولة موعد**
5. ❌ **عرض تفاصيل الموعد**
6. ❌ **حجز موعد من صفحة التخصصات**
7. ❌ **اختيار التواريخ والأوقات المتاحة**

---

## 📁 البنية الحالية

### الملفات الموجودة:
```
patien_app/lib/
├── models/
│   └── appointment.dart          ✅ موجود (يحتاج تحسين)
├── services/
│   └── api_service.dart          ✅ موجود (يحتاج إضافة دوال جديدة)
└── screens/
    └── appointments/
        └── appointments_screen.dart  ✅ موجود (عرض فقط)
```

---

## 🗂️ المراحل التنفيذية

### المرحلة 1: تحديث النماذج (Models) ⏱️ 30 دقيقة

#### 1.1 تحديث `lib/models/appointment.dart`

**الإضافات المطلوبة:**

```dart
// إضافة الحقول المفقودة
class Appointment {
  // ... الحقول الموجودة ...
  
  // الحقول الجديدة المطلوبة:
  final int? duration;              // مدة الموعد بالدقائق
  final DateTime? holdExpiresAt;    // وقت انتهاء الحجز المؤقت
  final String? idempotencyKey;     // مفتاح منع التكرار
  final Map<String, dynamic>? metadata;  // بيانات إضافية
  final String? cancellationReason;      // سبب الإلغاء
  final DateTime? cancelledAt;           // وقت الإلغاء
  final String? cancelledBy;             // من ألغى الموعد
  final bool? requiresPayment;           // هل يتطلب دفع
  final String? paymentId;               // معرف الدفع
}

// إضافة Enum للحالات (اختياري لكن مفيد)
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
}

enum AppointmentType {
  inPerson('IN_PERSON', 'حضور شخصي'),
  video('VIDEO', 'مكالمة فيديو'),
  chat('CHAT', 'محادثة نصية');

  final String value;
  final String arabicLabel;
  const AppointmentType(this.value, this.arabicLabel);
}

// تحديث fromJson ليتعامل مع الحقول الجديدة
factory Appointment.fromJson(Map<String, dynamic> json) {
  return Appointment(
    // ... الحقول الحالية ...
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

// إضافة toJson للإرسال
Map<String, dynamic> toJson() {
  return {
    'doctorId': doctorId,
    'serviceId': serviceId,
    'startAt': startAt.toUtc().toIso8601String(),
    'type': type,
    if (metadata != null) 'metadata': metadata,
  };
}
```

**المهام:**
- [ ] إضافة الحقول المفقودة
- [ ] تحديث `fromJson` لدعم الحقول الجديدة
- [ ] إضافة `toJson` للإرسال
- [ ] إضافة Enums للحالات والأنواع (اختياري)
- [ ] اختبار parsing البيانات

---

### المرحلة 2: تحديث ApiService ⏱️ 2 ساعة

#### 2.1 إضافة دالة إنشاء موعد جديد

**الملف:** `lib/services/api_service.dart`

```dart
/// إنشاء موعد جديد
/// 
/// [doctorId] معرف الطبيب
/// [serviceId] معرف الخدمة
/// [startAt] وقت بداية الموعد
/// [type] نوع الموعد: 'IN_PERSON', 'VIDEO', 'CHAT'
/// [metadata] بيانات إضافية (اختياري)
/// [idempotencyKey] مفتاح منع التكرار (اختياري)
Future<Appointment> createAppointment({
  required String doctorId,
  required String serviceId,
  required DateTime startAt,
  required String type,
  Map<String, dynamic>? metadata,
  String? idempotencyKey,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    // التحقق من نوع الموعد
    if (!['IN_PERSON', 'VIDEO', 'CHAT'].contains(type)) {
      throw Exception('نوع الموعد غير صحيح');
    }

    final body = {
      'doctorId': doctorId,
      'serviceId': serviceId,
      'startAt': startAt.toUtc().toIso8601String(),
      'type': type,
      if (metadata != null) 'metadata': metadata,
    };

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
    };

    final response = await post(
      '/patient/appointments',
      body,
      headers: headers,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Appointment.fromJson(jsonData);
    } else {
      final error = jsonDecode(response.body);
      final message = error['message'] ?? 'فشل إنشاء الموعد';
      throw Exception(message);
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في إنشاء الموعد: ${e.toString()}');
  }
}
```

#### 2.2 إضافة دالة إلغاء موعد

```dart
/// إلغاء موعد
/// 
/// [appointmentId] معرف الموعد
/// [reason] سبب الإلغاء (اختياري)
Future<Appointment> cancelAppointment({
  required String appointmentId,
  String? reason,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    final body = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await post(
      '/patient/appointments/$appointmentId/cancel',
      body,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Appointment.fromJson(jsonData);
    } else {
      final error = jsonDecode(response.body);
      final message = error['message'] ?? 'فشل إلغاء الموعد';
      throw Exception(message);
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في إلغاء الموعد: ${e.toString()}');
  }
}
```

#### 2.3 إضافة دالة إعادة جدولة موعد

```dart
/// إعادة جدولة موعد
/// 
/// [appointmentId] معرف الموعد
/// [newStartAt] وقت البداية الجديد
/// [metadata] بيانات إضافية (اختياري)
Future<Appointment> rescheduleAppointment({
  required String appointmentId,
  required DateTime newStartAt,
  Map<String, dynamic>? metadata,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    final body = {
      'newStartAt': newStartAt.toUtc().toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await post(
      '/patient/appointments/$appointmentId/reschedule',
      body,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Appointment.fromJson(jsonData);
    } else {
      final error = jsonDecode(response.body);
      final message = error['message'] ?? 'فشل إعادة جدولة الموعد';
      throw Exception(message);
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في إعادة جدولة الموعد: ${e.toString()}');
  }
}
```

#### 2.4 إضافة دالة جلب توفر الطبيب (اختياري لكن مفيد)

```dart
/// جلب أوقات التوفر للطبيب
/// 
/// [doctorId] معرف الطبيب
/// [serviceId] معرف الخدمة
/// [weekStart] تاريخ بداية الأسبوع (اختياري)
Future<Map<String, dynamic>> getDoctorAvailability({
  required String doctorId,
  required String serviceId,
  String? weekStart,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    final queryParams = <String, String>{
      'serviceId': serviceId,
      if (weekStart != null) 'weekStart': weekStart,
    };

    final uri = Uri.parse('$baseUrl/patient/doctors/$doctorId/availability')
        .replace(queryParameters: queryParams);

    final headers = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers).timeout(
      Duration(seconds: ApiConfig.requestTimeout),
      onTimeout: () {
        throw Exception('انتهت مهلة الاتصال');
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'فشل جلب أوقات التوفر');
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في جلب أوقات التوفر: ${e.toString()}');
  }
}
```

**المهام:**
- [ ] إضافة `createAppointment()`
- [ ] إضافة `cancelAppointment()`
- [ ] إضافة `rescheduleAppointment()`
- [ ] إضافة `getDoctorAvailability()` (اختياري)
- [ ] اختبار جميع الدوال مع الباك اند
- [ ] معالجة الأخطاء بشكل صحيح

---

### المرحلة 3: تحديث AppointmentsScreen ⏱️ 3 ساعات

#### 3.1 تحديث دالة `_cancelAppointment`

**الملف:** `lib/screens/appointments/appointments_screen.dart`

**التغييرات المطلوبة:**

```dart
void _cancelAppointment(Appointment appointment) async {
  // التحقق من الحالة
  if (appointment.status != 'PENDING_CONFIRM' && 
      appointment.status != 'CONFIRMED') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن إلغاء موعد بهذه الحالة'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // التحقق من المهلة (24 ساعة)
  final now = DateTime.now();
  final hoursUntil = appointment.startAt.difference(now).inHours;
  if (hoursUntil <= 24) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن إلغاء الموعد قبل أقل من 24 ساعة'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final reasonController = TextEditingController();
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إلغاء الموعد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من رغبتك في إلغاء هذا الموعد؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (اختياري)',
                hintText: 'مثال: تغير في الخطط',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && mounted) {
    try {
      setState(() => _isLoading = true);

      final token = await _authService.getToken();
      await _apiService.cancelAppointment(
        appointmentId: appointment.id,
        reason: reasonController.text.isNotEmpty 
            ? reasonController.text 
            : null,
        token: token,
      );

      setState(() => _isLoading = false);

      // إعادة تحميل المواعيد
      setState(() {}); // إعادة بناء الشاشة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الموعد بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
```

#### 3.2 تحديث دالة `_rescheduleAppointment`

```dart
void _rescheduleAppointment(Appointment appointment) async {
  // التحقق من الحالة
  if (appointment.status != 'PENDING_CONFIRM' && 
      appointment.status != 'CONFIRMED') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن إعادة جدولة موعد بهذه الحالة'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // التحقق من المهلة (24 ساعة)
  final now = DateTime.now();
  final hoursUntil = appointment.startAt.difference(now).inHours;
  if (hoursUntil <= 24) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يمكن إعادة جدولة الموعد قبل أقل من 24 ساعة'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // اختيار التاريخ الجديد
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: appointment.startAt.add(const Duration(days: 1)),
    firstDate: DateTime.now().add(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('ar', 'SA'),
    helpText: 'اختر تاريخاً جديداً',
  );

  if (selectedDate == null) return;

  // اختيار الوقت الجديد
  TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(appointment.startAt),
    helpText: 'اختر وقتاً جديداً',
  );

  if (selectedTime == null) return;

  final newStartAt = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );

  // التأكيد
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إعادة جدولة الموعد'),
        content: Text(
          'هل تريد تغيير الموعد إلى:\n'
          '${_formatDate(newStartAt)}\n'
          '${_formatTime(newStartAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && mounted) {
    try {
      setState(() => _isLoading = true);

      final token = await _authService.getToken();
      await _apiService.rescheduleAppointment(
        appointmentId: appointment.id,
        newStartAt: newStartAt,
        token: token,
      );

      setState(() => _isLoading = false);

      // إعادة تحميل المواعيد
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة جدولة الموعد بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
```

**المهام:**
- [ ] تحديث `_cancelAppointment` للاتصال بالـ API
- [ ] تحديث `_rescheduleAppointment` للاتصال بالـ API
- [ ] إضافة التحقق من الحالة والمهلة الزمنية
- [ ] تحسين رسائل الخطأ
- [ ] إضافة indicators التحميل
- [ ] إعادة تحميل البيانات بعد التغييرات

---

### المرحلة 4: إنشاء شاشة حجز موعد جديد ⏱️ 4 ساعات

#### 4.1 إنشاء `lib/screens/appointments/book_appointment_screen.dart`

**الميزات المطلوبة:**
- اختيار الطبيب والخدمة
- اختيار نوع الموعد (حضور شخصي / فيديو / محادثة)
- عرض أوقات التوفر
- اختيار التاريخ والوقت
- عرض السعر والمدة
- تأكيد الحجز

**البنية المقترحة:**

```dart
class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  final String? doctorName;
  final String serviceId;
  final String? serviceName;

  const BookAppointmentScreen({
    Key? key,
    required this.doctorId,
    this.doctorName,
    required this.serviceId,
    this.serviceName,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  // State variables
  DateTime? _selectedDate;
  String? _selectedTime;
  String _selectedType = 'IN_PERSON';
  bool _isLoading = false;
  bool _loadingAvailability = false;
  Map<String, dynamic>? _availability;
  double? _price;
  int? _duration;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    // جلب أوقات التوفر
  }

  Future<void> _bookAppointment() async {
    // إنشاء الموعد
  }

  Widget _buildTypeSelector() {
    // اختيار نوع الموعد
  }

  Widget _buildDateSelector() {
    // اختيار التاريخ
  }

  Widget _buildTimeSelector() {
    // اختيار الوقت من الأوقات المتاحة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الطبيب والخدمة
            // نوع الموعد
            // اختيار التاريخ
            // اختيار الوقت
            // معلومات السعر والمدة
            // زر الحجز
          ],
        ),
      ),
    );
  }
}
```

**المهام:**
- [ ] إنشاء ملف `book_appointment_screen.dart`
- [ ] تصميم واجهة اختيار نوع الموعد
- [ ] تصميم واجهة اختيار التاريخ
- [ ] تصميم واجهة اختيار الوقت من الأوقات المتاحة
- [ ] عرض معلومات السعر والمدة
- [ ] ربط زر الحجز بالـ API
- [ ] معالجة الأخطاء والتحقق
- [ ] إضافة indicators التحميل

---

### المرحلة 5: ربط شاشة الحجز بالتخصصات ⏱️ 2 ساعة

#### 5.1 تحديث `departments_screen.dart`

**إضافة زر "احجز موعد" في بطاقة الطبيب:**

```dart
// في _buildDoctorCard أو مكان مناسب
ElevatedButton.icon(
  onPressed: () async {
    // Navigate to booking screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          doctorId: doctor.id,
          doctorName: doctor.name,
          serviceId: serviceId, // من التخصص أو خدمة افتراضية
          serviceName: serviceName,
        ),
      ),
    );

    // إذا تم الحجز بنجاح، يمكن عرض رسالة
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حجز الموعد بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  },
  icon: const Icon(Iconsax.calendar),
  label: const Text('احجز موعد'),
)
```

**المهام:**
- [ ] إضافة زر الحجز في `departments_screen.dart`
- [ ] التنقل إلى `BookAppointmentScreen`
- [ ] تمرير المعاملات المطلوبة
- [ ] التعامل مع النتيجة

---

### المرحلة 6: شاشة تفاصيل الموعد ⏱️ 2 ساعة

#### 6.1 إنشاء `lib/screens/appointments/appointment_details_screen.dart`

**الميزات:**
- عرض جميع تفاصيل الموعد
- معلومات الطبيب والخدمة
- التاريخ والوقت
- الحالة والنوع
- السعر و حالة الدفع (إن وجد)
- سبب الإلغاء (إن كان ملغى)
- أزرار الإجراءات (إلغاء / إعادة جدولة)

**المهام:**
- [ ] إنشاء ملف `appointment_details_screen.dart`
- [ ] تصميم واجهة تفاصيل الموعد
- [ ] ربط أزرار الإجراءات
- [ ] التنقل من `AppointmentsScreen`

---

### المرحلة 7: التحسينات والتجربة ⏱️ 2 ساعة

#### 7.1 التحسينات المطلوبة

**معالجة الأخطاء:**
- [ ] رسائل خطأ واضحة بالعربية
- [ ] معالجة أخطاء الشبكة
- [ ] معالجة أخطاء التحقق (validation)

**تجربة المستخدم:**
- [ ] إضافة loading indicators
- [ ] إضافة pull-to-refresh في `AppointmentsScreen`
- [ ] تحسين رسائل النجاح والخطأ
- [ ] إضافة تأكيد قبل الإجراءات المهمة

**الأداء:**
- [ ] Cache للبيانات (اختياري)
- [ ] Lazy loading للمواعيد (pagination)
- [ ] تحسين سرعة الاستجابة

---

## 📝 ملاحظات تقنية مهمة

### 1. التواريخ والأوقات
- **مهم جداً:** الباك اند يتوقع ISO 8601 format بتوقيت UTC
- استخدم: `startAt.toUtc().toIso8601String()`
- عند قراءة البيانات: `DateTime.parse(json['startAt'])` (يتعامل تلقائياً مع UTC)

### 2. Idempotency Key
- استخدمه عند إنشاء موعد لتجنب الحجز المكرر
- يمكن استخدام: `'${DateTime.now().millisecondsSinceEpoch}_${doctorId}'`
- يتم إرساله في Header: `idempotency-key`

### 3. التحقق من المهلة
- الإلغاء/إعادة الجدولة مسموح قبل 24 ساعة على الأقل
- تحقق من ذلك في الواجهة قبل إرسال الطلب

### 4. حالات الموعد
- `PENDING_CONFIRM`: يمكن إلغاءه أو إعادة جدولته
- `CONFIRMED`: يمكن إلغاءه أو إعادة جدولته
- `CANCELLED`, `COMPLETED`, `REJECTED`: لا يمكن تعديله

### 5. أنواع المواعيد
- `IN_PERSON`: لا يتطلب دفع (عادة)
- `VIDEO`: يتطلب دفع (عادة)
- `CHAT`: يتطلب دفع (عادة)

---

## 🧪 الاختبار

### اختبارات مطلوبة:

1. **اختبار إنشاء موعد:**
   - [ ] حجز موعد حضور شخصي
   - [ ] حجز موعد فيديو
   - [ ] حجز موعد محادثة
   - [ ] التحقق من منع التكرار (Idempotency)
   - [ ] التحقق من رسائل الخطأ عند فشل الحجز

2. **اختبار إلغاء موعد:**
   - [ ] إلغاء موعد قبل 24 ساعة
   - [ ] محاولة إلغاء موعد بعد 24 ساعة (يجب أن يفشل)
   - [ ] محاولة إلغاء موعد مكتمل (يجب أن يفشل)
   - [ ] إلغاء مع سبب وبدون سبب

3. **اختبار إعادة الجدولة:**
   - [ ] إعادة جدولة قبل 24 ساعة
   - [ ] محاولة إعادة جدولة بعد 24 ساعة (يجب أن يفشل)
   - [ ] التحقق من التوفر الجديد

4. **اختبار عرض المواعيد:**
   - [ ] عرض المواعيد القادمة
   - [ ] عرض المواعيد السابقة
   - [ ] عرض المواعيد الملغاة
   - [ ] Refresh البيانات

---

## 📅 الجدول الزمني المقترح

| المرحلة | الوصف | الوقت المقدر |
|---------|-------|--------------|
| 1 | تحديث النماذج | 30 دقيقة |
| 2 | تحديث ApiService | 2 ساعة |
| 3 | تحديث AppointmentsScreen | 3 ساعات |
| 4 | شاشة حجز موعد جديد | 4 ساعات |
| 5 | ربط شاشة الحجز بالتخصصات | 2 ساعة |
| 6 | شاشة تفاصيل الموعد | 2 ساعة |
| 7 | التحسينات والاختبار | 2 ساعة |
| **المجموع** | | **~16 ساعة** |

---

## ✅ قائمة التحقق النهائية

### الوظائف الأساسية:
- [ ] إنشاء موعد جديد
- [ ] إلغاء موعد
- [ ] إعادة جدولة موعد
- [ ] عرض المواعيد (موجود)
- [ ] عرض تفاصيل الموعد

### الواجهات:
- [ ] شاشة حجز موعد جديدة
- [ ] شاشة تفاصيل الموعد
- [ ] تحديث شاشة المواعيد
- [ ] ربط الحجز من شاشة التخصصات

### التقنيات:
- [ ] تحديث النماذج
- [ ] إضافة دوال API
- [ ] معالجة الأخطاء
- [ ] تحسين تجربة المستخدم

### الاختبار:
- [ ] اختبار جميع الوظائف
- [ ] اختبار معالجة الأخطاء
- [ ] اختبار تجربة المستخدم

---

## 🔗 الروابط المرجعية

- [API Documentation](./API_INTEGRATION_SUMMARY.md)
- [Backend Appointments Service](../new/clinic-api/src/modules/schedule/services/appointment.service.ts)
- [Appointments Schema](../new/clinic-api/src/modules/schedule/schemas/appointment.schema.ts)
- [Patients Controller](../new/clinic-api/src/modules/patients/patients.controller.ts)

---

## 📞 ملاحظات إضافية

- تأكد من أن الباك اند يعمل قبل البدء
- اختبر كل دالة API بشكل منفصل أولاً
- استخدم print statements للت debugging
- راجع رسائل الخطأ من الباك اند بعناية
- استخدم try-catch في جميع الاستدعاءات

---

**تاريخ الإنشاء:** 2024  
**آخر تحديث:** 2024  
**الإصدار:** 1.0










# خطة تنفيذ ميزة الأطباء في تطبيق Flutter

## نظرة عامة

هذا المستند يوضح الخطة الشاملة لإضافة ميزة عرض واختيار الأطباء في تطبيق Flutter للمرضى، بناءً على نظام الباك اند الموجود.

---

## الأهداف

### الميزات المطلوبة:
1. عرض قائمة الأطباء
2. فلترة الأطباء حسب التخصص (Department)
3. فلترة الأطباء حسب الخدمة (Service)
4. البحث عن الأطباء بالاسم
5. عرض تفاصيل الطبيب
6. اختيار الطبيب عند الحجز
7. ربط الأطباء بشاشة الحجز

---

## البنية الحالية

### الملفات الموجودة:
```
patien_app/lib/
├── models/
│   ├── appointment.dart          ✅ موجود (يحتوي على DoctorInfo)
│   └── department.dart           ✅ موجود
├── services/
│   └── api_service.dart          ✅ موجود (يحتاج إضافة دوال الأطباء)
└── screens/
    ├── departments/
    │   └── departments_screen.dart  ✅ موجود (يحتاج ربط بالأطباء)
    └── appointments/
        └── book_appointment_screen.dart  ✅ موجود (يحتاج اختيار الطبيب)
```

### API Endpoints المتاحة في الباك اند:
```
GET /patient/doctors
- Query Parameters:
  - status?: string (افتراضياً APPROVED)
  - departmentId?: string
  - serviceId?: string
- Response: DoctorListItem[]

GET /patient/doctors/:id
- Response: DoctorDetails

GET /patient/doctors/:id/availability
- Query Parameters:
  - serviceId: string (مطلوب)
  - weekStart?: string
- Response: AvailabilityData
```

---

## المراحل التنفيذية

### المرحلة 1: إنشاء نموذج Doctor ⏱️ 30 دقيقة

#### 1.1 إنشاء `lib/models/doctor.dart`

**الحقول المطلوبة:**

```dart
class Doctor {
  final String id;
  final String name;
  final String? licenseNumber;
  final int? yearsOfExperience;
  final String? departmentId;
  final String? departmentName;
  final String? bio;
  final List<String>? photos;
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
    this.photos,
    required this.status,
    this.services,
    this.avatar,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      name: json['name'] ?? '',
      licenseNumber: json['licenseNumber'],
      yearsOfExperience: json['yearsOfExperience']?.toInt(),
      departmentId: json['departmentId']?['_id']?.toString() ?? 
                    json['departmentId']?.toString(),
      departmentName: json['departmentId']?['name'] ?? 
                      json['departmentName'],
      bio: json['bio'],
      photos: json['photos'] != null 
          ? List<String>.from(json['photos']) 
          : null,
      status: json['status'] ?? 'APPROVED',
      services: json['services'] != null
          ? (json['services'] as List)
              .map((s) => DoctorService.fromJson(s))
              .toList()
          : null,
      avatar: json['avatar'],
    );
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
    return DoctorService(
      serviceId: json['serviceId']?['_id']?.toString() ?? 
                 json['serviceId']?.toString() ?? '',
      serviceName: json['serviceId']?['name'] ?? 
                   json['serviceName'] ?? '',
      customPrice: json['customPrice']?.toDouble(),
      customDuration: json['customDuration']?.toInt(),
      isActive: json['isActive'] ?? true,
    );
  }
}
```

**المهام:**
- [ ] إنشاء ملف `doctor.dart`
- [ ] إضافة class `Doctor`
- [ ] إضافة class `DoctorService`
- [ ] إضافة `fromJson` factory
- [ ] اختبار parsing البيانات

---

### المرحلة 2: إضافة دوال API في ApiService ⏱️ 1 ساعة

#### 2.1 إضافة دالة جلب قائمة الأطباء

**الملف:** `lib/services/api_service.dart`

```dart
/// جلب قائمة الأطباء
/// 
/// [departmentId] فلترة حسب التخصص (اختياري)
/// [serviceId] فلترة حسب الخدمة (اختياري)
/// [status] فلترة حسب الحالة (افتراضياً APPROVED)
/// [token] رمز المصادقة
Future<List<Doctor>> getDoctors({
  String? departmentId,
  String? serviceId,
  String? status,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    final queryParams = <String, String>{};
    if (departmentId != null && departmentId.isNotEmpty) {
      queryParams['departmentId'] = departmentId;
    }
    if (serviceId != null && serviceId.isNotEmpty) {
      queryParams['serviceId'] = serviceId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final baseUri = Uri.parse(baseUrl);
    final path = '/patient/doctors';
    
    final uri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '${baseUri.path}$path',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final defaultHeaders = {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: defaultHeaders).timeout(
      Duration(seconds: ApiConfig.requestTimeout),
      onTimeout: () {
        throw Exception('انتهت مهلة الاتصال');
      },
    );

    if (response.statusCode == 401) {
      throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
    }

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> doctorsList = jsonData is List 
            ? jsonData 
            : (jsonData['data'] is List ? jsonData['data'] : []);
        
        return doctorsList
            .map((json) => Doctor.fromJson(json))
            .toList();
      } catch (e) {
        print('❌ Error parsing doctors response: $e');
        throw Exception('خطأ في معالجة استجابة الخادم');
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل جلب قائمة الأطباء');
      } catch (e) {
        throw Exception('فشل جلب قائمة الأطباء (${response.statusCode})');
      }
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في جلب قائمة الأطباء: ${e.toString()}');
  }
}
```

#### 2.2 إضافة دالة جلب تفاصيل الطبيب

```dart
/// جلب تفاصيل طبيب محدد
/// 
/// [doctorId] معرف الطبيب
/// [token] رمز المصادقة
Future<Doctor> getDoctorById({
  required String doctorId,
  String? token,
}) async {
  try {
    if (token == null || token.isEmpty) {
      throw Exception('غير مصرح - يرجى تسجيل الدخول');
    }

    final response = await getWithAuth(
      '/patient/doctors/$doctorId',
      token,
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        return Doctor.fromJson(jsonData);
      } catch (e) {
        print('❌ Error parsing doctor details response: $e');
        throw Exception('خطأ في معالجة استجابة الخادم');
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل جلب تفاصيل الطبيب');
      } catch (e) {
        throw Exception('فشل جلب تفاصيل الطبيب (${response.statusCode})');
      }
    }
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('خطأ في جلب تفاصيل الطبيب: ${e.toString()}');
  }
}
```

**المهام:**
- [ ] إضافة `getDoctors()` في ApiService
- [ ] إضافة `getDoctorById()` في ApiService
- [ ] إضافة import لـ Doctor model
- [ ] اختبار جميع الدوال مع الباك اند
- [ ] معالجة الأخطاء بشكل صحيح

---

### المرحلة 3: إنشاء شاشة قائمة الأطباء ⏱️ 3 ساعات

#### 3.1 إنشاء `lib/screens/doctors/doctors_screen.dart`

**الميزات المطلوبة:**
- عرض قائمة الأطباء
- بحث بالاسم
- فلترة حسب التخصص
- عرض معلومات أساسية (الاسم، التخصص، سنوات الخبرة)
- التنقل لتفاصيل الطبيب
- التنقل لشاشة الحجز

**البنية المقترحة:**

```dart
class DoctorsScreen extends StatefulWidget {
  final String? departmentId;
  final String? departmentName;
  final String? serviceId;
  final String? serviceName;

  const DoctorsScreen({
    super.key,
    this.departmentId,
    this.departmentName,
    this.serviceId,
    this.serviceName,
  });

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    // جلب الأطباء
  }

  void _filterDoctors() {
    // فلترة الأطباء حسب البحث
  }

  Widget _buildDoctorCard(Doctor doctor) {
    // بطاقة الطبيب
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName ?? 'الأطباء'),
      ),
      body: Column(
        children: [
          // Search bar
          // Doctors list
        ],
      ),
    );
  }
}
```

**المهام:**
- [ ] إنشاء ملف `doctors_screen.dart`
- [ ] تصميم شريط البحث
- [ ] تصميم بطاقة الطبيب
- [ ] ربط جلب البيانات بالـ API
- [ ] إضافة فلترة حسب البحث
- [ ] إضافة معالجة الأخطاء
- [ ] إضافة loading indicators
- [ ] إضافة pull-to-refresh

---

### المرحلة 4: إنشاء شاشة تفاصيل الطبيب ⏱️ 2 ساعة

#### 4.1 إنشاء `lib/screens/doctors/doctor_details_screen.dart`

**الميزات المطلوبة:**
- عرض جميع تفاصيل الطبيب
- عرض الصور (إن وجدت)
- عرض السيرة الذاتية
- عرض الخدمات المتاحة مع الأسعار
- عرض سنوات الخبرة
- زر الحجز المباشر

**المهام:**
- [ ] إنشاء ملف `doctor_details_screen.dart`
- [ ] تصميم واجهة تفاصيل الطبيب
- [ ] ربط جلب البيانات بالـ API
- [ ] إضافة زر الحجز
- [ ] التنقل لشاشة الحجز مع بيانات الطبيب

---

### المرحلة 5: تحديث شاشة الحجز لاختيار الطبيب ⏱️ 2 ساعة

#### 5.1 تحديث `book_appointment_screen.dart`

**التغييرات المطلوبة:**
- إضافة زر/قائمة لاختيار الطبيب
- إذا تم فتح الشاشة بدون طبيب، عرض قائمة الأطباء أولاً
- عرض الطبيب المختار بشكل واضح
- إمكانية تغيير الطبيب

**المهام:**
- [ ] إضافة UI لاختيار الطبيب
- [ ] ربط اختيار الطبيب بشاشة قائمة الأطباء
- [ ] تحديث validation ليتطلب اختيار الطبيب
- [ ] تحديث عرض معلومات الطبيب

---

### المرحلة 6: ربط شاشة التخصصات بالأطباء ⏱️ 1 ساعة

#### 6.1 تحديث `departments_screen.dart`

**التغييرات المطلوبة:**
- تحديث زر "عرض الأطباء المتاحين" للتنقل إلى `DoctorsScreen`
- تمرير `departmentId` للفلترة
- تحديث زر "حجز موعد" للتنقل إلى `DoctorsScreen` أولاً

**المهام:**
- [ ] تحديث زر "عرض الأطباء" في `_showDepartmentDetails()`
- [ ] تحديث زر "حجز موعد" للتنقل لشاشة الأطباء
- [ ] تمرير المعاملات المطلوبة

---

### المرحلة 7: التحسينات والتجربة ⏱️ 1 ساعة

#### 7.1 التحسينات المطلوبة

**معالجة الأخطاء:**
- [ ] رسائل خطأ واضحة بالعربية
- [ ] معالجة أخطاء الشبكة
- [ ] معالجة حالة عدم وجود أطباء

**تجربة المستخدم:**
- [ ] إضافة loading indicators
- [ ] إضافة pull-to-refresh
- [ ] تحسين رسائل الحالة الفارغة
- [ ] إضافة صور افتراضية للأطباء
- [ ] تحسين تصميم بطاقات الأطباء

**الأداء:**
- [ ] Cache للبيانات (اختياري)
- [ ] Lazy loading للأطباء (pagination إذا كان متوفراً)
- [ ] تحسين سرعة البحث

---

## ملاحظات تقنية مهمة

### 1. API Endpoints
- المسار الأساسي: `/patient/doctors`
- الفلترة: عبر query parameters
- المصادقة: مطلوبة (Bearer Token)

### 2. Flters المتاحة
- `departmentId`: فلترة حسب التخصص
- `serviceId`: فلترة حسب الخدمة
- `status`: فلترة حسب الحالة (افتراضياً APPROVED)

### 3. Response Structure
الباك اند قد يعيد:
- Array مباشر: `[{doctor1}, {doctor2}]`
- Object مع data: `{data: [{doctor1}, {doctor2}]}`
يجب معالجة كلا الحالتين

### 4. صور الأطباء
- قد تكون URLs كاملة أو نسبية
- استخدام `ApiConfig.buildFullUrl()` لتحويل المسارات النسبية
- إضافة صورة افتراضية إذا لم تكن موجودة

---

## الاختبار

### اختبارات مطلوبة:

1. **اختبار جلب الأطباء:**
   - [ ] جلب جميع الأطباء
   - [ ] فلترة حسب التخصص
   - [ ] فلترة حسب الخدمة
   - [ ] البحث بالاسم
   - [ ] معالجة الأخطاء

2. **اختبار تفاصيل الطبيب:**
   - [ ] عرض التفاصيل بشكل صحيح
   - [ ] عرض الخدمات
   - [ ] التنقل للحجز

3. **اختبار اختيار الطبيب:**
   - [ ] اختيار طبيب من القائمة
   - [ ] تمرير البيانات لشاشة الحجز
   - [ ] تغيير الطبيب

4. **اختبار ربط التخصصات:**
   - [ ] التنقل من التخصص للأطباء
   - [ ] الفلترة الصحيحة حسب التخصص
   - [ ] الحجز من شاشة الأطباء

---

## الجدول الزمني المقترح

| المرحلة | الوصف | الوقت المقدر |
|---------|-------|--------------|
| 1 | إنشاء نموذج Doctor | 30 دقيقة |
| 2 | إضافة دوال API | 1 ساعة |
| 3 | شاشة قائمة الأطباء | 3 ساعات |
| 4 | شاشة تفاصيل الطبيب | 2 ساعة |
| 5 | تحديث شاشة الحجز | 2 ساعة |
| 6 | ربط شاشة التخصصات | 1 ساعة |
| 7 | التحسينات والاختبار | 1 ساعة |
| **المجموع** | | **~11 ساعة** |

---

## قائمة التحقق النهائية

### الوظائف الأساسية:
- [ ] عرض قائمة الأطباء
- [ ] فلترة الأطباء
- [ ] البحث عن الأطباء
- [ ] عرض تفاصيل الطبيب
- [ ] اختيار الطبيب عند الحجز

### الواجهات:
- [ ] شاشة قائمة الأطباء
- [ ] شاشة تفاصيل الطبيب
- [ ] تحديث شاشة الحجز
- [ ] ربط شاشة التخصصات

### التقنيات:
- [ ] نموذج Doctor
- [ ] دوال API للأطباء
- [ ] معالجة الأخطاء
- [ ] تحسين تجربة المستخدم

### الاختبار:
- [ ] اختبار جميع الوظائف
- [ ] اختبار معالجة الأخطاء
- [ ] اختبار تجربة المستخدم

---

## الروابط المرجعية

- [API Documentation](./API_INTEGRATION_SUMMARY.md)
- [Backend Doctors API](../new/clinic-api/DOCTORS_API.md)
- [Patients Controller](../new/clinic-api/src/modules/patients/patients.controller.ts)
- [Patients Service](../new/clinic-api/src/modules/patients/patients.service.ts)

---

## ملاحظات إضافية

- تأكد من أن الباك اند يعمل قبل البدء
- اختبر كل دالة API بشكل منفصل أولاً
- استخدم print statements للت debugging
- راجع رسائل الخطأ من الباك اند بعناية
- استخدم try-catch في جميع الاستدعاءات
- تأكد من معالجة جميع حالات الاستجابة (array أو object)

---

**تاريخ الإنشاء:** 2024  
**آخر تحديث:** 2024  
**الإصدار:** 1.0









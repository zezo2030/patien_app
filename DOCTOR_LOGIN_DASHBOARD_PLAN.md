# خطة تنفيذ تسجيل دخول الطبيب و Dashboard خاص

## 📋 نظرة عامة

تطبيق هذه الخطة لإضافة إمكانية تسجيل دخول الطبيب في تطبيق المريض (Flutter) وعرض Dashboard خاص بالطبيب يحتوي على:
- لوحة تحكم رئيسية
- إدارة المواعيد (عرض، تأكيد، رفض)
- إدارة الجدول الزمني
- الملف الشخصي

---

## 🎯 الأهداف

1. ✅ دعم تسجيل دخول الطبيب بنفس صفحة تسجيل الدخول
2. ✅ التوجيه التلقائي حسب نوع المستخدم (PATIENT/DOCTOR)
3. ✅ إنشاء Dashboard خاص بالطبيب
4. ✅ إضافة شاشات إدارة المواعيد للطبيب
5. ✅ إضافة شاشة إدارة الجدول الزمني
6. ✅ دمج API Endpoints الخاصة بالطبيب

---

## 🔍 التحليل الحالي

### البنية الموجودة:

#### ✅ Models:
- `User` - يحتوي على `role` (PATIENT/DOCTOR/ADMIN)
- `AuthResponse` - يحتوي على `accessToken` و `user`
- `Appointment` - نموذج الموعد

#### ✅ Services:
- `AuthService` - خدمة المصادقة (تحفظ User و Token)
- `ApiService` - خدمة API (تحتوي على endpoints للمريض فقط حالياً)

#### ✅ Screens:
- `LoginScreen` - صفحة تسجيل الدخول
- `MainScreen` - Dashboard المريض
- `AppointmentsScreen` - مواعيد المريض

#### ✅ Backend APIs المتاحة:
- `POST /auth/login` - تسجيل دخول (يعمل لجميع الأدوار)
- `GET /doctor/appointments` - جلب مواعيد الطبيب
- `POST /doctor/appointments/:id/confirm` - تأكيد موعد
- `POST /doctor/appointments/:id/reject` - رفض موعد
- `GET /doctor/schedule` - جلب الجدول الزمني
- `POST /doctor/schedule` - إنشاء/تحديث الجدول
- `PATCH /doctor/schedule` - تحديث الجدول
- `POST /doctor/schedule/exceptions` - إضافة استثناء
- `POST /doctor/schedule/holidays` - إضافة عطلة

---

## 📝 الخطوات التفصيلية

### المرحلة 1: تعديل نظام المصادقة والتوجيه

#### 1.1 تعديل `login_screen.dart`
**الملف:** `lib/screens/auth/login_screen.dart`

**التعديلات:**
- بعد نجاح تسجيل الدخول، التحقق من `user.role`
- التوجيه حسب الـ Role:
  - `DOCTOR` → `/doctor-dashboard`
  - `PATIENT` أو آخر → `/home`

**الكود المقترح:**
```dart
await _authService.login(request);
final user = await _authService.getCurrentUser();

if (mounted) {
  if (user?.role == 'DOCTOR') {
    Navigator.of(context).pushReplacementNamed('/doctor-dashboard');
  } else {
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
```

#### 1.2 تعديل `main.dart` - AuthWrapper
**الملف:** `lib/main.dart`

**التعديلات:**
- تعديل `_checkAuthStatus()` لجلب بيانات المستخدم
- تعديل `build()` للتحقق من الـ Role وتحديد الوجهة المناسبة

**الكود المقترح:**
```dart
Future<void> _checkAuthStatus() async {
  final loggedIn = await _authService.isLoggedIn();
  setState(() {
    _isLoggedIn = loggedIn;
    _isLoading = false;
  });
}

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator())
    );
  }

  if (!_isLoggedIn) {
    return const LoginScreen();
  }

  return FutureBuilder<User?>(
    future: _authService.getCurrentUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator())
        );
      }
      
      final user = snapshot.data;
      if (user?.role == 'DOCTOR') {
        return const DoctorMainScreen();
      } else {
        return const MainScreen();
      }
    },
  );
}
```

#### 1.3 إضافة Routes
**الملف:** `lib/main.dart`

**التعديلات:**
- إضافة route للـ Doctor Dashboard

```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const MainScreen(),
  '/doctor-dashboard': (context) => const DoctorMainScreen(),
},
```

---

### المرحلة 2: إضافة API Methods للطبيب

#### 2.1 إضافة Methods في `api_service.dart`
**الملف:** `lib/services/api_service.dart`

**Methods المطلوبة:**

##### 1. جلب مواعيد الطبيب
```dart
Future<PaginatedAppointments> getDoctorAppointments({
  String? status,
  int page = 1,
  int limit = 100,
  String? token,
}) async {
  // GET /v1/doctor/appointments
  // Query params: status, page, limit
}
```

##### 2. تأكيد موعد
```dart
Future<Appointment> confirmAppointment({
  required String appointmentId,
  String? notes,
  String? token,
}) async {
  // POST /v1/doctor/appointments/:id/confirm
  // Body: { notes?: string }
}
```

##### 3. رفض موعد
```dart
Future<Appointment> rejectAppointment({
  required String appointmentId,
  required String reason,
  String? token,
}) async {
  // POST /v1/doctor/appointments/:id/reject
  // Body: { reason: string }
}
```

##### 4. جلب الجدول الزمني
```dart
Future<Map<String, dynamic>> getDoctorSchedule({
  String? token,
}) async {
  // GET /v1/doctor/schedule
}
```

##### 5. إنشاء/تحديث الجدول الزمني
```dart
Future<Map<String, dynamic>> createOrUpdateSchedule({
  required Map<String, dynamic> scheduleData,
  String? token,
}) async {
  // POST /v1/doctor/schedule
  // Body: {
  //   weeklyTemplate: [...],
  //   defaultBufferBefore?: number,
  //   defaultBufferAfter?: number,
  //   serviceBuffers?: [...]
  // }
}
```

##### 6. تحديث الجدول الزمني (جزئي)
```dart
Future<Map<String, dynamic>> updateSchedule({
  required Map<String, dynamic> updateData,
  String? token,
}) async {
  // PATCH /v1/doctor/schedule
}
```

##### 7. إضافة استثناء للجدول
```dart
Future<Map<String, dynamic>> addScheduleException({
  required String date,
  required bool isAvailable,
  List<Map<String, String>>? slots,
  String? reason,
  String? token,
}) async {
  // POST /v1/doctor/schedule/exceptions
  // Body: { date, isAvailable, slots?, reason? }
}
```

##### 8. حذف استثناء
```dart
Future<void> removeScheduleException({
  required String date,
  String? token,
}) async {
  // DELETE /v1/doctor/schedule/exceptions/:date
}
```

##### 9. إضافة عطلة
```dart
Future<Map<String, dynamic>> addHoliday({
  required String startDate,
  required String endDate,
  String? reason,
  String? token,
}) async {
  // POST /v1/doctor/schedule/holidays
  // Body: { startDate, endDate, reason? }
}
```

##### 10. حذف عطلة
```dart
Future<void> removeHoliday({
  required String holidayId,
  String? token,
}) async {
  // DELETE /v1/doctor/schedule/holidays/:holidayId
}
```

---

### المرحلة 3: إنشاء Doctor Dashboard Screens

#### 3.1 Doctor Main Screen
**الملف:** `lib/screens/doctor/doctor_main_screen.dart`

**الوصف:**
- شاشة رئيسية تحتوي على Bottom Navigation Bar
- 4 تبويبات:
  1. الرئيسية (Doctor Home)
  2. المواعيد (Doctor Appointments)
  3. الجدول الزمني (Doctor Schedule)
  4. الملف الشخصي (Profile - نفس الشاشة الموجودة)

**الهيكل:**
```dart
class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});
  
  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DoctorHomeScreen(),
    const DoctorAppointmentsScreen(),
    const DoctorScheduleScreen(),
    const ProfileScreen(),
  ];
  
  // ... build method
}
```

#### 3.2 Doctor Home Screen
**الملف:** `lib/screens/doctor/doctor_home_screen.dart`

**المميزات:**
- بطاقة ترحيبية باسم الطبيب
- بطاقات إحصائيات:
  - عدد المواعيد اليوم
  - المواعيد في الانتظار (PENDING_CONFIRM)
  - المواعيد المؤكدة اليوم (CONFIRMED)
  - المواعيد المكتملة هذا الأسبوع
- قائمة سريعة بالمواعيد القادمة (آخر 3 مواعيد)

**المكونات:**
- `_buildWelcomeCard()` - بطاقة الترحيب
- `_buildStatsCards()` - بطاقات الإحصائيات
- `_buildUpcomingAppointments()` - قائمة المواعيد القادمة
- `_loadStats()` - جلب الإحصائيات من API

#### 3.3 Doctor Appointments Screen
**الملف:** `lib/screens/doctor/doctor_appointments_screen.dart`

**المميزات:**
- TabBar مع 3 تبويبات:
  1. في الانتظار (PENDING_CONFIRM)
  2. المؤكدة (CONFIRMED)
  3. المكتملة (COMPLETED)
- كل موعد يحتوي على:
  - معلومات المريض (الاسم، رقم الهاتف)
  - وقت الموعد (التاريخ والوقت)
  - نوع الموعد (حضور/فيديو/محادثة)
  - الخدمة
  - أزرار: تأكيد / رفض (للمواعيد في الانتظار)
- تفاصيل الموعد عند الضغط عليه

**الحالات:**
- Loading state
- Empty state
- Error state
- Success state with appointments list

**Actions:**
- تأكيد موعد (مع إمكانية إضافة ملاحظات)
- رفض موعد (مع إلزام إدخال السبب)
- عرض تفاصيل الموعد الكاملة

#### 3.4 Doctor Schedule Screen
**الملف:** `lib/screens/doctor/doctor_schedule_screen.dart`

**المميزات:**
- عرض الجدول الأسبوعي الحالي
- إضافة/تعديل الجدول الأسبوعي:
  - اختيار الأيام المتاحة (0-6)
  - إضافة فترات زمنية لكل يوم (startTime, endTime)
  - تحديد Buffers (قبل وبعد الموعد)
- إدارة الاستثناءات:
  - إضافة استثناء ليوم محدد
  - حذف استثناء
- إدارة العطلات:
  - إضافة عطلة (تاريخ بداية ونهاية)
  - حذف عطلة
- معاينة الجدول

**المكونات:**
- `_buildWeeklySchedule()` - عرض الجدول الأسبوعي
- `_buildScheduleEditor()` - محرر الجدول
- `_buildExceptionsList()` - قائمة الاستثناءات
- `_buildHolidaysList()` - قائمة العطلات
- `_showAddExceptionDialog()` - Dialog لإضافة استثناء
- `_showAddHolidayDialog()` - Dialog لإضافة عطلة

---

### المرحلة 4: إنشاء Models إضافية (إذا لزم الأمر)

#### 4.1 Schedule Models
**الملف:** `lib/models/doctor_schedule.dart`

```dart
class DoctorSchedule {
  final String doctorId;
  final List<WeeklyTemplate> weeklyTemplate;
  final int defaultBufferBefore;
  final int defaultBufferAfter;
  final List<ServiceBuffer> serviceBuffers;
  final List<ScheduleException> exceptions;
  final List<Holiday> holidays;
  
  // fromJson, toJson methods
}

class WeeklyTemplate {
  final int dayOfWeek; // 0-6
  final List<TimeSlot> slots;
  final bool isAvailable;
}

class TimeSlot {
  final String startTime; // "09:00"
  final String endTime;   // "17:00"
}

class ScheduleException {
  final DateTime date;
  final List<TimeSlot> slots;
  final bool isAvailable;
  final String reason;
}

class Holiday {
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
}
```

---

### المرحلة 5: تحسينات UX/UI

#### 5.1 Bottom Navigation Bar
- تخصيص الأيقونات والنصوص للطبيب
- إضافة badges للتبويبات (مثل عدد المواعيد في الانتظار)

#### 5.2 Loading States
- إضافة Loading indicators في جميع الشاشات
- Skeleton screens للبيانات الثقيلة

#### 5.3 Error Handling
- معالجة الأخطاء بشكل أفضل
- رسائل خطأ واضحة بالعربية
- Retry mechanisms

#### 5.4 Refresh Functionality
- Pull-to-refresh في قوائم المواعيد
- Auto-refresh للبيانات المهمة

---

## 📁 الملفات المطلوب إنشاؤها

### Screens:
1. ✅ `lib/screens/doctor/doctor_main_screen.dart`
2. ✅ `lib/screens/doctor/doctor_home_screen.dart`
3. ✅ `lib/screens/doctor/doctor_appointments_screen.dart`
4. ✅ `lib/screens/doctor/doctor_schedule_screen.dart`

### Models:
5. ✅ `lib/models/doctor_schedule.dart` (اختياري - إذا كان سيستخدم Model)

### Widgets (اختياري):
6. ✅ `lib/widgets/doctor/appointment_card.dart` - بطاقة موعد للطبيب
7. ✅ `lib/widgets/doctor/schedule_day_widget.dart` - عرض يوم في الجدول
8. ✅ `lib/widgets/doctor/time_slot_editor.dart` - محرر الفترات الزمنية

---

## 📁 الملفات المطلوب تعديلها

### تعديلات أساسية:
1. ✅ `lib/main.dart` - تعديل AuthWrapper وإضافة routes
2. ✅ `lib/screens/auth/login_screen.dart` - إضافة التحقق من Role
3. ✅ `lib/services/api_service.dart` - إضافة Doctor API methods

### تعديلات اختيارية:
4. ✅ `lib/widgets/navigation/bottom_nav_bar.dart` - دعم تخصيص للأطباء (اختياري)

---

## 🔌 API Endpoints المطلوبة

### المواعيد:
- `GET /v1/doctor/appointments` - جلب مواعيد الطبيب
- `POST /v1/doctor/appointments/:id/confirm` - تأكيد موعد
- `POST /v1/doctor/appointments/:id/reject` - رفض موعد

### الجدول الزمني:
- `GET /v1/doctor/schedule` - جلب الجدول
- `POST /v1/doctor/schedule` - إنشاء/تحديث الجدول
- `PATCH /v1/doctor/schedule` - تحديث جزئي
- `POST /v1/doctor/schedule/exceptions` - إضافة استثناء
- `DELETE /v1/doctor/schedule/exceptions/:date` - حذف استثناء
- `POST /v1/doctor/schedule/holidays` - إضافة عطلة
- `DELETE /v1/doctor/schedule/holidays/:holidayId` - حذف عطلة

---

## ✅ قائمة المهام (Checklist)

### المرحلة 1: المصادقة والتوجيه
- [ ] تعديل `login_screen.dart` للتحقق من Role
- [ ] تعديل `main.dart` - AuthWrapper
- [ ] إضافة routes للـ Doctor Dashboard
- [ ] اختبار تسجيل دخول الطبيب
- [ ] اختبار تسجيل دخول المريض (للتأكد من عدم كسر الوظائف الموجودة)

### المرحلة 2: API Integration
- [ ] إضافة `getDoctorAppointments()` في `api_service.dart`
- [ ] إضافة `confirmAppointment()` في `api_service.dart`
- [ ] إضافة `rejectAppointment()` في `api_service.dart`
- [ ] إضافة `getDoctorSchedule()` في `api_service.dart`
- [ ] إضافة `createOrUpdateSchedule()` في `api_service.dart`
- [ ] إضافة `updateSchedule()` في `api_service.dart`
- [ ] إضافة `addScheduleException()` في `api_service.dart`
- [ ] إضافة `removeScheduleException()` في `api_service.dart`
- [ ] إضافة `addHoliday()` في `api_service.dart`
- [ ] إضافة `removeHoliday()` في `api_service.dart`
- [ ] اختبار جميع API methods

### المرحلة 3: Doctor Screens
- [ ] إنشاء `doctor_main_screen.dart`
- [ ] إنشاء `doctor_home_screen.dart`
- [ ] إنشاء `doctor_appointments_screen.dart`
- [ ] إنشاء `doctor_schedule_screen.dart`
- [ ] اختبار التنقل بين الشاشات
- [ ] اختبار عرض البيانات

### المرحلة 4: الوظائف التفاعلية
- [ ] تنفيذ تأكيد الموعد
- [ ] تنفيذ رفض الموعد
- [ ] تنفيذ عرض/تعديل الجدول
- [ ] تنفيذ إضافة استثناء
- [ ] تنفيذ إضافة عطلة
- [ ] اختبار جميع الوظائف

### المرحلة 5: التحسينات
- [ ] إضافة Loading states
- [ ] إضافة Error handling
- [ ] إضافة Pull-to-refresh
- [ ] تحسين UI/UX
- [ ] إضافة Toast messages للنجاح/الخطأ
- [ ] اختبار نهائي شامل

---

## 🧪 اختبارات مقترحة

### Unit Tests:
- [ ] اختبار AuthService - التحقق من Role
- [ ] اختبار ApiService - Doctor endpoints

### Integration Tests:
- [ ] اختبار تسجيل دخول الطبيب والتنقل
- [ ] اختبار جلب مواعيد الطبيب
- [ ] اختبار تأكيد/رفض الموعد
- [ ] اختبار إدارة الجدول الزمني

### Manual Testing:
- [ ] تسجيل دخول كطبيب وتحقق من فتح Dashboard
- [ ] عرض المواعيد وتصفيتها
- [ ] تأكيد موعد
- [ ] رفض موعد مع إدخال السبب
- [ ] عرض الجدول الزمني
- [ ] إضافة/تعديل الجدول
- [ ] إضافة استثناء
- [ ] إضافة عطلة

---

## 📅 الجدول الزمني المقترح

### الأسبوع 1: الأساسيات
- **يوم 1-2:** تعديل نظام المصادقة والتوجيه
- **يوم 3-4:** إضافة API Methods
- **يوم 5:** اختبار APIs

### الأسبوع 2: الشاشات الأساسية
- **يوم 1-2:** Doctor Main Screen و Home Screen
- **يوم 3-4:** Doctor Appointments Screen
- **يوم 5:** اختبار الشاشات

### الأسبوع 3: الجدول الزمني
- **يوم 1-3:** Doctor Schedule Screen
- **يوم 4-5:** اختبار وتصحيح الأخطاء

### الأسبوع 4: التحسينات والاختبارات
- **يوم 1-2:** تحسينات UX/UI
- **يوم 3-4:** اختبارات شاملة
- **يوم 5:** توثيق نهائي

---

## 🎨 تصميم UI/UX

### الألوان:
- استخدام نفس نظام الألوان الموجود (`AppColors`)
- تمييز بسيط للـ Doctor Dashboard (مثلاً: لون مختلف للـ AppBar)

### الأيقونات:
- استخدام `Iconsax` أو `Material Icons`
- أيقونات واضحة ومعبرة لكل قسم

### التخطيط:
- تصميم responsive
- دعم RTL (من اليمين لليسار)
- مسافات مناسبة (`AppDimensions`)

---

## 📚 ملاحظات مهمة

### الأمان:
- ✅ التأكد من أن API calls تستخدم Bearer Token
- ✅ التحقق من Role في Backend أيضاً
- ✅ عدم عرض بيانات حساسة في Logs

### الأداء:
- ✅ استخدام `FutureBuilder` للبيانات غير المتزامنة
- ✅ Caching للبيانات الثابتة (مثل الجدول الزمني)
- ✅ Lazy loading للقوائم الطويلة

### التوافق:
- ✅ التأكد من عدم كسر وظائف المريض الموجودة
- ✅ الحفاظ على نفس نمط الكود الموجود
- ✅ استخدام نفس الـ Models والـ Services حيثما أمكن

---

## 🚀 البدء في التنفيذ

1. ابدأ بالمرحلة 1 (المصادقة والتوجيه)
2. اختبر كل مرحلة قبل الانتقال للتالية
3. راجع الكود الموجود لفهم الأنماط المستخدمة
4. استخدم `print()` statements للـ debugging
5. راجع Backend APIs للتأكد من Response format

---

## 📞 الدعم والمراجع

### ملفات مهمة للمراجعة:
- `lib/services/api_service.dart` - لفهم نمط API calls
- `lib/screens/appointments/appointments_screen.dart` - كمرجع لتصميم شاشة المواعيد
- `lib/models/appointment.dart` - لفهم نموذج الموعد

### Backend Documentation:
- راجع `new/clinic-api/src/modules/doctors/doctors.controller.ts`
- راجع `new/clinic-api/src/modules/schedule/services/appointment.service.ts`

---

## ✨ خاتمة

بعد إتمام هذه الخطة، سيكون تطبيق المريض يدعم:
- ✅ تسجيل دخول الطبيب
- ✅ Dashboard خاص بالطبيب
- ✅ إدارة كاملة للمواعيد
- ✅ إدارة الجدول الزمني
- ✅ واجهة مستخدم احترافية وسهلة الاستخدام

**تاريخ إنشاء الخطة:** 2024  
**آخر تحديث:** 2024







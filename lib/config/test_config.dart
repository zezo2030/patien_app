/// إعدادات الاختبار
///
/// هذا الملف يحتوي على flags للاختبار التي تسمح بتجاوز بعض القيود
/// ⚠️ تحذير: يجب تعطيل هذه الإعدادات في الإنتاج
class TestConfig {
  // تفعيل وضع الاختبار
  // عند تفعيله، سيتم:
  // 1. تجاوز التحقق من الدفع للسماح بمكالمات الفيديو
  // 2. السماح بحجز المواعيد بعد 10 دقائق فقط من الآن
  static const bool enableTestMode = true;

  // تجاوز التحقق من الدفع للاختبار
  // عند تفعيله، سيتم السماح بمكالمات الفيديو حتى لو لم يتم الدفع
  static const bool bypassPaymentCheck = true;

  // السماح بحجز المواعيد بعد 10 دقائق فقط (للاختبار)
  // عند تفعيله، يمكن حجز موعد بعد 10 دقائق فقط من الآن
  // عند تعطيله، يجب أن يكون الموعد بعد 24 ساعة على الأقل (السلوك الافتراضي)
  static const bool allowBookingAfter10Minutes = true;

  // الحد الأدنى للدقائق قبل الموعد للحجز (عند تفعيل allowBookingAfter10Minutes)
  static const int minimumMinutesBeforeAppointment = 10;

  /// التحقق من أن وضع الاختبار مفعل
  static bool get isTestModeEnabled => enableTestMode;

  /// التحقق من تجاوز الدفع
  static bool get shouldBypassPayment => enableTestMode && bypassPaymentCheck;

  /// التحقق من السماح بالحجز بعد 10 دقائق
  static bool get shouldAllowQuickBooking =>
      enableTestMode && allowBookingAfter10Minutes;
}







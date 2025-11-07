# دليل إصلاح مشكلة Agora RTC Engine

## المشكلة
```
MissingPluginException(No implementation found for method androidInit on channel agora_rtc_ng)
```

## الحل

### الخطوة 1: إعادة بناء التطبيق بالكامل

لا تستخدم Hot Reload أو Hot Restart. يجب إعادة بناء التطبيق بالكامل:

```bash
# 1. إيقاف التطبيق تماماً
# اضغط على زر الإيقاف في Android Studio أو أغلق التطبيق من الجهاز

# 2. تنظيف المشروع
cd patien_app
flutter clean

# 3. إعادة تثبيت الحزم
flutter pub get

# 4. إعادة بناء وتشغيل التطبيق
flutter run
```

### الخطوة 2: التأكد من الصلاحيات

تأكد من أن التطبيق لديه صلاحيات الكاميرا والميكروفون:

1. افتح إعدادات الجهاز
2. التطبيقات > patien_app
3. الصلاحيات
4. فعّل الكاميرا والميكروفون

### الخطوة 3: اختبار على جهاز حقيقي (اختياري)

إذا كنت تستخدم محاكي (Emulator)، قد لا يعمل Agora بشكل صحيح. جرب على جهاز حقيقي:

```bash
flutter devices  # لرؤية الأجهزة المتاحة
flutter run -d <device_id>
```

### الخطوة 4: إذا استمرت المشكلة

#### أ) تحقق من إصدار Agora

في `pubspec.yaml`:
```yaml
agora_rtc_engine: ^6.3.0
```

إذا كانت المشكلة مستمرة، جرب إصدار آخر:
```yaml
agora_rtc_engine: ^6.2.0
```

ثم:
```bash
flutter clean
flutter pub get
flutter run
```

#### ب) تحقق من إعدادات Android

في `android/app/build.gradle`، تأكد من:
```gradle
android {
    compileSdkVersion 34  // أو أحدث
    ...
    defaultConfig {
        minSdkVersion 21  // Agora يحتاج على الأقل 21
        targetSdkVersion 34
    }
}
```

#### ج) إعادة بناء Android فقط

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### الخطوة 5: للاختبار بدون Agora (مؤقت)

إذا كنت تريد اختبار بقية الميزات بدون Agora، يمكنك تعطيل التحقق من Agora مؤقتاً:

في `video_call_screen.dart`، يمكنك إضافة try-catch لمعالجة الخطأ بشكل أفضل.

## ملاحظات مهمة

1. **Hot Reload لا يعمل مع Native Plugins**: يجب إعادة بناء التطبيق بالكامل
2. **المحاكي**: Agora قد لا يعمل بشكل صحيح على المحاكي - استخدم جهاز حقيقي
3. **الصلاحيات**: تأكد من منح الصلاحيات عند الطلب

## التحقق من نجاح الإصلاح

بعد إعادة البناء، يجب أن ترى في الـ logs:
```
✅ Agora engine initialized successfully
```

بدلاً من:
```
❌ Error initializing Agora engine: MissingPluginException
```




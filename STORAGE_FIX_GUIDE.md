# دليل حل مشكلة عدم وجود مساحة تخزين في المحاكي

## المشكلة
```
INSTALL_FAILED_INSUFFICIENT_STORAGE: Failed to override installation location
```

## الحلول

### الحل 1: تنظيف مساحة المحاكي (الأسرع)

1. افتح Android Studio
2. اذهب إلى **Tools > Device Manager**
3. اختر المحاكي الذي تستخدمه
4. اضغط على أيقونة **▶️** (تشغيل المحاكي)
5. بعد فتح المحاكي، افتح **Settings** في المحاكي
6. اذهب إلى **Storage**
7. اضغط على **Free up space** أو **Clear cache**
8. احذف التطبيقات غير المستخدمة

### الحل 2: زيادة مساحة المحاكي

1. في Android Studio، اذهب إلى **Tools > Device Manager**
2. اضغط على **Edit** (أيقونة القلم) بجانب المحاكي
3. اضغط **Show Advanced Settings**
4. زد **Internal Storage** إلى **8 GB** أو أكثر
5. احفظ التغييرات
6. احذف المحاكي القديم وأنشئ واحداً جديداً (اختياري)

### الحل 3: مسح بيانات المحاكي (Wipe Data)

1. في Android Studio، اذهب إلى **Tools > Device Manager**
2. اضغط على **▼** (سهم لأسفل) بجانب المحاكي
3. اختر **Wipe Data**
4. سيتم حذف جميع البيانات وإنشاء محاكي جديد نظيف
5. شغّل المحاكي مرة أخرى

### الحل 4: استخدام محاكي جديد

1. في Android Studio، اذهب إلى **Tools > Device Manager**
2. اضغط على **Create Device**
3. اختر جهاز (مثلاً: Pixel 5)
4. اختر **System Image** (API 34 أو أحدث)
5. في **Advanced Settings**:
   - **Internal Storage**: 8 GB أو أكثر
   - **SD Card**: 1 GB
6. احفظ وأنشئ المحاكي
7. شغّل المحاكي الجديد

### الحل 5: تنظيف من Terminal

افتح Terminal في المحاكي أو استخدم ADB:

```bash
# الاتصال بالمحاكي
adb devices

# تنظيف بيانات التطبيق
adb shell pm clear com.example.patien_app

# حذف التطبيق القديم
adb uninstall com.example.patien_app

# تنظيف الكاش
adb shell pm trim-caches 512M

# محاولة التثبيت مرة أخرى
flutter run
```

### الحل 6: استخدام جهاز حقيقي (موصى به)

1. فعّل **Developer Options** على جهاز Android
2. فعّل **USB Debugging**
3. وصّل الجهاز بالكمبيوتر
4. في Terminal:
   ```bash
   flutter devices  # لرؤية الأجهزة المتاحة
   flutter run -d <device_id>
   ```

## نصائح إضافية

### لتجنب المشكلة في المستقبل:

1. **نظف المشروع قبل البناء**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **استخدم Release build** (أصغر حجماً):
   ```bash
   flutter build apk --release
   ```

3. **احذف التطبيقات القديمة** من المحاكي بشكل دوري

## الحل السريع (الأفضل)

1. **افتح المحاكي**
2. **Settings > Apps > patien_app > Storage > Clear Data**
3. **احذف التطبيق** من المحاكي
4. **شغّل مرة أخرى**: `flutter run`

أو ببساطة:
```bash
adb uninstall com.example.patien_app
flutter run
```




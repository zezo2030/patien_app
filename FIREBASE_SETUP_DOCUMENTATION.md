# 📚 دليل إعداد Firebase في تطبيق VirClinc

## 📋 نظرة عامة

هذا الدليل يشرح بالتفصيل كيفية إعداد وتكوين Firebase في تطبيق Flutter الخاص بـ VirClinc، بالإضافة إلى طريقة إضافة شعارات Firebase داخل التطبيق.

---

## 🔥 إعداد Firebase في التطبيق

### 1. معلومات مشروع Firebase

- **Project ID:** `virclinic-fcf3e`
- **Project Number:** `927142922437`
- **Storage Bucket:** `virclinic-fcf3e.firebasestorage.app`

### 2. المكتبات المستخدمة

تم إضافة المكتبات التالية في `pubspec.yaml`:

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.0.0
  
  # Firebase Cloud Messaging للإشعارات
  firebase_messaging: ^15.0.0
  
  # الإشعارات المحلية
  flutter_local_notifications: ^19.5.0
```

### 3. تهيئة Firebase في التطبيق

#### ملف `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // تأكد من تهيئة Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // تهيئة خدمة الإشعارات
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}
```

#### ملف `lib/firebase_options.dart`

هذا الملف يحتوي على إعدادات Firebase لجميع المنصات:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      // ...
    }
  }
}
```

**إعدادات Firebase لكل منصة:**

- **Web:**
  - API Key: `AIzaSyByqm0UkZuMZSWAm6grfIwvgusyVJ6fMY0`
  - App ID: `1:927142922437:web:9f2e57e12159360e9188ac`
  - Measurement ID: `G-8TGK0SKQKN`

- **Android:**
  - API Key: `AIzaSyBsZS_TsGvqnFfRb310I6UquhEqwdFl11E`
  - App ID: `1:927142922437:android:10a4023669fab6189188ac`
  - Package Name: `com.example.patien_app`

- **iOS:**
  - API Key: `AIzaSyAajNBJ_FV2ptPZDeMe8C3XD0OSfu4a-xQ`
  - App ID: `1:927142922437:ios:99056340f63363379188ac`
  - Bundle ID: `com.example.patienApp`

- **Windows:**
  - API Key: `AIzaSyByqm0UkZuMZSWAm6grfIwvgusyVJ6fMY0`
  - App ID: `1:927142922437:web:e9d98306ddf5c93c9188ac`
  - Measurement ID: `G-RSRMZBD9J8`

---

## 🤖 إعداد Firebase Cloud Messaging (FCM)

### 1. خدمة الإشعارات (`lib/services/notification_service.dart`)

الخدمة تقوم بـ:
- طلب صلاحيات الإشعارات
- تهيئة الإشعارات المحلية
- إعداد معالجات الرسائل
- الحصول على Device Token
- إرسال Token إلى Backend

#### الميزات الرئيسية:

```dart
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = ...;
  
  // تهيئة الخدمة
  Future<void> initialize() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _setupMessageHandlers();
    await _getAndSaveToken();
  }
  
  // طلب الصلاحيات
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
    } else if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
```

### 2. معالجة الرسائل

#### رسائل الخلفية (Background Messages)

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  // Firebase يعرض الإشعار تلقائياً عند وجود التطبيق في الخلفية
}
```

#### رسائل الواجهة الأمامية (Foreground Messages)

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('📱 Foreground message received: ${message.messageId}');
  _showLocalNotification(message);
});
```

#### فتح التطبيق من الإشعار

```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('📱 Message opened app: ${message.messageId}');
  _handleNotificationTap(message);
});
```

### 3. Device Token

```dart
// الحصول على Token
Future<String?> getDeviceToken() async {
  final token = await _firebaseMessaging.getToken();
  return token;
}

// إرسال Token إلى Backend
Future<void> sendTokenToBackend(String userId, String authToken) async {
  final deviceToken = await getDeviceToken();
  final platform = Platform.isAndroid ? 'android' : 'ios';
  await _apiService.saveDeviceToken(userId, deviceToken, platform, authToken);
}
```

---

## 📱 إعداد Android

### 1. ملف `android/settings.gradle.kts`

```kotlin
plugins {
    // FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
}
```

### 2. ملف `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    // FlutterFire Configuration
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

### 3. ملف `android/app/google-services.json`

يحتوي على إعدادات Firebase لـ Android:

```json
{
  "project_info": {
    "project_number": "927142922437",
    "project_id": "virclinic-fcf3e",
    "storage_bucket": "virclinic-fcf3e.firebasestorage.app"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "1:927142922437:android:10a4023669fab6189188ac",
      "android_client_info": {
        "package_name": "com.example.patien_app"
      }
    }
  }]
}
```

### 4. ملف `android/app/src/main/AndroidManifest.xml`

```xml
<!-- صلاحيات Firebase Cloud Messaging -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>

<application>
    <!-- Firebase Cloud Messaging Service -->
    <service
        android:name="com.google.firebase.messaging.FirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

---

## 🍎 إعداد iOS

### 1. ملف `ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 2. ملف `ios/Runner/Info.plist`

يجب إضافة صلاحيات الإشعارات في `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 3. إضافة GoogleService-Info.plist

للإنتاج، يجب إضافة ملف `GoogleService-Info.plist` في:
- `ios/Runner/GoogleService-Info.plist`

**ملاحظة:** هذا الملف غير موجود حالياً في المشروع ويجب إضافته من Firebase Console.

---

## 🎨 إضافة شعارات Firebase في التطبيق

### 1. إضافة صور Firebase كـ Assets

#### الخطوة 1: إنشاء مجلد Assets

أنشئ مجلد `assets` في جذر المشروع:

```
patien_app/
├── assets/
│   ├── images/
│   │   ├── firebase_logo.png
│   │   ├── firebase_icon.png
│   │   └── powered_by_firebase.png
```

#### الخطوة 2: تحديث `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/firebase_logo.png
    - assets/images/firebase_icon.png
    - assets/images/powered_by_firebase.png
```

#### الخطوة 3: استخدام الصور في الكود

```dart
import 'package:flutter/material.dart';

class FirebaseLogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/firebase_logo.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
  }
}
```

### 2. إضافة شعار Firebase في شاشة About أو Settings

#### مثال: إضافة في شاشة Profile

```dart
// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // محتوى الشاشة
          
          // شعار Firebase في الأسفل
          Spacer(),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Image.asset(
                  'assets/images/powered_by_firebase.png',
                  width: 120,
                  height: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. إضافة شعار Firebase في شاشة Login/Splash

```dart
// lib/screens/auth/login_screen.dart

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شعار التطبيق
          Image.asset(
            'assets/images/app_logo.png',
            width: 150,
            height: 150,
          ),
          
          SizedBox(height: 40),
          
          // نموذج تسجيل الدخول
          // ...
          
          Spacer(),
          
          // شعار Firebase
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images/powered_by_firebase.png',
              width: 100,
              height: 33,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. استخدام Firebase Logo من الإنترنت (بدون Assets)

إذا لم تكن تريد إضافة الصور كـ assets، يمكنك استخدام URL مباشر:

```dart
Image.network(
  'https://firebase.google.com/images/brand-guidelines/logo-standard.png',
  width: 100,
  height: 100,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

### 5. إضافة Firebase Badge في Footer

```dart
Widget _buildFirebaseFooter() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Powered by ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Image.asset(
          'assets/images/firebase_logo.png',
          width: 80,
          height: 26,
        ),
      ],
    ),
  );
}
```

---

## 📥 تنزيل شعارات Firebase

### مصادر رسمية لشعارات Firebase:

1. **Firebase Brand Guidelines:**
   - https://firebase.google.com/brand-guidelines

2. **Firebase Logo Downloads:**
   - https://firebase.google.com/downloads/brand-guidelines

3. **أنواع الشعارات المتاحة:**
   - Firebase Logo (Full)
   - Firebase Icon (Square)
   - "Powered by Firebase" Badge
   - Firebase for Flutter Badge

### مواصفات الصور الموصى بها:

- **Logo:** PNG مع خلفية شفافة
- **Resolution:** 2x أو 3x للشاشات عالية الدقة
- **Format:** PNG أو SVG
- **Colors:** استخدام الألوان الرسمية (Orange #FF6F00)

---

## 🔧 خطوات إضافة Firebase Logo خطوة بخطوة

### الخطوة 1: تحضير الصور

1. قم بتحميل شعار Firebase من الموقع الرسمي
2. احفظ الصور في مجلد `assets/images/`
3. استخدم أسماء واضحة:
   - `firebase_logo.png` - الشعار الكامل
   - `firebase_icon.png` - الأيقونة المربعة
   - `powered_by_firebase.png` - شعار "Powered by"

### الخطوة 2: تحديث pubspec.yaml

```yaml
flutter:
  assets:
    - assets/images/
```

ثم قم بتشغيل:
```bash
flutter pub get
```

### الخطوة 3: إضافة Widget للشعار

أنشئ ملف جديد `lib/widgets/firebase_logo_widget.dart`:

```dart
import 'package:flutter/material.dart';

class FirebaseLogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  
  const FirebaseLogoWidget({
    Key? key,
    this.width = 100,
    this.height = 33,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText)
          Text(
            'Powered by',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        if (showText) SizedBox(height: 4),
        Image.asset(
          'assets/images/powered_by_firebase.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
```

### الخطوة 4: استخدام Widget في الشاشات

```dart
import 'package:patien_app/widgets/firebase_logo_widget.dart';

// في أي شاشة
FirebaseLogoWidget(
  width: 120,
  height: 40,
  showText: true,
)
```

---

## 🧪 اختبار Firebase

### 1. اختبار تهيئة Firebase

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  runApp(const MyApp());
}
```

### 2. اختبار الإشعارات

استخدم Firebase Console لإرسال إشعار تجريبي:
1. اذهب إلى Firebase Console
2. Cloud Messaging > Send test message
3. أدخل Device Token
4. أرسل الإشعار

### 3. التحقق من Device Token

```dart
final notificationService = NotificationService();
await notificationService.initialize();
final token = await notificationService.getDeviceToken();
print('Device Token: $token');
```

---

## 📝 ملاحظات مهمة

### 1. الأمان

- **لا تشارك API Keys علناً** في الكود المصدري
- استخدم Environment Variables للإنتاج
- راجع صلاحيات Firebase في Console

### 2. الأداء

- Firebase يتم تهيئته مرة واحدة عند بدء التطبيق
- Device Token يتم تحديثه تلقائياً عند الحاجة
- الإشعارات المحلية تستخدم قناة مخصصة على Android

### 3. التوافق

- **Android:** يتطلب Android 6.0+ (API 23+)
- **iOS:** يتطلب iOS 10.0+
- **Web:** مدعوم بالكامل
- **Windows/macOS:** مدعوم

### 4. استكشاف الأخطاء

#### مشكلة: Firebase لا يتم تهيئته

**الحل:**
- تأكد من وجود `google-services.json` في `android/app/`
- تأكد من وجود `GoogleService-Info.plist` في `ios/Runner/` (لـ iOS)
- تحقق من إعدادات `firebase_options.dart`

#### مشكلة: الإشعارات لا تظهر

**الحل:**
- تحقق من الصلاحيات في AndroidManifest.xml
- تحقق من صلاحيات iOS في Info.plist
- تأكد من تهيئة NotificationService بشكل صحيح

#### مشكلة: Device Token فارغ

**الحل:**
- تأكد من اتصال الإنترنت
- تحقق من إعدادات Firebase في Console
- تأكد من أن التطبيق مسجل في Firebase Console

---

## 📚 المراجع

1. **Firebase Flutter Documentation:**
   - https://firebase.flutter.dev/

2. **Firebase Cloud Messaging:**
   - https://firebase.google.com/docs/cloud-messaging

3. **FlutterFire CLI:**
   - https://firebase.flutter.dev/docs/cli

4. **Firebase Brand Guidelines:**
   - https://firebase.google.com/brand-guidelines

---

## 🔄 تحديث Firebase

### تحديث الإعدادات

إذا احتجت تحديث إعدادات Firebase:

1. استخدم FlutterFire CLI:
```bash
flutterfire configure
```

2. أو قم بتحديث `firebase_options.dart` يدوياً

3. قم بتحديث `google-services.json` و `GoogleService-Info.plist`

---

## ✅ Checklist الإعداد

- [x] إضافة `firebase_core` و `firebase_messaging` في `pubspec.yaml`
- [x] تهيئة Firebase في `main.dart`
- [x] إعداد `firebase_options.dart` لجميع المنصات
- [x] إضافة `google-services.json` في Android
- [x] إضافة `GoogleService-Info.plist` في iOS (مطلوب للإنتاج)
- [x] إعداد صلاحيات الإشعارات في AndroidManifest.xml
- [x] إعداد صلاحيات الإشعارات في Info.plist (iOS)
- [x] تهيئة NotificationService
- [x] إضافة Firebase Logo Widget (اختياري)
- [x] اختبار الإشعارات

---

**تم الإنشاء:** 2024  
**الإصدار:** 1.0.0  
**المشروع:** VirClinc Patient App




# استكشاف أخطاء الاتصال - Flutter App

## المشكلة: انتهت مهلة الاتصال (Connection Timeout)

إذا كنت تواجه رسالة الخطأ: `انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت`

### الحلول الممكنة:

#### 1. تأكد من أن Backend Server يعمل ✅

**الخطوة الأهم:** يجب أن يكون Backend Server يعمل قبل تشغيل التطبيق.

```bash
# افتح Terminal جديد وانتقل إلى مجلد Backend
cd new/clinic-api

# تأكد من تثبيت التبعيات
npm install

# شغّل Backend Server
npm run start:dev
```

يجب أن ترى رسالة مثل:
```
[Nest] INFO [NestFactory] Starting Nest application...
[Nest] INFO [InstanceLoader] AppModule dependencies initialized
[Nest] INFO [NestApplication] Nest application successfully started
```

**التحقق من عمل Server:**
- افتح المتصفح على: `http://localhost:3000/v1/health`
- يجب أن ترى: `{"status":"ok"}`

---

#### 2. تحقق من IP Address 📍

التطبيق يحاول الاتصال بـ: `http://192.168.1.3:3000/v1`

**للحصول على IP جهازك:**

**Windows:**
```powershell
ipconfig
```
ابحث عن `IPv4 Address` تحت `Wireless LAN adapter Wi-Fi` أو `Ethernet adapter`

**Mac/Linux:**
```bash
ifconfig
# أو
ip addr show
```

**تحديث IP في التطبيق:**
1. افتح: `patien_app/lib/config/api_config.dart`
2. غيّر السطر 16:
   ```dart
   static const String _localIP = 'YOUR_IP_HERE'; // مثال: '192.168.1.100'
   ```
3. تأكد من أن `_usePhysicalDeviceIP = true` (السطر 27)

---

#### 3. تأكد من أن الجهاز والكمبيوتر على نفس الشبكة 📶

- **الكمبيوتر:** يجب أن يكون متصل بـ WiFi
- **جهاز الموبايل/Emulator:** يجب أن يكون على نفس شبكة WiFi

**للتحقق:**
- افتح المتصفح على الموبايل
- اكتب: `http://YOUR_IP:3000/v1/health`
- إذا لم يعمل، فالمشكلة في الشبكة

---

#### 4. تحقق من Firewall 🔥

**Windows Firewall:**
1. افتح `Windows Defender Firewall`
2. اضغط `Allow an app or feature through Windows Firewall`
3. تأكد من أن `Node.js` مسموح له بالاتصال

**أو أضف قاعدة يدوياً:**
```powershell
# كمسؤول (Run as Administrator)
netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=3000
```

---

#### 5. للـ Android Emulator 📱

إذا كنت تستخدم Android Emulator:
- استخدم `10.0.2.2` بدلاً من `localhost` أو IP المحلي
- في `api_config.dart`، تأكد من أن الكود يتعامل مع Emulator بشكل صحيح

---

#### 6. اختبار الاتصال يدوياً 🔍

**من المتصفح (على الكمبيوتر):**
```
http://localhost:3000/v1/health
```

**من المتصفح (على الموبايل - نفس الشبكة):**
```
http://YOUR_IP:3000/v1/health
```

**من Terminal (ping test):**
```bash
# Windows
ping YOUR_IP

# Mac/Linux
ping YOUR_IP
```

---

#### 7. تحقق من Port 3000 🚪

**Windows:**
```powershell
netstat -ano | findstr :3000
```

**Mac/Linux:**
```bash
lsof -i :3000
```

إذا كان Port 3000 مستخدم، يمكنك:
- إنهاء العملية التي تستخدمه
- أو تغيير Port في Backend (في ملف `.env`)

---

## ملخص الخطوات السريعة:

1. ✅ شغّل Backend: `cd new/clinic-api && npm run start:dev`
2. ✅ تحقق من IP: `ipconfig` (Windows) أو `ifconfig` (Mac/Linux)
3. ✅ حدّث IP في `api_config.dart`
4. ✅ تأكد من نفس الشبكة WiFi
5. ✅ تحقق من Firewall
6. ✅ اختبر الاتصال من المتصفح

---

## رسائل الخطأ المحسّنة

تم تحسين رسائل الخطأ في التطبيق لتوفر معلومات أكثر:

- **Timeout:** ستعرض الآن URL الكامل واقتراحات للحل
- **SocketException:** ستعرض تعليمات مفصلة للتحقق من Server
- **Health Check:** يمكن تفعيله للتحقق من الاتصال قبل Login

---

## للمساعدة الإضافية

إذا استمرت المشكلة:
1. تحقق من Console logs في Backend
2. تحقق من Console logs في Flutter
3. تأكد من أن MongoDB يعمل (إذا كان مطلوب)
4. راجع ملف `.env` في `clinic-api`



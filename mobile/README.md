# حقّنا — تطبيق Android (Flutter)

تطبيق native لجمعية حقّنا، يعمل offline ويتزامن مع السيرفر عبر شبكة LAN خاصة.

## ⚡ ملخص سريع

| الميزة | الحالة |
|--------|--------|
| تسجيل الدخول مع Token | ✅ |
| تخزين محلي SQLite | ✅ |
| إنشاء/تعديل ناجٍ offline | ✅ |
| بحث في القائمة | ✅ |
| مزامنة تلقائية عند توفر الاتصال | ✅ |
| مزامنة يدوية بزر | ✅ |
| RTL + Arabic UI | ✅ |
| تحميل البيانات المرجعية | ✅ |
| رفع صور وفيديوهات | 🚧 (مرحلة لاحقة) |
| المسح الاجتماعي | 🚧 |
| الشهود والوثائق | 🚧 |
| المقابلات والوسائط | 🚧 |
| الإحالة لجهات خارجية | 🚧 |

التطبيق في **المرحلة الأولى** الجاهزة للاستخدام الميداني: إنشاء ملفات الناجين
الأساسية offline ومزامنتها. التوسعات لاحقة تتبع نفس النمط المعماري.

## 📋 المتطلبات

- Flutter SDK 3.10+
- Android SDK (API 24+ / Android 7+)
- جهاز Android أو محاكي
- اللابتوب يشغّل Django backend على نفس الـWiFi

## 🚀 الإعداد

### 1. تثبيت Flutter

```bash
# على Linux/Mac
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### 2. تثبيت dependencies التطبيق

```bash
cd mobile/
flutter pub get
```

### 3. تشغيل اللابتوب backend

```bash
# في طرفية اللابتوب (داخل مجلد hq_protocol)
./run.sh
# سيُشغّل على http://0.0.0.0:8000/
```

اكتشف عنوان IP اللابتوب على الشبكة:
```bash
# Linux
ip addr show | grep "inet " | grep -v 127.0.0.1
# مثال الناتج: inet 192.168.1.42/24

# Windows: ipconfig
# Mac: ifconfig
```

### 4. تشغيل التطبيق

```bash
# على جهاز Android متصل أو محاكي
flutter run

# أو لبناء APK:
flutter build apk --release
# APK في: build/app/outputs/flutter-apk/app-release.apk
```

### 5. الاستخدام الأول

1. افتح التطبيق
2. أدخل عنوان السيرفر: `http://192.168.1.42:8000` (استبدل بـIP لابتوبك)
3. سجّل دخول بحساب موثّق على السيرفر (مثلاً admin/haqquna2026)
4. التطبيق يُحمّل البيانات المرجعية تلقائياً
5. ابدأ بإنشاء ناجٍ - يُحفَظ فوراً محلياً

## 🏗️ المعمارية

```
lib/
├── main.dart                  ← نقطة الدخول
├── theme.dart                 ← ألوان حقّنا
├── config/
│   └── api_config.dart        ← عنوان السيرفر (يُخزَّن SharedPreferences)
├── models/
│   ├── user.dart
│   ├── survivor.dart          ← Survivor + DB serialization
│   └── choices.dart           ← قوائم مرجعية
├── services/
│   ├── api_client.dart        ← HTTP wrapper مع Token auth
│   ├── auth_service.dart      ← Login + secure storage
│   ├── database_service.dart  ← SQLite (sqflite)
│   ├── survivor_service.dart  ← CRUD محلي
│   └── sync_service.dart      ← Push/Pull + connectivity listener
└── screens/
    ├── splash_screen.dart
    ├── server_config_screen.dart
    ├── login_screen.dart
    ├── home_screen.dart       ← الداشبورد + إحصاءات + زر مزامنة
    ├── survivor_list_screen.dart
    └── survivor_form_screen.dart
```

### استراتيجية offline-first

1. **كل كتابة** تذهب إلى SQLite أولاً مع `needs_sync=1`
2. **كل قراءة** من SQLite (سريع، يعمل offline)
3. **المزامنة** تتم:
   - تلقائياً عند تغيّر حالة الاتصال (connectivity_plus listener)
   - يدوياً عند الضغط على زر المزامنة
   - بعد كل عملية حفظ (محاولة فورية)
4. **Push**: يرسل الناجين بـ`needs_sync=1` إلى `/api/v1/sync/push/`
5. **Pull**: يجلب التغييرات منذ آخر `updated_at` محلي

## 🔧 الـAPI Endpoints المُستخدَمة

| المسار | الطريقة | الوصف |
|--------|---------|-------|
| `/api/v1/auth/login/` | POST | تسجيل دخول → token |
| `/api/v1/auth/profile/` | GET | بيانات المستخدم الحالي |
| `/api/v1/auth/logout/` | POST | إلغاء الـtoken |
| `/api/v1/reference/` | GET | البيانات المرجعية كاملة |
| `/api/v1/survivors/` | GET | قائمة ناجين (مع بحث وفلترة) |
| `/api/v1/survivors/{id}/` | GET | تفاصيل ناجٍ |
| `/api/v1/survivors/create/` | POST | إنشاء ناجٍ |
| `/api/v1/survivors/{id}/update/` | PATCH | تعديل ناجٍ |
| `/api/v1/sync/push/` | POST | دفع مجمّع للناجين |
| `/api/v1/sync/pull/?since=...` | GET | سحب التغييرات |

كل النقاط (ما عدا login) تتطلب header:
```
Authorization: Token <key>
```

## 🔐 الأمان

- **Token** يُخزَّن في `flutter_secure_storage` (Android Keystore)
- **SQLite** غير مشفّر افتراضياً - استخدم `sqflite_sqlcipher` للتشفير لاحقاً
- **HTTP cleartext** مسموح فقط لشبكات LAN (192.168.x، 10.x، 172.16-31.x)
- **device_id** فريد لكل جهاز يُسجَّل في `mobile_api.AuthToken`
- كل دخول يُسجَّل في `accounts.AuditLog` كـ`LOGIN` أو `FAILED_LOGIN`

## 🛠️ التوسعات المقترحة

### مرحلة 2 (المسح الاجتماعي):
- إضافة جدول `households` و `children` لـSQLite
- شاشات MaterialApp جديدة
- توسيع `/api/v1/` لتشمل HouseholdSurvey

### مرحلة 3 (الوسائط):
- التقاط صور/فيديوهات بـ`image_picker` و`camera`
- تخزينها في `getApplicationDocumentsDirectory()`
- رفعها مع المزامنة كـMultipart

### مرحلة 4 (الميزات المتقدمة):
- توقيع الموافقة المستنيرة بإصبع المستخدم (`signature` package)
- مسح QR لربط جهاز ناجٍ سابق
- خرائط offline للمحافظات

## 🐛 استكشاف الأخطاء

**"Connection refused"**: تحقق من:
- اللابتوب على نفس الـWiFi
- Django يستمع على `0.0.0.0` (ليس فقط `127.0.0.1`)
- جدار الحماية يسمح بالمنفذ 8000

**"Invalid token"**: 
- سجّل خروج وادخل من جديد
- أو من Django admin: امسح Tokens القديمة

**المزامنة لا تشتغل**:
- افحص الـconsole logs (`adb logcat`)
- جرّب الضغط على زر المزامنة يدوياً

## 📦 بناء APK للتوزيع

```bash
flutter build apk --release --split-per-abi
# 3 APKs منفصلة لمعمارية CPU
# توزّعها على المتطوّعين عبر USB أو خادم محلي
```

## 🎨 تخصيص

- الألوان: `lib/theme.dart`
- اسم التطبيق: `android/app/src/main/AndroidManifest.xml` (android:label)
- الأيقونة: استبدل `android/app/src/main/res/mipmap-*/ic_launcher.png`

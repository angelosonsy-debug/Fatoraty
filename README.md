# فاتورتي (Fatorty)

تطبيق تذكير بمواعيد سداد الفواتير — للسوق المصري. Offline-first بالكامل،
بدون Backend أو تسجيل حساب.

- **Package name:** `com.angelosonsy.fatorty`
- **Stack:** Flutter + Provider + shared_preferences (JSON) +
  flutter_local_notifications

## تشغيل المشروع محلياً

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

**ملاحظة مهمة:** `android/gradlew`, `android/gradlew.bat`,
و`android/gradle/wrapper/gradle-wrapper.jar` **مش موجودين فعلياً في
المستودع** (الـ jar ملف binary مينفعش يتكتب كنص، فمحتاج Gradle حقيقي
يولّده). الـ CI (`.github/workflows/build.yml`) بيولّدهم تلقائياً في كل
تشغيل. لو هتبني محلياً لأول مرة وظهر خطأ شبيه بـ "Gradle version too
old"، شغّل الأمر ده مرة واحدة جوه `android/` قبل أي حاجة تانية:
```bash
cd android
gradle wrapper --gradle-version 8.14 --distribution-type bin
cd ..
```
(لو مفيش `gradle` عندك أصلاً، نزّل نسخة من https://gradle.org/releases/
أو استخدم Android Studio اللي بيجيب Gradle جاهز).

## بناء تلقائي على GitHub

عند أي push لفرع `main` أو فتح Pull Request، يقوم
`.github/workflows/build.yml` تلقائياً بـ:
`flutter pub get` → `flutter analyze` → `flutter test` →
`flutter build apk --debug` → رفع الـ APK كـ Artifact يمكن تحميله من تبويب
Actions في المستودع.

## محتاج تدخل يدوي قبل النشر على Google Play

- [ ] **AdMob**: إنشاء حساب AdMob لهذا التطبيق تحديداً، واستبدال
      `ca-app-pub-3940256099942544~3347511713` (Test App ID) في
      `AndroidManifest.xml` وأي Ad Unit IDs placeholder في الكود بالقيم
      الحقيقية.
- [ ] **الأيقونة**: الأيقونة الحالية (مربع أزرق بسيط) placeholder مؤقت بس
      عشان البناء يعدي — استبدل `assets/icon/icon.png` و
      `icon_foreground.png` بأيقونة تصميم نهائية (1024×1024)، ثم شغّل:
      `flutter pub run flutter_launcher_icons`
      (هيستبدل تلقائياً كل ملفات `android/app/src/main/res/mipmap-*/ic_launcher.png`
      اللي حالياً مؤقتة)
- [ ] **سعر الاشتراك**: تحديد السعر النهائي (بين 15-29 جنيه) وربط
      Google Play Billing الفعلي بدل الـ placeholders في `PremiumProvider`
      وشاشة الإعدادات/الـ PremiumModal.
- [ ] **توقيع الإصدار (Release Signing)**: إنشاء keystore حقيقي، وإضافة
      `android/key.properties` (غير مرفوع على Git)، وتحديث
      `android/app/build.gradle` ليستخدم `signingConfigs.release` بدل
      `signingConfigs.debug` المؤقت المستخدم حالياً فقط عشان CI يقدر يبني.
- [ ] **Firebase Crashlytics**: تفعيل `flutterfire configure` + حزمة
      `firebase_crashlytics` (TODO موجود في `lib/main.dart`).
- [ ] **رفع على Google Play Console** لتفعيل الاشتراكات الفعلية (Billing
      لا يعمل بدون نشر أولي، ولو كـ Internal Testing).
- [ ] مراجعة **Privacy Policy** و**Data Safety** على Play Console قبل
      النشر العلني.

## ملاحظات تقنية

- منطق حساب تاريخ التذكير (الأهم تقنياً) موجود في
  `lib/utils/reminder_calculator.dart`، مع اختبارات وحدة شاملة في
  `test/reminder_calculator_test.dart` تغطي حدود الشهر (مثل يوم سداد = 1
  مع تذكير أسبوعين، وأشهر فبراير القصيرة).
- جدولة الإشعارات الشهرية تعتمد حالياً على جدولة أقرب تذكير قادم فقط ثم
  إعادة الجدولة عند فتح التطبيق (`BillProvider.load` → `_resyncNotifications`)
  — TODO موضح في `lib/services/notification_service.dart` لتحسين هذا لاحقاً
  عبر WorkManager لضمان إعادة الجدولة حتى لو التطبيق مُغلق لفترة طويلة.

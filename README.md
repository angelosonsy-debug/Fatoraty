# فاتورتي (Fatorty)

تطبيق تذكير بمواعيد سداد الفواتير — للسوق المصري. Offline-first بالكامل،
بدون Backend أو تسجيل حساب.

- **Package name:** `com.angelosonsy.fatorty`
- **Stack:** Flutter + Provider + shared_preferences (JSON) +
  flutter_local_notifications

## آخر الإضافات
- **طرق الدفع** — زرار "طرق الدفع" في تفاصيل أي فاتورة، بيفتح قائمة
  بأهم وسائل السداد في مصر (فوري برابط موقعهم الرسمي، تطبيق myFawry،
  محافظ موبايل، تطبيقات بنوك، مكتب البريد). `lib/widgets/payment_methods_sheet.dart`.
  ملاحظة: معلومات إرشادية بس لمحافظ الموبايل/البنوك (مش روابط مباشرة)
  لأني معنديش طريقة أتأكد من صحة deep links لتطبيقاتهم من غير اختبار حقيقي.
- **تأجيل التذكير من الإشعار نفسه** — زرار "ذكرني غداً" داخل الإشعار،
  بيأجّل التذكير 24 ساعة من غير ما يفتح التطبيق. شغّال حتى لو التطبيق
  مقفول بالكامل (background isolate منفصل) — `notificationBackgroundHandler`
  في `lib/services/notification_service.dart`.
- **Widget الشاشة الرئيسية بقى بيعرض لحد 3 فواتير** بدل فاتورة واحدة بس.
- **اختصار "أضف فاتورة"** بالضغط المطوّل على أيقونة التطبيق (`quick_actions`).
- **تذكيرات متعددة لكل فاتورة** — تقدر تختار أكتر من مدة تذكير مع بعض
  (مثلاً أسبوع قبل + يوم قبل). `Bill.reminderLeads` (قائمة) بدل
  `reminderLead` (قيمة واحدة)، مع توافق رجعي كامل للبيانات القديمة.
- **"تم السداد" + سجل مدفوعات حقيقي** — زرار في تفاصيل أي فاتورة يسجّل
  دفعة فعلية (بتاريخ ومبلغ قابلين للتعديل، مش بالضرورة نفس المبلغ
  التقديري). شاشة جديدة "سجل المصروفات" (من الإعدادات) بتجمّع كل
  المدفوعات بالشهر مع الإجمالي. ملفات: `lib/models/payment_record.dart`،
  `lib/screens/payment_history_screen.dart`. **ملاحظة مهمة:** تسجيل
  الدفع مجرد سجل تاريخي — مبيأثرش على حساب دورة الاستحقاق القادمة
  (بتتحسب دايماً من anchorDate + الدورة بغض النظر عن حالة الدفع).
  النسخة الاحتياطية (Backup/Restore) بقت بتشمل سجل المدفوعات كمان.
- دورات سداد مرنة (أسبوعي/شهري/ربع سنوي/نصف سنوي/سنوي/مخصص) — مش بس شهري
- Rating Prompt تلقائي بعد 3-5 استخدامات (`BillProvider._maybePromptForRating`)
- نسخة احتياطية + استرجاع (JSON) — `lib/services/backup_service.dart`
- تصدير بيانات CSV لمشتركي Pro — نفس الملف
- Home Screen Widget — بيعرض أقرب فاتورة مستحقة على الشاشة الرئيسية
  للموبايل مباشرة. الملفات: `lib/services/widget_service.dart` (Dart)،
  `android/app/src/main/kotlin/.../FatortyWidgetProvider.kt` (Kotlin)،
  layout/xml مرفقين تحت `android/app/src/main/res/`. البيانات بتتحدّث
  أوتوماتيك مع أي تغيير في الفواتير. **ملاحظة: ده كود Android أصلي
  (Kotlin) معنديش بيئة لبنائه واختباره فعلياً هنا — المتوقع إنه يحتاج
  جولة تصحيح أو اتنين زي باقي أجزاء المشروع لحد ما يعدّي أول build.**
- حاسبة شرائح الكهرباء — `lib/utils/electricity_tariff.dart` +
  `lib/widgets/electricity_calculator_sheet.dart`. متاحة من شاشة تفاصيل
  أي فاتورة كهرباء، وكمان من خطوة 3 في معالج الإضافة. البيانات مبنية على
  شرائح الاستهلاك المنزلي الرسمية (آخر تحديث: أغسطس 2026، جهاز تنظيم
  مرفق الكهرباء). **لازم تحديث القيم في `ElectricityTariff.tiers` و
  `lastUpdatedLabel` لما الحكومة تغيّر التسعيرة لاحقاً** — القيم مش
  بتتحدّث تلقائياً من أي مصدر خارجي.

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
- [ ] **الأيقونة**: الأيقونة الحالية (فاتورة + جرس تذكير، مرسومة
      برمجياً) placeholder محسّن لكنه لسه مؤقت — استبدل
      `assets/icon/icon.png` و `icon_foreground.png` بأيقونة تصميم نهائية
      من مصمم حقيقي (1024×1024)، ثم شغّل:
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

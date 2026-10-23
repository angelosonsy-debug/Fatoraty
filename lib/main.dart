import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';

import 'providers/bill_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/bill_details_screen.dart';
import 'screens/wizard/add_bill_wizard_screen.dart';
import 'theme/app_theme.dart';

// TODO: فعّل Firebase Crashlytics قبل أول نشر على Play Store.
// الخطوات: flutterfire configure + إضافة firebase_crashlytics +
// تغليف runApp بـ runZonedGuarded وربط FlutterError.onError.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();

  // مهم جداً: لازم runApp() تتنفذ مهما حصل. لو تهيئة الإشعارات علّقت أو
  // رمت استثناء (زي اللي حصل فعلياً)، كان التطبيق مش بيوصل لـ runApp()
  // خالص — يعني Flutter مش بيرسم ولا فريم واحد، وشاشة splash الخاصة
  // بأندرويد (الأيقونة في النص) بتفضل واقفة للأبد. التذكيرات مهمة لكنها
  // مش أهم من إن التطبيق يفتح أصلاً.
  String? launchBillId;
  try {
    await NotificationService.instance.init().timeout(
          const Duration(seconds: 5),
        );
    launchBillId = await NotificationService.instance
        .getLaunchBillId()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // فشل تهيئة الإشعارات (أو استغرقت وقت طويل) — نكمل فتح التطبيق
    // عادي من غيرها. التذكيرات المجدولة قبل كده هتفضل شغالة برضه
    // (مستقلة عن تهيئة الـ plugin نفسها)، وأي محاولة جدولة جديدة
    // هتتعامل مع الفشل بنفس الأسلوب (راجع try/catch جوه BillProvider).
  }

  // TODO: فعّل Mobile Ads SDK الحقيقي هنا بعد توفر AdMob App ID:
  // await MobileAds.instance.initialize();

  runApp(FatortyApp(storage: storage, initialBillId: launchBillId));
}

class FatortyApp extends StatelessWidget {
  final StorageService storage;
  final String? initialBillId;
  const FatortyApp({super.key, required this.storage, this.initialBillId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)..load()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage)..load(),
        ),
        ChangeNotifierProvider(create: (_) => PremiumProvider(storage)..load()),
        ChangeNotifierProxyProvider<SettingsProvider, BillProvider>(
          create: (ctx) =>
              BillProvider(storage, ctx.read<SettingsProvider>())..load(),
          update: (ctx, settings, previous) =>
              previous ?? BillProvider(storage, settings),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'فاتورتي',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            locale: const Locale('ar', 'EG'),
            supportedLocales: const [Locale('ar', 'EG')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
            home: RootGate(initialBillId: initialBillId),
            onGenerateRoute: (settings) {
              if (settings.name == '/bill-details') {
                final billId = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => BillDetailsScreen(billId: billId ?? ''),
                );
              }
              if (settings.name == '/archive') {
                return MaterialPageRoute(
                  builder: (_) => const ArchiveScreen(),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// يقرر هل يعرض Onboarding أول مرة أم يروح على الـ Dashboard مباشرة
class RootGate extends StatefulWidget {
  final String? initialBillId;
  const RootGate({super.key, this.initialBillId});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final _storage = StorageService();
  bool? _onboardingDone;

  static const _quickActions = QuickActions();
  static const _addBillActionType = 'add_bill';

  @override
  void initState() {
    super.initState();
    _check();
    _initQuickActions();

    // شبكة أمان: لو _check() علّقت لأي سبب (استثناء من SharedPreferences
    // مثلاً، أو أي مشكلة platform channel)، الشاشة كانت بتفضل عالقة على
    // دائرة تحميل للأبد — زي بالظبط اللي كان بيحصل. بعد 3 ثواني، لو
    // النتيجة لسه ما وصلتش، بنكمل بافتراض آمن (onboarding لسه ما خلصش)
    // بدل ما نسيب المستخدم عالق على شاشة سودا.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _onboardingDone == null) {
        setState(() => _onboardingDone = false);
      }
    });
  }

  Future<void> _check() async {
    try {
      final done = await _storage.isOnboardingDone();
      if (mounted) setState(() => _onboardingDone = done);
    } catch (_) {
      // لو حصل أي استثناء هنا (بالذات SharedPreferences)، متسيبش الشاشة
      // عالقة للأبد — افتراض آمن: اعرض الـ Onboarding.
      if (mounted) setState(() => _onboardingDone = false);
    }
  }

  /// اختصار "أضف فاتورة" بالضغط المطوّل على أيقونة التطبيق. initialize()
  /// بتتكفّل بالحالتين مع بعض: التطبيق مقفول بالكامل واتفتح بالاختصار،
  /// أو التطبيق شغّال والمستخدم استخدم الاختصار من جديد — مفيش داعي
  /// لفحص منفصل زي حالة الإشعارات (getLaunchBillId).
  ///
  /// الكل جوه try/catch: initState() لازم تفضل متزامنة وما تطلّعش أي
  /// استثناء — استثناء هنا كان ممكن يمنع باقي initState() (بما فيها
  /// _check() اللي فوق) من الاكتمال صح لو انرمى في اللحظة الغلط.
  void _initQuickActions() {
    try {
      _quickActions.initialize((type) {
        if (type == _addBillActionType) {
          // ننتظر لحد ما الـ Navigator يبقى جاهز تماماً
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const AddBillWizardScreen()),
            );
          });
        }
      });
      _quickActions.setShortcutItems(const <ShortcutItem>[
        ShortcutItem(
          type: _addBillActionType,
          localizedTitle: 'أضف فاتورة',
          icon: 'ic_shortcut_add_bill',
        ),
      ]);
    } catch (_) {
      // لو quick_actions مش متاحة أو فشلت لأي سبب، متأثرش على باقي
      // التطبيق — الاختصار مجرد تحسين، مش أساسي لفتح التطبيق.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone!) return const OnboardingScreen();
    return DashboardScreen(initialBillId: widget.initialBillId);
  }
}

/// نقطة دخول مُسمّاة لإعادة الاستخدام من شاشة الإعدادات (زر رابط الأرشيف إلخ)
class AppRoutes {
  static const dashboard = '/';
  static const settings = '/settings';
  static const archive = '/archive';
  static const billDetails = '/bill-details';
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

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
import 'theme/app_theme.dart';

// TODO: فعّل Firebase Crashlytics قبل أول نشر على Play Store.
// الخطوات: flutterfire configure + إضافة firebase_crashlytics +
// تغليف runApp بـ runZonedGuarded وربط FlutterError.onError.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await NotificationService.instance.init();
  // لو التطبيق اتفتح من الصفر بسبب ضغط على إشعار (مش مجرد foreground tap)
  final launchBillId = await NotificationService.instance.getLaunchBillId();

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

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await _storage.isOnboardingDone();
    if (mounted) setState(() => _onboardingDone = done);
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

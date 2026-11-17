import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح تطبيق مثبّت فعلياً على الجهاز بالـ package name بتاعه، ولو مش
/// متثبّت، نوديه لصفحته على Google Play عشان يحمّله. بنستخدم قناة
/// Platform Channel صغيرة (شوف MainActivity.kt) بدل باكدج خارجي جديد،
/// لأن كل اللي محتاجينه هو PackageManager.getLaunchIntentForPackage —
/// حاجة بسيطة مش محتاجة اعتماد كامل.
class AppLauncher {
  AppLauncher._();

  static const MethodChannel _channel =
      MethodChannel('com.angelosonsy.fatorty/app_launcher');

  /// بيحاول يفتح التطبيق المثبّت مباشرة. لو مش متثبّت (أو حصل أي خطأ في
  /// القناة نفسها — مثلاً على منصة غير أندرويد)، بيفتح صفحة التطبيق على
  /// Google Play بدل كده (اللي بدورها بتفتح تطبيق Play Store نفسه لو
  /// متثبّت، أو المتصفح لو لأ).
  ///
  /// بيرجّع true لو التطبيق اتفتح فعلياً (مش صفحة المتجر).
  static Future<bool> openOrGoToStore(String packageName) async {
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openApp',
        {'package': packageName},
      );
      if (opened == true) return true;
    } catch (_) {
      // قناة مش متاحة (منصة تانية غير أندرويد) أو خطأ غير متوقع —
      // نكمل على فتح صفحة المتجر بدل ما نوقف المستخدم تمامًا.
    }
    await _openPlayStore(packageName);
    return false;
  }

  static Future<void> _openPlayStore(String packageName) async {
    final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

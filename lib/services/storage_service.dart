import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';

/// تخزين محلي بصيغة JSON عبر shared_preferences — بنفس أسلوب Mahfazty.
/// حجم البيانات المتوقع صغير (فواتير قليلة لكل مستخدم) فهذا كافٍ ومتسق.
class StorageService {
  static const _billsKey = 'fatorty_bills_v1';
  static const _onboardingDoneKey = 'fatorty_onboarding_done_v1';
  static const _notificationsEnabledKey = 'fatorty_notifications_enabled_v1';
  static const _notificationHourKey = 'fatorty_notification_hour_v1';
  static const _notificationMinuteKey = 'fatorty_notification_minute_v1';
  static const _usageCountKey = 'fatorty_usage_count_v1';
  static const _isPremiumKey = 'fatorty_is_premium_v1'; // TODO: يُحدّث من Billing
  static const _bonusSlotExpiryKey = 'fatorty_bonus_slot_expiry_v1';
  static const _themeModeKey = 'fatorty_theme_mode_v1';

  Future<String> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<List<Bill>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_billsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      // كل فاتورة بتتقرا بمفردها: لو فاتورة واحدة بس فيها مشكلة (بيانات
      // قديمة/تالفة)، منفقدش كل الفواتير التانية معاها — بنتجاهل العنصر
      // التالف بس ونكمل.
      final bills = <Bill>[];
      for (final e in list) {
        try {
          bills.add(Bill.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          // تجاهل عنصر تالف واحد، كمّل البقية
        }
      }
      return bills;
    } catch (_) {
      // بيانات تالفة بالكامل (JSON مش صالح مثلاً) — رجّع قائمة فاضية
      // بدل ما نرمي exception تمنع باقي التطبيق من الفتح خالص.
      return [];
    }
  }

  Future<void> saveBills(List<Bill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(bills.map((b) => b.toJson()).toList());
    await prefs.setString(_billsKey, raw);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<({int hour, int minute})> notificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_notificationHourKey) ?? 9;
    final minute = prefs.getInt(_notificationMinuteKey) ?? 0;
    return (hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationHourKey, hour);
    await prefs.setInt(_notificationMinuteKey, minute);
  }

  Future<int> usageCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usageCountKey) ?? 0;
  }

  Future<void> incrementUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_usageCountKey) ?? 0;
    await prefs.setInt(_usageCountKey, current + 1);
  }

  // TODO: استبدل هذا بمصدر حقيقي للحالة من Google Play Billing (purchase stream)
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, value);
  }

  /// سلوت الفاتورة الخامسة المؤقت (Rewarded Ad) — تاريخ انتهاء الصلاحية
  Future<DateTime?> bonusSlotExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bonusSlotExpiryKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setBonusSlotExpiry(DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bonusSlotExpiryKey, expiry.toIso8601String());
  }

  Future<void> clearBonusSlot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bonusSlotExpiryKey);
  }
}

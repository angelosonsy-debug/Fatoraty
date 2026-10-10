import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/bill.dart';
import '../utils/reminder_calculator.dart';

/// مفتاح التنقل العام — يُستخدم لعمل Deep Link من الإشعار لشاشة تفاصيل
/// الفاتورة مباشرة بدل الشاشة الرئيسية.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // TODO: استخدم flutter_timezone لتحديد المنطقة الزمنية الفعلية للجهاز
    // بدقة بدل الاعتماد على الإعداد الافتراضي للـ timezone package.
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  /// بيتشاف لو التطبيق اتفتح من الصفر (cold start) بسبب ضغط على إشعار —
  /// الحالة دي مختلفة عن onDidReceiveNotificationResponse اللي بيشتغل بس
  /// لو التطبيق كان شغّال أصلاً (foreground/background). من غير الفحص ده،
  /// فتح التطبيق من إشعار والتطبيق مقفول بالكامل كان هيوديك للشاشة
  /// الرئيسية بدل تفاصيل الفاتورة المقصودة.
  Future<String?> getLaunchBillId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  void _onNotificationTap(NotificationResponse response) {
    final billId = response.payload;
    if (billId == null || billId.isEmpty) return;
    navigatorKey.currentState?.pushNamed('/bill-details', arguments: billId);
  }

  Future<void> requestPermission() async {
    // Android 13+ (API 33) يتطلب صلاحية POST_NOTIFICATIONS صراحة
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  int _notificationIdFor(String billId) => billId.hashCode & 0x7fffffff;

  /// يجدول إشعار التذكير القادم لهذه الفاتورة. بما أن flutter_local_notifications
  /// لا يدعم تكرار شهري بـ offset متغير (لأن يوم التذكير = يوم السداد - مدة
  /// التذكير قد يختلف شهرياً حسب طول الشهر)، نجدول أقرب تاريخ تذكير قادم فقط،
  /// ثم نعيد الجدولة تلقائياً عند فتح التطبيق (انظر rescheduleAll).
  ///
  /// TODO: لضمان إعادة الجدولة حتى لو المستخدم ما فتحش التطبيق لفترة طويلة،
  /// فكّر في استخدام WorkManager / AlarmManager دوري بدل الاعتماد فقط على
  /// فتح التطبيق.
  Future<void> scheduleForBill({
    required Bill bill,
    required int hour,
    required int minute,
  }) async {
    await cancelForBill(bill.id);

    final now = DateTime.now();
    var reminderDate = ReminderCalculator.nextReminderDate(
      dueDayOfMonth: bill.dueDayOfMonth,
      leadDays: bill.reminderLead.days,
      from: now,
    );

    var scheduledDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );

    // ReminderCalculator بيحسب بدقة "يوم" بس (من غير ساعة/دقيقة). لو
    // التاريخ المحسوب النهاردة بالظبط، لكن وقت الإشعار المختار (hour:minute)
    // يكون فات بالفعل النهاردة، scheduledDateTime هتبقى في الماضي —
    // وده ممكن يخلي الإشعار يطلق فوراً بدل الميعاد الصح. لو حصل كده،
    // ادفع لأقرب دورة تذكير تانية فعلياً (بدايةً من بكرة).
    if (!scheduledDateTime.isAfter(now)) {
      final tomorrow =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      reminderDate = ReminderCalculator.nextReminderDate(
        dueDayOfMonth: bill.dueDayOfMonth,
        leadDays: bill.reminderLead.days,
        from: tomorrow,
      );
      scheduledDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );
    }

    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final daysLeft = bill.reminderLead.days;

    await _plugin.zonedSchedule(
      _notificationIdFor(bill.id),
      'فاتورتي',
      'فاتورة ${bill.name} مستحقة بعد $daysLeft أيام',
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fatorty_reminders',
          'تذكيرات الفواتير',
          channelDescription: 'إشعارات تذكير بمواعيد سداد الفواتير',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: bill.id,
      // عمداً inexact مش exact: تذكير فاتورة مش محتاج دقة لحظية (زي منبه
      // فعلي)، ويصل عادةً خلال دقايق قليلة من الميعاد المجدول حتى في وضع
      // idle. ده بيتجنّب تمامًا الحاجة لصلاحية SCHEDULE_EXACT_ALARM
      // (اللي مرفوضة افتراضياً من Android 13+ ولازم المستخدم يمنحها يدوياً
      // من الإعدادات) وUSE_EXACT_ALARM (صلاحية مقيّدة من Google Play
      // ومخصصة فعلياً لتطبيقات المنبّه/التقويم بس — استخدامها هنا كان
      // ممكن يسبب رفض أو مراجعة إضافية وقت نشر التطبيق على المتجر).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForBill(String billId) async {
    await _plugin.cancel(_notificationIdFor(billId));
  }

  /// يعيد جدولة كل الفواتير النشطة — يُستدعى عند فتح التطبيق وعند تغيير
  /// إعدادات الإشعارات، لضمان أن الجدول دايمًا محدّث حتى بعد مرور دورة.
  Future<void> rescheduleAll({
    required List<Bill> activeBills,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }
    for (final bill in activeBills) {
      await scheduleForBill(bill: bill, hour: hour, minute: minute);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/bill.dart';
import 'storage_service.dart';
import '../utils/reminder_calculator.dart';

/// مفتاح التنقل العام — يُستخدم لعمل Deep Link من الإشعار لشاشة تفاصيل
/// الفاتورة مباشرة بدل الشاشة الرئيسية.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _snoozeActionId = 'snooze_1day';

/// Entry point منفصل لمعالجة أكشن "تأجيل" من الإشعار لما التطبيق يكون
/// مقفول بالكامل (مش مجرد في الخلفية) — flutter_local_notifications
/// محتاج isolate منفصل للحالة دي، وده مينفعش يكون method جوه كلاس عادي،
/// لازم top-level function بالظبط بالشكل ده.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  if (response.notificationResponseType ==
          NotificationResponseType.selectedNotificationAction &&
      response.actionId == _snoozeActionId) {
    final billId = response.payload;
    if (billId != null && billId.isNotEmpty) {
      // fire-and-forget — الـ isolate هيتقفل بعد ما الدالة ترجع، فمفيش
      // داعي (ولا فايدة) من انتظار النتيجة هنا.
      NotificationService.instance.snoozeOneDay(billId);
    }
  }
}

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

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      // بيتنادى بس لما التطبيق يكون مقفول بالكامل وقت الضغط على أكشن
      // "تأجيل" — راجع التعليق فوق notificationBackgroundHandler.
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
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

    // الضغط على زرار "ذكرني غداً" داخل الإشعار نفسه — مش المفروض يفتح
    // التطبيق، بس لو كان شغّال أصلاً (foreground) هيوصلّنا نفس الـ
    // callback ده بدل الـ background handler المنفصل.
    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction &&
        response.actionId == _snoozeActionId) {
      snoozeOneDay(billId);
      return;
    }

    navigatorKey.currentState?.pushNamed('/bill-details', arguments: billId);
  }

  Future<void> requestPermission() async {
    // Android 13+ (API 33) يتطلب صلاحية POST_NOTIFICATIONS صراحة
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// كل فاتورة ممكن يكون ليها أكتر من تذكير (reminderLeads)، فكل تذكير
  /// محتاج notification id مستقل — من غير كده كل تذكير جديد كان هيمسح
  /// اللي قبله (نفس الـ id). الـ id بيتكوّن من hash الفاتورة + index
  /// مدة التذكير في enum ReminderLeadTime (ثابت دايماً)، فمفيش تعارض.
  int _notificationIdFor(String billId, [ReminderLeadTime? lead]) {
    final base = billId.hashCode & 0x7fffff;
    final leadOffset = lead == null ? 0 : (lead.index + 1);
    return (base * 10 + leadOffset) & 0x7fffffff;
  }

  /// يجدول إشعار واحد لكل مدة تذكير في bill.reminderLeads. بما أن
  /// flutter_local_notifications لا يدعم تكرار شهري بـ offset متغير (لأن
  /// يوم التذكير = يوم السداد - مدة التذكير قد يختلف شهرياً حسب طول
  /// الشهر)، نجدول أقرب تاريخ تذكير قادم فقط لكل مدة، ثم نعيد الجدولة
  /// تلقائياً عند فتح التطبيق (انظر rescheduleAll).
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

    for (final lead in bill.reminderLeads) {
      await _scheduleOneReminder(bill: bill, lead: lead, hour: hour, minute: minute);
    }
  }

  Future<void> _scheduleOneReminder({
    required Bill bill,
    required ReminderLeadTime lead,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var reminderDate = ReminderCalculator.nextReminderDate(
      anchorDate: bill.anchorDate,
      cycleValue: bill.cycleValue,
      cycleUnit: bill.cycleUnit,
      leadDays: lead.days,
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
        anchorDate: bill.anchorDate,
        cycleValue: bill.cycleValue,
        cycleUnit: bill.cycleUnit,
        leadDays: lead.days,
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
    final daysLeft = lead.days;

    await _plugin.zonedSchedule(
      _notificationIdFor(bill.id, lead),
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
          icon: '@drawable/ic_notification',
          actions: [
            AndroidNotificationAction(
              _snoozeActionId,
              'ذكرني غداً',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
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

  /// بيلغي كل الإشعارات المحتملة لفاتورة معينة — بنمسح كل الـ ids
  /// الممكنة (واحد لكل مدة تذكير ممكنة + الـ id الأساسي القديم)، مش بس
  /// اللي الفاتورة حالياً مستخدماه، عشان نضمن مفيش إشعار قديم فاضل معلّق
  /// لو المستخدم غيّر مدد التذكير بعد ما كانت متجدولة.
  Future<void> cancelForBill(String billId) async {
    await _plugin.cancel(_notificationIdFor(billId));
    for (final lead in ReminderLeadTime.values) {
      await _plugin.cancel(_notificationIdFor(billId, lead));
    }
  }

  /// بيأجّل تذكير فاتورة معينة 24 ساعة من دلوقتي — بيتنادى من ضغطة زرار
  /// "ذكرني غداً" جوه الإشعار نفسه (foreground أو background isolate
  /// منفصل تماماً، راجع notificationBackgroundHandler فوق). مُصمَّم
  /// عشان يشتغل من غير أي اعتماد على Provider/widget tree — بس
  /// StorageService و NotificationService نفسهم، عشان يشتغل من جوه
  /// isolate خلفي لما التطبيق يكون مقفول بالكامل.
  Future<void> snoozeOneDay(String billId) async {
    try {
      if (!_initialized) await init();

      final bills = await StorageService().loadBills();
      Bill? bill;
      for (final b in bills) {
        if (b.id == billId) {
          bill = b;
          break;
        }
      }
      if (bill == null) return;

      await cancelForBill(bill.id);

      final snoozeTime = DateTime.now().add(const Duration(days: 1));
      final tzDateTime = tz.TZDateTime.from(snoozeTime, tz.local);

      await _plugin.zonedSchedule(
        _notificationIdFor(bill.id),
        'فاتورتي',
        'تذكير مؤجل: فاتورة ${bill.name}',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fatorty_reminders',
            'تذكيرات الفواتير',
            channelDescription: 'إشعارات تذكير بمواعيد سداد الفواتير',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
        payload: bill.id,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // لو فشل التأجيل، معندناش واجهة نعرض بيها خطأ هنا (ممكن نكون جوه
      // background isolate بلا UI خالص) — نسيبه بصمت بدل ما نكسّر حاجة.
    }
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

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:in_app_review/in_app_review.dart';

import '../models/bill.dart';
import '../models/payment_record.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../utils/reminder_calculator.dart';
import 'settings_provider.dart';

class BillProvider extends ChangeNotifier {
  final StorageService _storage;
  final SettingsProvider _settings;

  BillProvider(this._storage, this._settings);

  List<Bill> _bills = [];
  List<PaymentRecord> _payments = [];
  bool loaded = false;

  List<Bill> get allBills => List.unmodifiable(_bills);

  /// الفواتير النشطة، مرتبة بالاستحقاق الفعلي القادم (الأقرب الأول) — مش
  /// بس بترتيب "يوم الشهر" زي قبل، لأن دلوقتي الدورات مختلفة (أسبوعي، ربع
  /// سنوي، إلخ) فمقارنة الأيام مباشرة متبقاش ذات معنى.
  List<Bill> get activeBills {
    final now = DateTime.now();
    final list = _bills.where((b) => !b.archived).toList();
    list.sort((a, b) {
      final dueA = ReminderCalculator.nextDueDate(
        anchorDate: a.anchorDate,
        cycleValue: a.cycleValue,
        cycleUnit: a.cycleUnit,
        from: now,
      );
      final dueB = ReminderCalculator.nextDueDate(
        anchorDate: b.anchorDate,
        cycleValue: b.cycleValue,
        cycleUnit: b.cycleUnit,
        from: now,
      );
      return dueA.compareTo(dueB);
    });
    return list;
  }

  List<Bill> get archivedBills => _bills.where((b) => b.archived).toList();

  Future<void> load() async {
    try {
      _bills = await _storage.loadBills();
    } catch (_) {
      // لو أي خطأ غير متوقع حصل برضه، مانخليش الشاشة الرئيسية عالقة
      // على دائرة تحميل للأبد — نكمل بقائمة فاضية بدل كده.
      _bills = [];
    }
    try {
      _payments = await _storage.loadPayments();
    } catch (_) {
      _payments = [];
    }
    loaded = true;
    notifyListeners();
    try {
      await _resyncNotifications();
    } catch (_) {
      // فشل جدولة الإشعارات (مثلاً مشكلة في الصلاحيات) متمنعش عرض
      // الفواتير نفسها.
    }
    await _syncWidget();
  }

  Future<void> _persist() async {
    await _storage.saveBills(_bills);
  }

  /// بيحدّث Home Screen Widget بأقرب فاتورة مستحقة — بيتنادى بعد أي تعديل
  /// فعلي على الفواتير (إضافة/تعديل/حذف/أرشفة/استرجاع)، مش بس عند فتح
  /// التطبيق.
  Future<void> _syncWidget() async {
    try {
      await WidgetService.update(activeBills);
    } catch (_) {}
  }

  /// استرجاع كامل من نسخة احتياطية — بيستبدل كل الفواتير الحالية بالي في
  /// الملف المستورد (استبدال كامل، مش دمج)، وبعدين يعيد جدولة كل
  /// التذكيرات من جديد. العملية دي هدّامة (بتمسح أي فواتير حالية مش
  /// موجودة في النسخة الاحتياطية)، فلازم تأكيد من المستخدم قبل ما تتنادى.
  Future<void> restoreFromBackup(
    List<Bill> importedBills,
    List<PaymentRecord> importedPayments,
  ) async {
    // لإلغاء أي إشعارات مجدولة للفواتير الحالية قبل ما نمسحها
    for (final old in _bills) {
      try {
        await NotificationService.instance.cancelForBill(old.id);
      } catch (_) {}
    }

    _bills = importedBills;
    _payments = importedPayments;
    await _persist();
    await _storage.savePayments(_payments);
    notifyListeners();

    try {
      await _resyncNotifications();
    } catch (_) {}
    await _syncWidget();
  }

  Future<void> _resyncNotifications() async {
    await NotificationService.instance.rescheduleAll(
      activeBills: activeBills,
      enabled: _settings.notificationsEnabled,
      hour: _settings.notificationTime.hour,
      minute: _settings.notificationTime.minute,
    );
  }

  Future<Bill> addBill({
    required String name,
    required BillServiceType serviceType,
    required BillKind kind,
    required DateTime anchorDate,
    required int cycleValue,
    required BillCycleUnit cycleUnit,
    double? approximateAmount,
    required List<ReminderLeadTime> reminderLeads,
  }) async {
    final bill = Bill(
      id: const Uuid().v4(),
      name: name,
      serviceType: serviceType,
      kind: kind,
      anchorDate: anchorDate,
      cycleValue: cycleValue,
      cycleUnit: cycleUnit,
      approximateAmount: approximateAmount,
      reminderLeads: reminderLeads,
      createdAt: DateTime.now(),
    );
    _bills.add(bill);
    await _persist();
    notifyListeners();
    // لو جدولة الإشعار فشلت لأي سبب (مشكلة منصة، صلاحية، إلخ)، الفاتورة
    // اتحفظت فعلاً بنجاح فوق — متمنعش استمرار العملية ولا نرمي exception
    // للشاشة اللي استدعت addBill (ده كان بيسيب معالج الإضافة عالق بصمت).
    if (_settings.notificationsEnabled) {
      try {
        await NotificationService.instance.scheduleForBill(
          bill: bill,
          hour: _settings.notificationTime.hour,
          minute: _settings.notificationTime.minute,
        );
      } catch (_) {
        // TODO: أظهر تحذير غير حاجب للمستخدم ("الفاتورة اتحفظت، بس
        // التذكير مقدرش يتفعّل") بدل التجاهل الصامت.
      }
    }
    await _storage.incrementUsageCount();
    await _maybePromptForRating();
    await _syncWidget();
    return bill;
  }

  /// يطلب تقييم التطبيق مرة واحدة بس، بعد 3-5 استخدامات (إضافة فواتير)
  /// زي ما هو مطلوب في الـ checklist الأساسي. in_app_review نفسه بيحترم
  /// حدود Google Play الداخلية (بيمنع الإلحاح كمان من جهته)، لكن بنضيف
  /// علم محلي عشان حتى المحاولة الأولى تحصل مرة واحدة بس مش كل مرة
  /// العداد يقع في المدى ده.
  Future<void> _maybePromptForRating() async {
    try {
      final alreadyShown = await _storage.ratingPromptShown();
      if (alreadyShown) return;

      final count = await _storage.usageCount();
      if (count < 3 || count > 5) return;

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await _storage.setRatingPromptShown();
      }
    } catch (_) {
      // فشل طلب التقييم (مثلاً مش متاح على الجهاز) متأثرش على حفظ الفاتورة
    }
  }

  Future<void> updateBill(Bill updated) async {
    final index = _bills.indexWhere((b) => b.id == updated.id);
    if (index == -1) return;
    _bills[index] = updated;
    await _persist();
    notifyListeners();
    try {
      if (updated.archived || !_settings.notificationsEnabled) {
        await NotificationService.instance.cancelForBill(updated.id);
      } else {
        await NotificationService.instance.scheduleForBill(
          bill: updated,
          hour: _settings.notificationTime.hour,
          minute: _settings.notificationTime.minute,
        );
      }
    } catch (_) {
      // فشل جدولة/إلغاء الإشعار متمنعش إن التعديل يتحفظ بنجاح
    }
    await _syncWidget();
  }

  Future<void> archiveBill(String id) async {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index == -1) return;
    _bills[index] = _bills[index].copyWith(archived: true);
    await _persist();
    notifyListeners();
    try {
      await NotificationService.instance.cancelForBill(id);
    } catch (_) {}
    await _syncWidget();
  }

  Future<void> restoreBill(String id) async {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index == -1) return;
    _bills[index] = _bills[index].copyWith(archived: false);
    await _persist();
    notifyListeners();
    if (_settings.notificationsEnabled) {
      try {
        await NotificationService.instance.scheduleForBill(
          bill: _bills[index],
          hour: _settings.notificationTime.hour,
          minute: _settings.notificationTime.minute,
        );
      } catch (_) {}
    }
    await _syncWidget();
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _persist();
    notifyListeners();
    await NotificationService.instance.cancelForBill(id);
    await _syncWidget();
  }

  Bill? byId(String id) {
    try {
      return _bills.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===================== سجل المدفوعات =====================

  /// كل المدفوعات، الأحدث أولاً.
  List<PaymentRecord> get allPayments {
    final list = List<PaymentRecord>.from(_payments);
    list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  }

  /// سجل المدفوعات الخاص بفاتورة معينة، الأحدث أولاً.
  List<PaymentRecord> paymentsForBill(String billId) =>
      allPayments.where((p) => p.billId == billId).toList();

  /// إجمالي المدفوع فعلياً خلال شهر تقويمي معين (مش تقديري زي
  /// approximateMonthlyTotal — ده بناءً على سجلات "تم السداد" الحقيقية).
  double totalPaidInMonth(DateTime month) {
    return _payments
        .where((p) =>
            p.paidAt.year == month.year && p.paidAt.month == month.month)
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// إجمالي المدفوعات مجمّعة بالشهر (مفتاح "yyyy-MM")، مرتبة من الأحدث
  /// للأقدم — مفيدة لشاشة سجل المصروفات.
  Map<String, double> monthlyPaymentTotals() {
    final map = <String, double>{};
    for (final p in _payments) {
      final key =
          '${p.paidAt.year}-${p.paidAt.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + p.amount;
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  /// تسجيل إن الفاتورة اتدفعت — مجرد سجل تاريخي، مبيأثرش على حساب دورة
  /// الاستحقاق القادمة (ده دايماً بيتحسب من anchorDate + الدورة بغض النظر
  /// عن حالة الدفع). المبلغ ده ممكن يكون مختلف عن approximateAmount
  /// (المبلغ الفعلي وقت الدفع، مش التقديري وقت إنشاء الفاتورة).
  Future<PaymentRecord> markAsPaid({
    required Bill bill,
    required double amount,
    DateTime? paidAt,
  }) async {
    final record = PaymentRecord(
      id: const Uuid().v4(),
      billId: bill.id,
      billName: bill.name,
      amount: amount,
      paidAt: paidAt ?? DateTime.now(),
    );
    _payments.add(record);
    await _storage.savePayments(_payments);
    notifyListeners();
    return record;
  }

  /// حذف سجل دفعة واحد (لو اتسجّل بالغلط)
  Future<void> deletePaymentRecord(String paymentId) async {
    _payments.removeWhere((p) => p.id == paymentId);
    await _storage.savePayments(_payments);
    notifyListeners();
  }

  /// مجموع المبالغ التقريبية للفواتير النشطة (لبطاقة "هذا الشهر")
  double get approximateMonthlyTotal => activeBills.fold<double>(
      0, (sum, b) => sum + (b.approximateAmount ?? 0));

  /// عدد الفواتير اللي موعدها قريب (خلال نطاق مدة تذكيرها الخاصة)
  int dueSoonCount({DateTime? now}) {
    final from = now ?? DateTime.now();
    return activeBills.where((b) {
      final daysLeft = ReminderCalculator.daysUntilDue(
        anchorDate: b.anchorDate,
        cycleValue: b.cycleValue,
        cycleUnit: b.cycleUnit,
        from: from,
      );
      return daysLeft <= b.earliestReminderLead.days;
    }).length;
  }
}

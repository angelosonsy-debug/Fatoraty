import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/bill.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/reminder_calculator.dart';
import 'settings_provider.dart';

class BillProvider extends ChangeNotifier {
  final StorageService _storage;
  final SettingsProvider _settings;

  BillProvider(this._storage, this._settings);

  List<Bill> _bills = [];
  bool loaded = false;

  List<Bill> get allBills => List.unmodifiable(_bills);
  List<Bill> get activeBills =>
      _bills.where((b) => !b.archived).toList()
        ..sort((a, b) => a.dueDayOfMonth.compareTo(b.dueDayOfMonth));
  List<Bill> get archivedBills => _bills.where((b) => b.archived).toList();

  Future<void> load() async {
    try {
      _bills = await _storage.loadBills();
    } catch (_) {
      // لو أي خطأ غير متوقع حصل برضه، مانخليش الشاشة الرئيسية عالقة
      // على دائرة تحميل للأبد — نكمل بقائمة فاضية بدل كده.
      _bills = [];
    }
    loaded = true;
    notifyListeners();
    try {
      await _resyncNotifications();
    } catch (_) {
      // فشل جدولة الإشعارات (مثلاً مشكلة في الصلاحيات) متمنعش عرض
      // الفواتير نفسها.
    }
  }

  Future<void> _persist() async {
    await _storage.saveBills(_bills);
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
    required int dueDayOfMonth,
    double? approximateAmount,
    required ReminderLeadTime reminderLead,
  }) async {
    final bill = Bill(
      id: const Uuid().v4(),
      name: name,
      serviceType: serviceType,
      kind: kind,
      dueDayOfMonth: dueDayOfMonth,
      approximateAmount: approximateAmount,
      reminderLead: reminderLead,
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
    return bill;
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
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _persist();
    notifyListeners();
    await NotificationService.instance.cancelForBill(id);
  }

  Bill? byId(String id) {
    try {
      return _bills.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// مجموع المبالغ التقريبية للفواتير النشطة (لبطاقة "هذا الشهر")
  double get approximateMonthlyTotal => activeBills.fold<double>(
      0, (sum, b) => sum + (b.approximateAmount ?? 0));

  /// عدد الفواتير اللي موعدها قريب (خلال نطاق مدة تذكيرها الخاصة)
  int dueSoonCount({DateTime? now}) {
    final from = now ?? DateTime.now();
    return activeBills.where((b) {
      final daysLeft = ReminderCalculator.daysUntilDue(b.dueDayOfMonth, from);
      return daysLeft <= b.reminderLead.days;
    }).length;
  }
}

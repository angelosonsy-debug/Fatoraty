import 'package:home_widget/home_widget.dart';

import '../models/bill.dart';
import '../utils/reminder_calculator.dart';

/// بيزامن بيانات أقرب الفواتير استحقاقاً (لحد 3) مع Home Screen Widget
/// الأندرويد (FatortyWidgetProvider.kt). بيتنادى من BillProvider في كل
/// مرة الفواتير تتغيّر (إضافة/تعديل/حذف/أرشفة/استرجاع)، مش بس عند فتح
/// التطبيق — عشان الـ widget يفضل محدّث لحظياً.
class WidgetService {
  WidgetService._();

  // لازم يطابق class name بتاع FatortyWidgetProvider.kt بالظبط
  static const _androidWidgetName = 'FatortyWidgetProvider';

  static const int maxRows = 3;

  /// بياخد الفواتير النشطة، يرتبهم بالاستحقاق الأقرب، ويبعت أقرب 3 منهم
  /// للـ widget (صف لكل فاتورة). لو القائمة فاضية، الـ widget هيعرض حالة
  /// "لا توجد فواتير".
  static Future<void> update(List<Bill> activeBills) async {
    try {
      final now = DateTime.now();
      final fromDay = DateTime(now.year, now.month, now.day);

      final withDueDates = activeBills.map((bill) {
        final due = ReminderCalculator.nextDueDate(
          anchorDate: bill.anchorDate,
          cycleValue: bill.cycleValue,
          cycleUnit: bill.cycleUnit,
          from: now,
        );
        return (bill: bill, due: due);
      }).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

      final topBills = withDueDates.take(maxRows).toList();

      for (var i = 0; i < maxRows; i++) {
        if (i < topBills.length) {
          final entry = topBills[i];
          final daysLeft = entry.due.difference(fromDay).inDays;
          final String subtitle;
          if (daysLeft <= 0) {
            subtitle = 'مستحقة اليوم';
          } else if (daysLeft == 1) {
            subtitle = 'مستحقة بعد يوم واحد';
          } else {
            subtitle = 'مستحقة بعد $daysLeft أيام';
          }
          await HomeWidget.saveWidgetData<String>(
              'widget_bill_name_$i', entry.bill.name);
          await HomeWidget.saveWidgetData<String>(
              'widget_bill_subtitle_$i', subtitle);
        } else {
          // صف فاضي — الـ Kotlin provider هيخفيه لو الاسم فاضي
          await HomeWidget.saveWidgetData<String>('widget_bill_name_$i', '');
          await HomeWidget.saveWidgetData<String>(
              'widget_bill_subtitle_$i', '');
        }
      }

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // فشل تحديث الـ widget (مثلاً الجهاز مش مضيف الـ widget أصلاً)
      // مينفعش يأثر على باقي وظائف التطبيق.
    }
  }
}

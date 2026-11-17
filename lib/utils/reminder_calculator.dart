import '../models/bill.dart';

/// منطق حساب تاريخ التذكير بناءً على تاريخ استحقاق مرجعي (anchor) ودورة
/// تكرار عامة (كل N يوم/أسبوع/شهر/سنة) + مدة التذكير.
///
/// القواعد:
/// - الدورات الشهرية/السنوية بتحافظ على "يوم الشهر" الأصلي، مع "قصّ" اليوم
///   على آخر يوم متاح في الشهر لو كان أكبر من عدد أيامه (مثلاً يوم 31 في
///   شهر فبراير).
/// - لو طرح مدة التذكير من تاريخ الاستحقاق يرجع لدورة سابقة، يجب حساب
///   التاريخ صح وليس مجرد رقم سالب.
/// - يجب دائمًا إرجاع أقرب تاريخ تذكير/استحقاق *مستقبلي* بالنسبة إلى
///   [from] (أو يساويه).
class ReminderCalculator {
  ReminderCalculator._();

  /// يرجع تاريخ صالح في شهر/سنة معينين، مع "قصّ" اليوم على آخر يوم متاح
  /// في الشهر لو كان اليوم المطلوب أكبر من عدد أيامه.
  static DateTime dateForMonth(int year, int month, int day) {
    // تطبيع الشهر (لو month > 12 أو < 1)
    final normalizedYear = year + ((month - 1) ~/ 12);
    final normalizedMonth = ((month - 1) % 12) + 1;
    final daysInMonth =
        DateTime(normalizedYear, normalizedMonth + 1, 0).day;
    final clampedDay = day > daysInMonth ? daysInMonth : (day < 1 ? 1 : day);
    return DateTime(normalizedYear, normalizedMonth, clampedDay);
  }

  /// يضيف [k] دورة (كل دورة = [cycleValue] وحدة [cycleUnit]) على
  /// [anchor]، مع قصّ اليوم عند الحاجة لدورات الشهر/السنة.
  static DateTime _addCycles(
    DateTime anchor,
    int k,
    int cycleValue,
    BillCycleUnit cycleUnit,
  ) {
    switch (cycleUnit) {
      case BillCycleUnit.day:
        return anchor.add(Duration(days: k * cycleValue));
      case BillCycleUnit.week:
        return anchor.add(Duration(days: k * cycleValue * 7));
      case BillCycleUnit.month:
        return dateForMonth(
            anchor.year, anchor.month + k * cycleValue, anchor.day);
      case BillCycleUnit.year:
        return dateForMonth(
            anchor.year, anchor.month + k * cycleValue * 12, anchor.day);
    }
  }

  /// أقرب تاريخ استحقاق لاحق لـ [from] أو يساويه، بناءً على [anchorDate]
  /// ودورة التكرار ([cycleValue] × [cycleUnit]).
  static DateTime nextDueDate({
    required DateTime anchorDate,
    required int cycleValue,
    required BillCycleUnit cycleUnit,
    required DateTime from,
  }) {
    final fromDay = DateTime(from.year, from.month, from.day);
    final anchorDay =
        DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    if (!anchorDay.isBefore(fromDay)) return anchorDay;

    // قفزة تقريبية (floor) لتقليل عدد التكرارات، ثم تصحيح دقيق بحلقة
    // محدودة (أقصى كام تكرار بسيط) لضمان الوصول لأول دورة >= from بالظبط.
    int k;
    if (cycleUnit == BillCycleUnit.day || cycleUnit == BillCycleUnit.week) {
      final stepDays = cycleValue * (cycleUnit == BillCycleUnit.week ? 7 : 1);
      final diffDays = fromDay.difference(anchorDay).inDays;
      k = (diffDays / stepDays).floor();
    } else {
      final monthsPerCycle =
          cycleValue * (cycleUnit == BillCycleUnit.year ? 12 : 1);
      final totalMonthsDiff =
          (fromDay.year - anchorDay.year) * 12 + (fromDay.month - anchorDay.month);
      k = (totalMonthsDiff / monthsPerCycle).floor();
    }
    if (k < 0) k = 0;

    var candidate = _addCycles(anchorDay, k, cycleValue, cycleUnit);
    while (candidate.isBefore(fromDay)) {
      k++;
      candidate = _addCycles(anchorDay, k, cycleValue, cycleUnit);
    }
    return candidate;
  }

  /// تاريخ التذكير القادم (تاريخ الاستحقاق - مدة التذكير)، مضموناً أنه في
  /// المستقبل بالنسبة لـ [from]. لو اليوم المحسوب في الماضي (الدورة دي
  /// فات ميعاد تذكيرها بالفعل) نقفز لدورة الاستحقاق التالية.
  static DateTime nextReminderDate({
    required DateTime anchorDate,
    required int cycleValue,
    required BillCycleUnit cycleUnit,
    required int leadDays,
    required DateTime from,
  }) {
    final fromDay = DateTime(from.year, from.month, from.day);

    var due = nextDueDate(
      anchorDate: anchorDate,
      cycleValue: cycleValue,
      cycleUnit: cycleUnit,
      from: from,
    );
    var reminder = due.subtract(Duration(days: leadDays));

    if (reminder.isBefore(fromDay)) {
      // ميعاد الاستحقاق هذه الدورة قريب جداً أو التذكير فات بالفعل،
      // انتقل لدورة الاستحقاق التالية.
      due = nextDueDate(
        anchorDate: anchorDate,
        cycleValue: cycleValue,
        cycleUnit: cycleUnit,
        from: due.add(const Duration(days: 1)),
      );
      reminder = due.subtract(Duration(days: leadDays));
    }

    return reminder;
  }

  /// عدد الأيام المتبقية حتى الاستحقاق، لعرضها في الواجهة (Badge "قريب").
  static int daysUntilDue({
    required DateTime anchorDate,
    required int cycleValue,
    required BillCycleUnit cycleUnit,
    required DateTime from,
  }) {
    final due = nextDueDate(
      anchorDate: anchorDate,
      cycleValue: cycleValue,
      cycleUnit: cycleUnit,
      from: from,
    );
    final fromDay = DateTime(from.year, from.month, from.day);
    return due.difference(fromDay).inDays;
  }
}

/// منطق حساب تاريخ التذكير بناءً على يوم السداد الشهري ومدة التذكير.
///
/// القواعد:
/// - يوم السداد قد يكون أكبر من عدد أيام الشهر (مثلاً 31 في شهر فبراير)،
///   في هذه الحالة نستخدم آخر يوم في الشهر (clamp).
/// - لو طرح مدة التذكير من يوم السداد يرجع لشهر سابق (مثلاً يوم السداد = 1
///   والتذكير أسبوعين)، يجب حساب التاريخ في الشهر السابق بشكل صحيح وليس
///   مجرد رقم سالب.
/// - يجب دائمًا إرجاع أقرب تاريخ تذكير *مستقبلي* بالنسبة إلى `from`.
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

  /// أقرب تاريخ استحقاق (due date) لاحق لـ [from] أو يساويه.
  static DateTime nextDueDate(int dueDayOfMonth, DateTime from) {
    final fromDay = DateTime(from.year, from.month, from.day);
    var candidate = dateForMonth(from.year, from.month, dueDayOfMonth);
    if (candidate.isBefore(fromDay)) {
      candidate = dateForMonth(from.year, from.month + 1, dueDayOfMonth);
    }
    return candidate;
  }

  /// تاريخ التذكير القادم (due date - lead days)، مضموناً أنه في المستقبل
  /// بالنسبة لـ [from]. لو اليوم المحسوب في الماضي (لأن الشهر الحالي خلاص
  /// فات ميعاد تذكيره) نقفز لدورة الاستحقاق التالية.
  static DateTime nextReminderDate({
    required int dueDayOfMonth,
    required int leadDays,
    required DateTime from,
  }) {
    final fromDay = DateTime(from.year, from.month, from.day);

    var due = nextDueDate(dueDayOfMonth, from);
    var reminder = due.subtract(Duration(days: leadDays));

    if (reminder.isBefore(fromDay)) {
      // ميعاد الاستحقاق هذه الدورة قريب جداً أو التذكير فات بالفعل،
      // انتقل لدورة الاستحقاق التالية (الشهر اللي بعده).
      due = dateForMonth(due.year, due.month + 1, dueDayOfMonth);
      reminder = due.subtract(Duration(days: leadDays));
    }

    return reminder;
  }

  /// عدد الأيام المتبقية حتى الاستحقاق، لعرضها في الواجهة (Badge "قريب").
  static int daysUntilDue(int dueDayOfMonth, DateTime from) {
    final due = nextDueDate(dueDayOfMonth, from);
    final fromDay = DateTime(from.year, from.month, from.day);
    return due.difference(fromDay).inDays;
  }
}

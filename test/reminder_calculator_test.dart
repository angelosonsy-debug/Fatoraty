import 'package:flutter_test/flutter_test.dart';
import 'package:fatorty/utils/reminder_calculator.dart';

void main() {
  group('ReminderCalculator.dateForMonth', () {
    test('clamps day 31 to last day of February (non-leap year)', () {
      final d = ReminderCalculator.dateForMonth(2025, 2, 31);
      expect(d, DateTime(2025, 2, 28));
    });

    test('clamps day 31 to last day of February (leap year)', () {
      final d = ReminderCalculator.dateForMonth(2024, 2, 31);
      expect(d, DateTime(2024, 2, 29));
    });

    test('handles month overflow (month 13 -> next year January)', () {
      final d = ReminderCalculator.dateForMonth(2025, 13, 5);
      expect(d, DateTime(2026, 1, 5));
    });
  });

  group('ReminderCalculator.nextDueDate', () {
    test('returns this month due date if still ahead', () {
      final from = DateTime(2025, 6, 10);
      final due = ReminderCalculator.nextDueDate(20, from);
      expect(due, DateTime(2025, 6, 20));
    });

    test('rolls to next month if due date already passed', () {
      final from = DateTime(2025, 6, 25);
      final due = ReminderCalculator.nextDueDate(20, from);
      expect(due, DateTime(2025, 7, 20));
    });

    test('today counts as due (not passed)', () {
      final from = DateTime(2025, 6, 20);
      final due = ReminderCalculator.nextDueDate(20, from);
      expect(due, DateTime(2025, 6, 20));
    });
  });

  group('ReminderCalculator.nextReminderDate — month boundary', () {
    // الحالة الحرجة المذكورة في المواصفات: يوم سداد = 1، تذكير = أسبوعين.
    // لازم يرجع تاريخ في الشهر اللي قبل شهر الاستحقاق.
    test('due day = 1, lead = 2 weeks -> reminder falls in previous month', () {
      final from = DateTime(2025, 6, 10); // أي يوم في يونيو
      final reminder = ReminderCalculator.nextReminderDate(
        dueDayOfMonth: 1,
        leadDays: 14,
        from: from,
      );
      // أقرب استحقاق قادم هو 1 يوليو، التذكير قبله بـ14 يوم = 17 يونيو
      expect(reminder, DateTime(2025, 6, 17));
      expect(reminder.isAfter(from) || reminder.isAtSameMomentAs(from), true);
    });

    test('if computed reminder already passed, jump to next cycle', () {
      // استحقاق يوم 1، تذكير أسبوعين قبله = يوم 17 بالشهر السابق.
      // لو إحنا بعد يوم 17 خلاص، المفروض يقفز لدورة الاستحقاق اللي بعدها.
      final from = DateTime(2025, 6, 20); // بعد 17 يونيو
      final reminder = ReminderCalculator.nextReminderDate(
        dueDayOfMonth: 1,
        leadDays: 14,
        from: from,
      );
      // الاستحقاق القادم: 1 أغسطس (لأن استحقاق 1 يوليو تذكيره فات في 17 يونيو)
      expect(reminder, DateTime(2025, 7, 18));
    });

    test('due day near end of month with long lead time', () {
      final from = DateTime(2025, 1, 1);
      final reminder = ReminderCalculator.nextReminderDate(
        dueDayOfMonth: 31,
        leadDays: 14,
        from: from,
      );
      // أقرب استحقاق: 31 يناير -> تذكير 17 يناير، ده بعد from فهو صالح
      expect(reminder, DateTime(2025, 1, 17));
    });

    test('same-day short lead time (1 day)', () {
      final from = DateTime(2025, 3, 1);
      final reminder = ReminderCalculator.nextReminderDate(
        dueDayOfMonth: 5,
        leadDays: 1,
        from: from,
      );
      expect(reminder, DateTime(2025, 3, 4));
    });
  });

  group('ReminderCalculator.daysUntilDue', () {
    test('counts remaining days correctly', () {
      final from = DateTime(2025, 6, 10);
      final days = ReminderCalculator.daysUntilDue(20, from);
      expect(days, 10);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fatorty/models/bill.dart';
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

  group('ReminderCalculator.nextDueDate — monthly (backward-compat case)', () {
    test('returns this month due date if still ahead', () {
      final from = DateTime(2025, 6, 10);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2025, 1, 20),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.month,
        from: from,
      );
      expect(due, DateTime(2025, 6, 20));
    });

    test('rolls to next month if due date already passed', () {
      final from = DateTime(2025, 6, 25);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2025, 1, 20),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.month,
        from: from,
      );
      expect(due, DateTime(2025, 7, 20));
    });
  });

  group('ReminderCalculator.nextReminderDate — month boundary (critical case)', () {
    test('due day = 1, lead = 2 weeks -> reminder falls in previous month', () {
      final from = DateTime(2025, 6, 10);
      final reminder = ReminderCalculator.nextReminderDate(
        anchorDate: DateTime(2025, 1, 1),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.month,
        leadDays: 14,
        from: from,
      );
      expect(reminder, DateTime(2025, 6, 17));
    });

    test('if computed reminder already passed, jump to next cycle', () {
      final from = DateTime(2025, 6, 20);
      final reminder = ReminderCalculator.nextReminderDate(
        anchorDate: DateTime(2025, 1, 1),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.month,
        leadDays: 14,
        from: from,
      );
      expect(reminder, DateTime(2025, 7, 18));
    });
  });

  group('ReminderCalculator — quarterly (كل 3 أشهر، زي الخط الأرضي)', () {
    test('next due date lands exactly 3 months after anchor', () {
      final from = DateTime(2025, 2, 1);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2025, 1, 15),
        cycleValue: 3,
        cycleUnit: BillCycleUnit.month,
        from: from,
      );
      expect(due, DateTime(2025, 4, 15));
    });

    test('skips multiple elapsed quarters correctly', () {
      final from = DateTime(2025, 6, 1);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2024, 1, 15),
        cycleValue: 3,
        cycleUnit: BillCycleUnit.month,
        from: from,
      );
      expect(due, DateTime(2025, 7, 15));
    });
  });

  group('ReminderCalculator — weekly (أسبوعي)', () {
    test('next due date is the nearest future weekly occurrence', () {
      final from = DateTime(2025, 3, 10);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2025, 3, 3),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.week,
        from: from,
      );
      expect(due, DateTime(2025, 3, 10));
    });

    test('reminder lead longer than cycle still resolves to a future date', () {
      final from = DateTime(2025, 3, 5);
      final reminder = ReminderCalculator.nextReminderDate(
        anchorDate: DateTime(2025, 3, 3),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.week,
        leadDays: 2,
        from: from,
      );
      expect(reminder.isAfter(from) || reminder == from, true);
    });
  });

  group('ReminderCalculator — custom cycle (كل N يوم)', () {
    test('every 10 days from a given anchor', () {
      final from = DateTime(2025, 1, 25);
      final due = ReminderCalculator.nextDueDate(
        anchorDate: DateTime(2025, 1, 1),
        cycleValue: 10,
        cycleUnit: BillCycleUnit.day,
        from: from,
      );
      expect(due, DateTime(2025, 1, 31));
    });
  });

  group('ReminderCalculator.daysUntilDue', () {
    test('counts remaining days correctly', () {
      final from = DateTime(2025, 6, 10);
      final days = ReminderCalculator.daysUntilDue(
        anchorDate: DateTime(2025, 1, 20),
        cycleValue: 1,
        cycleUnit: BillCycleUnit.month,
        from: from,
      );
      expect(days, 10);
    });
  });
}

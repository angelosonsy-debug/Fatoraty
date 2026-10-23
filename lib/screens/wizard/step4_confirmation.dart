import 'package:flutter/material.dart';
import '../../models/bill.dart';
import '../../utils/reminder_calculator.dart';

class Step4Confirmation extends StatelessWidget {
  final String name;
  final BillServiceType serviceType;
  final BillKind kind;
  final DateTime anchorDate;
  final int cycleValue;
  final BillCycleUnit cycleUnit;
  final List<ReminderLeadTime> reminderLeads;

  const Step4Confirmation({
    super.key,
    required this.name,
    required this.serviceType,
    required this.kind,
    required this.anchorDate,
    required this.cycleValue,
    required this.cycleUnit,
    required this.reminderLeads,
  });

  String _nextDueLabel() {
    final due = ReminderCalculator.nextDueDate(
      anchorDate: anchorDate,
      cycleValue: cycleValue,
      cycleUnit: cycleUnit,
      from: DateTime.now(),
    );
    return '${due.day}/${due.month}/${due.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('تأكيد الفاتورة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: serviceType.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(serviceType.icon,
                            color: serviceType.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(kind.label,
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _SummaryLine(
                      label: 'دورة السداد',
                      value: billCycleLabel(cycleValue, cycleUnit)),
                  const SizedBox(height: 10),
                  _SummaryLine(
                      label: 'الاستحقاق القادم',
                      value: _nextDueLabel()),
                  const SizedBox(height: 10),
                  _SummaryLine(
                      label: 'التذكير',
                      value: reminderLeads.map((r) => 'قبل ${r.days} أيام').join(' + ')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

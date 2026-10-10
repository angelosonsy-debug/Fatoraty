import 'package:flutter/material.dart';
import '../../models/bill.dart';

class Step4Confirmation extends StatelessWidget {
  final String name;
  final BillServiceType serviceType;
  final BillKind kind;
  final int dueDayOfMonth;
  final ReminderLeadTime reminderLead;

  const Step4Confirmation({
    super.key,
    required this.name,
    required this.serviceType,
    required this.kind,
    required this.dueDayOfMonth,
    required this.reminderLead,
  });

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
                  _SummaryLine(label: 'يوم السداد', value: 'يوم $dueDayOfMonth من كل شهر'),
                  const SizedBox(height: 10),
                  _SummaryLine(
                      label: 'التذكير', value: 'قبل ${reminderLead.days} أيام'),
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

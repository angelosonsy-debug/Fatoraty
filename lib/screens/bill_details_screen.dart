import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../utils/reminder_calculator.dart';

class BillDetailsScreen extends StatelessWidget {
  final String billId;
  const BillDetailsScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final bill = billProvider.byId(billId);

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
        body: const Center(child: Text('الفاتورة غير موجودة (ربما حُذفت)')),
      );
    }

    final nextDue = ReminderCalculator.nextDueDate(
        bill.dueDayOfMonth, DateTime.now());
    final nextReminder = ReminderCalculator.nextReminderDate(
      dueDayOfMonth: bill.dueDayOfMonth,
      leadDays: bill.reminderLead.days,
      from: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(bill.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'archive') {
                context.read<BillProvider>().archiveBill(bill.id);
                if (context.mounted) Navigator.pop(context);
              } else if (value == 'delete') {
                // حذف نهائي وغير قابل للتراجع — لازم تأكيد، بنفس نمط
                // شاشة الأرشيف، بدل ما يتنفذ فوراً من أول ضغطة بالغلط.
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف نهائي؟'),
                    content: Text(
                        'سيتم حذف "${bill.name}" نهائياً ولا يمكن التراجع.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child:
                            const Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<BillProvider>().deleteBill(bill.id);
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'archive', child: Text('أرشفة')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bill.serviceType.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(bill.serviceType.icon,
                  color: bill.serviceType.color, size: 34),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Row('النوع', bill.serviceType.label),
                  const Divider(),
                  _Row('نوع الفاتورة', bill.kind.label),
                  const Divider(),
                  _Row('يوم السداد', 'يوم ${bill.dueDayOfMonth} من كل شهر'),
                  const Divider(),
                  if (bill.approximateAmount != null) ...[
                    _Row('المبلغ التقريبي',
                        '${bill.approximateAmount!.toStringAsFixed(0)} جنيه'),
                    const Divider(),
                  ],
                  _Row('التذكير', 'قبل ${bill.reminderLead.days} أيام'),
                  const Divider(),
                  _Row('الاستحقاق القادم',
                      '${nextDue.day}/${nextDue.month}/${nextDue.year}'),
                  const Divider(),
                  _Row('التذكير القادم',
                      '${nextReminder.day}/${nextReminder.month}/${nextReminder.year}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

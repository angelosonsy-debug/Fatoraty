import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../models/payment_record.dart';
import '../providers/bill_provider.dart';
import '../utils/reminder_calculator.dart';
import '../widgets/electricity_calculator_sheet.dart';
import '../widgets/payment_methods_sheet.dart';

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

    final now = DateTime.now();
    final nextDue = ReminderCalculator.nextDueDate(
      anchorDate: bill.anchorDate,
      cycleValue: bill.cycleValue,
      cycleUnit: bill.cycleUnit,
      from: now,
    );
    // الفاتورة ممكن يكون ليها أكتر من مدة تذكير — بنعرض أقرب واحد هيحصل
    // فعلياً (التذكيرات التانية هتيجي بعده بالترتيب).
    final nextReminder = bill.reminderLeads
        .map((lead) => ReminderCalculator.nextReminderDate(
              anchorDate: bill.anchorDate,
              cycleValue: bill.cycleValue,
              cycleUnit: bill.cycleUnit,
              leadDays: lead.days,
              from: now,
            ))
        .reduce((a, b) => a.isBefore(b) ? a : b);

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
                  _Row('دورة السداد', bill.cycleLabel),
                  const Divider(),
                  if (bill.approximateAmount != null) ...[
                    _Row('المبلغ التقريبي',
                        '${bill.approximateAmount!.toStringAsFixed(0)} جنيه'),
                    const Divider(),
                  ],
                  _Row('التذكير',
                      bill.reminderLeads.map((r) => 'قبل ${r.days} أيام').join(' + ')),
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
          if (bill.serviceType == BillServiceType.electricity) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ElectricityCalculatorSheet.show(context),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('حاسبة شرائح الكهرباء'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => PaymentMethodsSheet.show(context),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('طرق الدفع'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
              ),
              onPressed: () => _showMarkAsPaidDialog(context, bill),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تم السداد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 28),
          _PaymentHistorySection(billId: bill.id),
        ],
      ),
    );
  }
}

Future<void> _showMarkAsPaidDialog(BuildContext context, Bill bill) async {
  HapticFeedback.selectionClick();
  final amountController = TextEditingController(
    text: bill.approximateAmount?.toStringAsFixed(0) ?? '',
  );
  var selectedDate = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('تسجيل السداد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('المبلغ المدفوع فعلياً',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'جنيه',
              ),
            ),
            const SizedBox(height: 16),
            const Text('تاريخ الدفع', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final amount = double.tryParse(amountController.text) ?? 0;
  await context.read<BillProvider>().markAsPaid(
        bill: bill,
        amount: amount,
        paidAt: selectedDate,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل السداد')),
    );
  }
}

class _PaymentHistorySection extends StatelessWidget {
  final String billId;
  const _PaymentHistorySection({required this.billId});

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final payments = billProvider.paymentsForBill(billId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('سجل المدفوعات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('لسه مفيش مدفوعات مسجّلة لهذه الفاتورة',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          )
        else
          ...payments.map((p) => _PaymentTile(payment: p)),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentRecord payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE6F7EC),
          child: Icon(Icons.check_rounded, color: Color(0xFF16A34A)),
        ),
        title: Text('${payment.amount.toStringAsFixed(0)} جنيه',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${payment.paidAt.day}/${payment.paidAt.month}/${payment.paidAt.year}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: () => context.read<BillProvider>().deletePaymentRecord(payment.id),
        ),
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

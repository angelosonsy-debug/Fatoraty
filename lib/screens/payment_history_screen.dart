import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_record.dart';
import '../providers/bill_provider.dart';

const _monthNames = [
  '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final payments = billProvider.allPayments;
    final monthlyTotals = billProvider.monthlyPaymentTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('سجل المصروفات')),
      body: payments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('لسه مفيش مدفوعات مسجّلة',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(
                      'سجّل "تم السداد" في أي فاتورة عشان تبدأ تشوف مصروفاتك هنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in monthlyTotals.entries)
                  _MonthGroup(
                    monthKey: entry.key,
                    total: entry.value,
                    payments: payments
                        .where((p) =>
                            '${p.paidAt.year}-${p.paidAt.month.toString().padLeft(2, '0')}' ==
                            entry.key)
                        .toList(),
                  ),
              ],
            ),
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String monthKey; // "yyyy-MM"
  final double total;
  final List<PaymentRecord> payments;

  const _MonthGroup({
    required this.monthKey,
    required this.total,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    final monthLabel = '${_monthNames[monthIndex]} $year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${total.toStringAsFixed(0)} جنيه',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF16A34A))),
              Text(monthLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ...payments.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(p.billName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.paidAt.day}/${p.paidAt.month}/${p.paidAt.year}'),
                  trailing: Text('${p.amount.toStringAsFixed(0)} جنيه',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }
}

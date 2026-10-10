import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final archived = billProvider.archivedBills;

    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير المؤرشفة')),
      body: archived.isEmpty
          ? Center(
              child: Text('لا توجد فواتير مؤرشفة',
                  style: TextStyle(color: Colors.grey.shade600)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: archived.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bill = archived[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bill.serviceType.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(bill.serviceType.icon,
                          color: bill.serviceType.color),
                    ),
                    title: Text(bill.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('يوم ${bill.dueDayOfMonth} من كل شهر'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore_rounded),
                          tooltip: 'استعادة',
                          onPressed: () =>
                              context.read<BillProvider>().restoreBill(bill.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          tooltip: 'حذف نهائي',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('حذف نهائي؟'),
                              content: Text(
                                  'سيتم حذف "${bill.name}" نهائياً ولا يمكن التراجع.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<BillProvider>()
                                        .deleteBill(bill.id);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('حذف',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

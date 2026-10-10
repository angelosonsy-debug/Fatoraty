import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bill.dart';

class Step1ServiceType extends StatelessWidget {
  final BillServiceType? selected;
  final ValueChanged<BillServiceType> onSelected;

  const Step1ServiceType({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _order = [
    BillServiceType.gas,
    BillServiceType.water,
    BillServiceType.electricity,
    BillServiceType.mobile,
    BillServiceType.landline,
    BillServiceType.internet,
    BillServiceType.subscription,
    BillServiceType.custom,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('اختر نوع الخدمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _order.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final type = _order[index];
              final isSelected = type == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(type);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(type.icon, color: type.color, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(type.label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bill.dart';

class Step2BillKind extends StatelessWidget {
  final BillKind selected;
  final ValueChanged<BillKind> onSelected;

  const Step2BillKind({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('اختر نوع الفاتورة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _KindCard(
                  icon: Icons.credit_card_rounded,
                  label: 'كارت شحن',
                  isSelected: selected == BillKind.prepaidCard,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(BillKind.prepaidCard);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _KindCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'فاتورة شهرية',
                  isSelected: selected == BillKind.monthlyBill,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(BillKind.monthlyBill);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _KindCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? primary : Colors.grey.shade700),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

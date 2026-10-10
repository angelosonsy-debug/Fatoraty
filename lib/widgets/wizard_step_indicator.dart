import 'package:flutter/material.dart';

class WizardStepIndicator extends StatelessWidget {
  final int currentStep; // 1-4
  static const _labels = ['نوع الخدمة', 'نوع الفاتورة', 'البيانات', 'تأكيد'];

  const WizardStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // تُعرض من 4 إلى 1 بترتيب RTL حسب مرجع التصميم
    final stepsDesc = [4, 3, 2, 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stepsDesc.map((step) {
          final isDone = step < currentStep;
          final isActive = step == currentStep;
          final color = (isDone || isActive) ? primary : Colors.grey.shade300;
          final textColor =
              (isDone || isActive) ? primary : Colors.grey.shade400;
          return Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: (isDone || isActive) ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _labels[step - 1],
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

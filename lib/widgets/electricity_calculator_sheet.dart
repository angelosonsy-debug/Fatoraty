import 'package:flutter/material.dart';
import '../utils/electricity_tariff.dart';

/// Bottom sheet لحاسبة شرائح الكهرباء — وضعين:
/// 1) عندي استهلاك بالكيلووات، عايز أعرف التكلفة
/// 2) عندي مبلغ (رصيد كارت)، عايز أعرف هيشتري كام كيلووات تقريباً
class ElectricityCalculatorSheet extends StatefulWidget {
  const ElectricityCalculatorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ElectricityCalculatorSheet(),
    );
  }

  @override
  State<ElectricityCalculatorSheet> createState() =>
      _ElectricityCalculatorSheetState();
}

enum _Mode { kwhToCost, budgetToKwh }

class _ElectricityCalculatorSheetState
    extends State<ElectricityCalculatorSheet> {
  _Mode _mode = _Mode.kwhToCost;
  final _controller = TextEditingController();
  double? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recalculate(String value) {
    final input = double.tryParse(value);
    if (input == null || input <= 0) {
      setState(() => _result = null);
      return;
    }
    setState(() {
      _result = _mode == _Mode.kwhToCost
          ? ElectricityTariff.costForKwh(input)
          : ElectricityTariff.kwhForBudget(input);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text('حاسبة شرائح الكهرباء',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(
                value: _Mode.kwhToCost,
                label: Text('كام هدفع؟'),
              ),
              ButtonSegment(
                value: _Mode.budgetToKwh,
                label: Text('رصيدي هيكفي كام؟'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) {
              setState(() => _mode = s.first);
              _recalculate(_controller.text);
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _recalculate,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _mode == _Mode.kwhToCost
                  ? 'عدد الكيلووات/ساعة المستهلكة'
                  : 'المبلغ المتاح (جنيه)',
              suffixText: _mode == _Mode.kwhToCost ? 'ك.و.س' : 'جنيه',
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _mode == _Mode.kwhToCost
                        ? 'التكلفة التقريبية'
                        : 'عدد الكيلووات التقريبي',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mode == _Mode.kwhToCost
                        ? '${_result!.toStringAsFixed(2)} جنيه'
                        : '${_result!.toStringAsFixed(1)} ك.و.س',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'تقديرية وفق شرائح الاستهلاك المنزلي الرسمية (آخر تحديث: '
            '${ElectricityTariff.lastUpdatedLabel}) — مش بديل عن الفاتورة '
            'الرسمية، والأسعار ممكن تتغيّر بقرار حكومي لاحق. السعر ده لعدادات '
            'الاستهلاك المنزلي العادية، ومش بينطبق على العدادات الكودية '
            'للمباني المخالفة (سعر موحّد مختلف).',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

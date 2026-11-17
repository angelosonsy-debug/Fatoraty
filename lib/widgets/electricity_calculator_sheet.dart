import 'package:material_ui/material_ui.dart';
import '../utils/tiered_tariff.dart';

/// Bottom sheet عامة لحاسبة أي مرفق بنظام شرائح تراكمية (كهرباء/مياه/
/// غاز).
class UtilityCalculatorSheet extends StatefulWidget {
  final TieredTariff tariff;
  final String title;
  final IconData icon;
  final Color iconColor;

  const UtilityCalculatorSheet({
    super.key,
    required this.tariff,
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  static Future<void> show(
    BuildContext context, {
    required TieredTariff tariff,
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UtilityCalculatorSheet(
        tariff: tariff,
        title: title,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  State<UtilityCalculatorSheet> createState() => _UtilityCalculatorSheetState();
}

enum _Mode { unitsToCost, budgetToUnits }

class _UtilityCalculatorSheetState extends State<UtilityCalculatorSheet> {
  _Mode _mode = _Mode.unitsToCost;
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
      _result = _mode == _Mode.unitsToCost
          ? widget.tariff.costForUnits(input)
          : widget.tariff.unitsForBudget(input);
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
              Icon(widget.icon, color: widget.iconColor),
              const SizedBox(width: 8),
              Text(widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(value: _Mode.unitsToCost, label: Text('كام هدفع؟')),
              ButtonSegment(value: _Mode.budgetToUnits, label: Text('رصيدي هيكفي كام؟')),
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
              labelText: _mode == _Mode.unitsToCost
                  ? 'عدد ${widget.tariff.unitLabel} المستهلكة'
                  : 'المبلغ المتاح (جنيه)',
              suffixText: _mode == _Mode.unitsToCost ? null : 'جنيه',
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
                    _mode == _Mode.unitsToCost ? 'التكلفة التقريبية' : 'الكمية التقريبية',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mode == _Mode.unitsToCost
                        ? '${_result!.toStringAsFixed(2)} جنيه'
                        : '${_result!.toStringAsFixed(1)} ${widget.tariff.unitLabel}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'تقديرية وفق الشرائح الرسمية (آخر تحديث: ${widget.tariff.lastUpdatedLabel}) '
            '— مش بديل عن الفاتورة الرسمية، والأسعار ممكن تتغيّر بقرار حكومي لاحق.'
            '${widget.tariff.note != null ? ' ${widget.tariff.note}' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

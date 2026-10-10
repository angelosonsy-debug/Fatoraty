import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bill.dart';

class Step3BillData extends StatefulWidget {
  final String name;
  final int dueDayOfMonth;
  final double? approximateAmount;
  final ReminderLeadTime reminderLead;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onDueDayChanged;
  final ValueChanged<double?> onAmountChanged;
  final ValueChanged<ReminderLeadTime> onReminderChanged;

  /// بيتنادى في كل مرة النص اللي في حقل "يوم السداد" يتغيّر، بغض النظر
  /// عن كونه رقم صالح (1-31) ولا لأ. الهدف: زرار "التالي" يعتمد على
  /// حالة الحقل المعروضة فعلياً على الشاشة، مش بس آخر قيمة صالحة اتحفظت
  /// — لأن المستخدم ممكن يمسح الحقل أو يكتب رقم خارج النطاق، وكان لازم
  /// نمنعه من الاستمرار في الحالة دي بدل ما نستخدم قيمة قديمة بصمت.
  final ValueChanged<bool> onDueDayValidityChanged;

  const Step3BillData({
    super.key,
    required this.name,
    required this.dueDayOfMonth,
    required this.approximateAmount,
    required this.reminderLead,
    required this.onNameChanged,
    required this.onDueDayChanged,
    required this.onAmountChanged,
    required this.onReminderChanged,
    required this.onDueDayValidityChanged,
  });

  @override
  State<Step3BillData> createState() => _Step3BillDataState();
}

class _Step3BillDataState extends State<Step3BillData> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.name);
  late final TextEditingController _dueDayController =
      TextEditingController(text: widget.dueDayOfMonth.toString());
  late final TextEditingController _amountController = TextEditingController(
      text: widget.approximateAmount?.toStringAsFixed(0) ?? '');

  String? _dueDayError;

  @override
  void initState() {
    super.initState();
    // الحقل مُعبّى برقم صالح افتراضياً (widget.dueDayOfMonth)، فالحالة
    // الابتدائية صالحة.
    widget.onDueDayValidityChanged(true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dueDayController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('بيانات الفاتورة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('اسم الفاتورة', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: 20),
          const Text('يوم السداد في الشهر',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _dueDayController,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _dueDayError,
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              final isValid = parsed != null && parsed >= 1 && parsed <= 31;
              setState(() {
                _dueDayError = v.isEmpty
                    ? 'مطلوب'
                    : (isValid ? null : 'لازم يكون رقم من 1 إلى 31');
              });
              widget.onDueDayValidityChanged(isValid);
              if (isValid) {
                widget.onDueDayChanged(parsed);
              }
            },
          ),
          const SizedBox(height: 20),
          const Text('المبلغ التقريبي (اختياري)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'مثال: 200 جنيه',
            ),
            onChanged: (v) => widget.onAmountChanged(double.tryParse(v)),
          ),
          const SizedBox(height: 20),
          const Text('التذكير قبل الموعد بـ',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: ReminderLeadTime.values.map((lead) {
              final isSelected = lead == widget.reminderLead;
              return ChoiceChip(
                label: Text(lead.label),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  widget.onReminderChanged(lead);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bill.dart';

/// دورات مخصّصة/جاهزة للعرض كـ chips في خطوة البيانات.
class _CyclePreset {
  final String label;
  final int? value; // null = مخصص (المستخدم يدخل القيمة بنفسه)
  final BillCycleUnit? unit;
  const _CyclePreset(this.label, this.value, this.unit);
}

const _presets = [
  _CyclePreset('شهري', 1, BillCycleUnit.month),
  _CyclePreset('أسبوعي', 1, BillCycleUnit.week),
  _CyclePreset('ربع سنوي', 3, BillCycleUnit.month),
  _CyclePreset('نصف سنوي', 6, BillCycleUnit.month),
  _CyclePreset('سنوي', 1, BillCycleUnit.year),
  _CyclePreset('مخصص', null, null),
];

class Step3BillData extends StatefulWidget {
  final String name;
  final DateTime anchorDate;
  final int cycleValue;
  final BillCycleUnit cycleUnit;
  final double? approximateAmount;
  final ReminderLeadTime reminderLead;

  final ValueChanged<String> onNameChanged;
  final ValueChanged<double?> onAmountChanged;
  final ValueChanged<ReminderLeadTime> onReminderChanged;

  /// بيتنادى كل ما الدورة (قيمة/وحدة/تاريخ مرجعي) تتغيّر، وكمان بيتنادى
  /// في كل مرة النص اللي في حقل رقمي يتغيّر بغض النظر عن كونه صالح، عشان
  /// الشاشة الأب تقدر تمنع "التالي" لو الإدخال الحالي مش سليم.
  final void Function(int value, BillCycleUnit unit, DateTime anchorDate)
      onCycleChanged;
  final ValueChanged<bool> onCycleValidityChanged;

  const Step3BillData({
    super.key,
    required this.name,
    required this.anchorDate,
    required this.cycleValue,
    required this.cycleUnit,
    required this.approximateAmount,
    required this.reminderLead,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onReminderChanged,
    required this.onCycleChanged,
    required this.onCycleValidityChanged,
  });

  @override
  State<Step3BillData> createState() => _Step3BillDataState();
}

class _Step3BillDataState extends State<Step3BillData> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.name);
  late final TextEditingController _amountController = TextEditingController(
      text: widget.approximateAmount?.toStringAsFixed(0) ?? '');

  // حالة الدورة محلياً جوه الشاشة دي، بتتماشى مع قيم الأب وبترجع ليه عن
  // طريق onCycleChanged كل ما تتغيّر.
  late int _cycleValue = widget.cycleValue;
  late BillCycleUnit _cycleUnit = widget.cycleUnit;
  late DateTime _anchorDate = widget.anchorDate;

  // لحالة "شهري" البسيطة: حقل "يوم الشهر" رقمي زي الأول بالظبط.
  late final TextEditingController _dueDayController = TextEditingController(
      text: (_isSimpleMonthly ? widget.anchorDate.day : 1).toString());
  String? _dueDayError;

  // لحالة "مخصص": قيمة رقمية + وحدة.
  late final TextEditingController _customValueController =
      TextEditingController(
          text: _isPreset ? '' : widget.cycleValue.toString());
  String? _customValueError;

  bool get _isSimpleMonthly =>
      widget.cycleValue == 1 && widget.cycleUnit == BillCycleUnit.month;

  bool get _isPreset =>
      _presets.any((p) => p.value == widget.cycleValue && p.unit == widget.cycleUnit);

  // حالة واجهة صريحة لوضع "مخصص" بدل ما نستنتجها من تطابق القيمة/الوحدة —
  // لو مستخدم كتب قيمة مخصصة بالصدفة بتساوي preset جاهز (مثلاً 3 أشهر =
  // نفس قيمة "ربع سنوي")، منبقاش نقفز نخفي حقول "مخصص" من تحته وهو لسه
  // بيكتب.
  late bool _customSelected = !_isPreset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCycleValidityChanged(true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    _customValueController.dispose();
    super.dispose();
  }

  void _emitCycle() {
    widget.onCycleChanged(_cycleValue, _cycleUnit, _anchorDate);
  }

  void _selectPreset(_CyclePreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      if (preset.value == null) {
        // "مخصص" — سيب القيمة الحالية كبداية لو منطقية، أو 1 افتراضياً
        _customSelected = true;
        if (_cycleValue < 1) _cycleValue = 1;
        _customValueController.text = _cycleValue.toString();
        _customValueError = null;
      } else {
        _customSelected = false;
        _cycleValue = preset.value!;
        _cycleUnit = preset.unit!;
        if (_cycleUnit == BillCycleUnit.month && _cycleValue == 1) {
          // شهري البسيط: لو مفيش يوم محفوظ قبل كده، افتراضي يوم 1
          final day = int.tryParse(_dueDayController.text) ?? 1;
          final now = DateTime.now();
          _anchorDate = DateTime(now.year, now.month, day.clamp(1, 31));
        } else {
          final now = DateTime.now();
          _anchorDate = DateTime(now.year, now.month, now.day);
        }
      }
    });
    widget.onCycleValidityChanged(preset.value != null || _customValueIsValid);
    _emitCycle();
  }

  bool get _customValueIsValid {
    final v = int.tryParse(_customValueController.text);
    return v != null && v >= 1;
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'اختر تاريخ الاستحقاق القادم',
    );
    if (picked != null) {
      setState(() => _anchorDate = DateTime(picked.year, picked.month, picked.day));
      _emitCycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMonthlySimple =
        !_customSelected && _cycleValue == 1 && _cycleUnit == BillCycleUnit.month;

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

          const Text('دورة السداد', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((preset) {
              final isSelected = preset.value == null
                  ? _customSelected
                  : (!_customSelected &&
                      preset.value == _cycleValue &&
                      preset.unit == _cycleUnit);
              return ChoiceChip(
                label: Text(preset.label),
                selected: isSelected,
                onSelected: (_) => _selectPreset(preset),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          if (isMonthlySimple) ...[
            // الحالة الشائعة: فاتورة شهرية — نفس تجربة "يوم السداد في
            // الشهر" البسيطة القديمة، من غير داعي لاختيار تاريخ كامل.
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
                widget.onCycleValidityChanged(isValid);
                if (isValid) {
                  final now = DateTime.now();
                  _anchorDate = DateTime(now.year, now.month, parsed);
                  _emitCycle();
                }
              },
            ),
          ] else if (_customSelected) ...[
            // مخصص: المستخدم بيحدد "كل كام" + الوحدة + تاريخ مرجعي
            const Text('كل', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _customValueController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: _customValueError,
                suffixText: _cycleUnit.unitLabel,
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                final isValid = parsed != null && parsed >= 1;
                setState(() {
                  _customValueError =
                      v.isEmpty ? 'مطلوب' : (isValid ? null : 'رقم غير صالح');
                  if (isValid) _cycleValue = parsed;
                });
                widget.onCycleValidityChanged(isValid);
                if (isValid) _emitCycle();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: BillCycleUnit.values.map((u) {
                final isSelected = u == _cycleUnit;
                return ChoiceChip(
                  label: Text(u.unitLabel),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _cycleUnit = u);
                    _emitCycle();
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _AnchorDateField(date: _anchorDate, onTap: _pickAnchorDate),
          ] else ...[
            // أسبوعي / ربع سنوي / نصف سنوي / سنوي: نحتاج تاريخ استحقاق
            // حقيقي كمرجع (مش مجرد "يوم في الشهر") عشان الدورة تتحسب صح.
            _AnchorDateField(date: _anchorDate, onTap: _pickAnchorDate),
          ],

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

class _AnchorDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _AnchorDateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('تاريخ الاستحقاق القادم',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.calendar_month_rounded,
                    color: Colors.grey.shade600, size: 20),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

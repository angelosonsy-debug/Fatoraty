import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/bill.dart';
import '../../providers/bill_provider.dart';
import '../../widgets/wizard_step_indicator.dart';
import 'step1_service_type.dart';
import 'step2_bill_kind.dart';
import 'step3_bill_data.dart';
import 'step4_confirmation.dart';

class AddBillWizardScreen extends StatefulWidget {
  const AddBillWizardScreen({super.key});

  @override
  State<AddBillWizardScreen> createState() => _AddBillWizardScreenState();
}

class _AddBillWizardScreenState extends State<AddBillWizardScreen> {
  int _step = 1;
  bool _isSaving = false;

  BillServiceType? serviceType;
  BillKind kind = BillKind.monthlyBill;
  String name = '';

  // دورة السداد — تحل محل dueDayOfMonth القديمة، وبتدعم أي دورة (مش بس
  // شهري): anchorDate هو أول/أقرب تاريخ استحقاق معروف، وcycleValue +
  // cycleUnit بيحددوا كل كام وحدة بتتكرر الفاتورة.
  DateTime anchorDate = DateTime.now();
  int cycleValue = 1;
  BillCycleUnit cycleUnit = BillCycleUnit.month;

  double? approximateAmount;
  List<ReminderLeadTime> reminderLeads = [ReminderLeadTime.twoDays];
  bool _cycleFieldValid = true;

  bool get _canGoNext {
    switch (_step) {
      case 1:
        return serviceType != null;
      case 2:
        return true;
      case 3:
        // بنتأكد من حالة الحقل المعروضة فعلياً (_cycleFieldValid)، مش بس
        // آخر قيمة صالحة اتحفظت — عشان لو المستخدم مسح الحقل أو كتب رقم
        // خارج النطاق، منسمحوش نكمل بقيمة قديمة من غير ما هو يلاحظ.
        return name.trim().isNotEmpty && _cycleFieldValid && cycleValue >= 1;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canGoNext) return;
    HapticFeedback.selectionClick();
    if (_step < 4) {
      setState(() => _step++);
    }
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    // حماية من الضغط المتكرر السريع على الزر — كان ممكن يعمل أكتر من
    // فاتورة مكررة لنفس البيانات لو المستخدم ضغط تاني قبل ما الأول يخلص.
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<BillProvider>().addBill(
            name: name.trim(),
            serviceType: serviceType!,
            kind: kind,
            anchorDate: anchorDate,
            cycleValue: cycleValue,
            cycleUnit: cycleUnit,
            approximateAmount: approximateAmount,
            reminderLeads: reminderLeads,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onServiceSelected(BillServiceType type) {
    setState(() {
      final wasDefault = serviceType == null;
      serviceType = type;
      if (name.isEmpty) name = type.label;
      // نقترح دورة سداد مناسبة لنوع الخدمة (مثلاً خط أرضي = ربع سنوي
      // افتراضياً في مصر)، بس بس لو المستخدم لسه ما لمسش الدورة بنفسه —
      // عشان لو رجع لخطوة 1 وغيّر النوع بعد ما عدّل الدورة يدوياً في
      // خطوة 3، متغيّرش قيمته من تحته.
      if (wasDefault || _cycleUntouched) {
        final preset = type.defaultCyclePreset;
        cycleValue = preset.value;
        cycleUnit = preset.unit;
        final now = DateTime.now();
        anchorDate = preset.matches(1, BillCycleUnit.month)
            ? DateTime(now.year, now.month, 1) // نفس الافتراضي القديم (يوم 1)
            : DateTime(now.year, now.month, now.day);
      }
    });
  }

  // بيتسجل true بس أول مرة؛ بمجرد ما المستخدم يلمس أي عنصر في اختيار
  // الدورة بنفسه في خطوة 3، بيبقى false ومنغيّرش الاقتراح التلقائي بعد كده.
  bool _cycleUntouched = true;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة فاتورة جديدة'),
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Column(
          children: [
            WizardStepIndicator(currentStep: _step),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildStep(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: _step == 4
              ? ElevatedButton.icon(
                  key: const ValueKey('save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text(
                    'حفظ وتفعيل التذكير',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
              : ElevatedButton.icon(
                  key: const ValueKey('next'),
                  onPressed: _canGoNext ? _next : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text(
                    'التالي',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return Step1ServiceType(
          key: const ValueKey('step1'),
          selected: serviceType,
          onSelected: _onServiceSelected,
        );
      case 2:
        return Step2BillKind(
          key: const ValueKey('step2'),
          selected: kind,
          onSelected: (k) => setState(() => kind = k),
        );
      case 3:
        return Step3BillData(
          key: const ValueKey('step3'),
          name: name,
          serviceType: serviceType,
          anchorDate: anchorDate,
          cycleValue: cycleValue,
          cycleUnit: cycleUnit,
          approximateAmount: approximateAmount,
          reminderLeads: reminderLeads,
          onNameChanged: (v) => setState(() => name = v),
          onAmountChanged: (v) => setState(() => approximateAmount = v),
          onRemindersChanged: (v) => setState(() => reminderLeads = v),
          onCycleChanged: (value, unit, anchor) => setState(() {
            _cycleUntouched = false;
            cycleValue = value;
            cycleUnit = unit;
            anchorDate = anchor;
          }),
          onCycleValidityChanged: (v) =>
              setState(() => _cycleFieldValid = v),
        );
      case 4:
        return Step4Confirmation(
          key: const ValueKey('step4'),
          name: name,
          serviceType: serviceType!,
          kind: kind,
          anchorDate: anchorDate,
          cycleValue: cycleValue,
          cycleUnit: cycleUnit,
          reminderLeads: reminderLeads,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

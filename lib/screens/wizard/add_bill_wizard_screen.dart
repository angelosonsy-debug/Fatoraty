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
  int dueDayOfMonth = 1;
  double? approximateAmount;
  ReminderLeadTime reminderLead = ReminderLeadTime.twoDays;
  bool _dueDayFieldValid = true;

  bool get _canGoNext {
    switch (_step) {
      case 1:
        return serviceType != null;
      case 2:
        return true;
      case 3:
        // بنتأكد من حالة الحقل المعروضة فعلياً (_dueDayFieldValid)، مش بس
        // آخر قيمة صالحة اتحفظت — عشان لو المستخدم مسح الحقل أو كتب رقم
        // خارج النطاق، منسمحوش نكمل بقيمة قديمة من غير ما هو يلاحظ.
        return name.trim().isNotEmpty &&
            _dueDayFieldValid &&
            dueDayOfMonth >= 1 &&
            dueDayOfMonth <= 31;
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
            dueDayOfMonth: dueDayOfMonth,
            approximateAmount: approximateAmount,
            reminderLead: reminderLead,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onServiceSelected(BillServiceType type) {
    setState(() {
      serviceType = type;
      if (name.isEmpty) name = type.label;
    });
  }

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
          dueDayOfMonth: dueDayOfMonth,
          approximateAmount: approximateAmount,
          reminderLead: reminderLead,
          onNameChanged: (v) => setState(() => name = v),
          onDueDayChanged: (v) => setState(() => dueDayOfMonth = v),
          onAmountChanged: (v) => setState(() => approximateAmount = v),
          onReminderChanged: (v) => setState(() => reminderLead = v),
          onDueDayValidityChanged: (v) =>
              setState(() => _dueDayFieldValid = v),
        );
      case 4:
        return Step4Confirmation(
          key: const ValueKey('step4'),
          name: name,
          serviceType: serviceType!,
          kind: kind,
          dueDayOfMonth: dueDayOfMonth,
          reminderLead: reminderLead,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

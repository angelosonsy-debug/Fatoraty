import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../providers/premium_provider.dart';
import '../utils/reminder_calculator.dart';
import 'settings_screen.dart';
import 'wizard/add_bill_wizard_screen.dart';
import 'bill_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// لما تتفتح أول مرة بعد الـ Onboarding، نفتح معالج إضافة الفاتورة
  /// تلقائياً فوق الشاشة الرئيسية. ملاحظة مهمة: ده متعمّد إنه يتحط هنا
  /// جوه Dashboard نفسها (مش في onboarding_screen عن طريق انتظار نتيجة
  /// Navigator.pushReplacement) لأن الـ Future اللي pushReplacement
  /// بيرجّعها بتكتمل بس لما الـ route الجديد (Dashboard) يتـ"pop"، مش
  /// لما يخلص الانتقال — وبما إن Dashboard بقت الشاشة الرئيسية ومفيش حد
  /// هيعمل pop ليها في الاستخدام العادي، كان أي كود بعد الـ await ده
  /// مستحيل ينفّذ خالص (عالق للأبد).
  final bool openWizardOnLaunch;

  /// لو التطبيق اتفتح من الصفر (cold start) بسبب ضغط على إشعار، بنفتح
  /// تفاصيل الفاتورة دي تلقائياً فوق الشاشة الرئيسية — نفس فكرة
  /// openWizardOnLaunch بالظبط ونفس السبب (post-frame، مش await على
  /// pushReplacement).
  final String? initialBillId;

  const DashboardScreen({
    super.key,
    this.openWizardOnLaunch = false,
    this.initialBillId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.openWizardOnLaunch) {
      // نفتح المعالج بعد أول frame عشان نضمن إن الـ Dashboard نفسها
      // خلصت بناء وظهرت على الشاشة الأول.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBillWizardScreen()),
          );
        }
      });
    } else if (widget.initialBillId != null &&
        widget.initialBillId!.isNotEmpty) {
      final billId = widget.initialBillId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BillDetailsScreen(billId: billId),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [_BillsTab(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'فواتيري',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class _BillsTab extends StatelessWidget {
  const _BillsTab();

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();

    if (!billProvider.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeBills = billProvider.activeBills;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.credit_card_rounded),
            SizedBox(width: 8),
            Text('فاتورتي'),
          ],
        ),
      ),
      body: SafeArea(
        child: activeBills.isEmpty
            ? _EmptyState(billProvider: billProvider)
            : _BillsList(bills: activeBills, billProvider: billProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddBill(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

Future<void> _handleAddBill(BuildContext context) async {
  HapticFeedback.selectionClick();
  final billProvider = context.read<BillProvider>();
  final premium = context.read<PremiumProvider>();

  if (!premium.canAddBill(billProvider.activeBills.length)) {
    _showPremiumModal(context);
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AddBillWizardScreen()),
  );
}

void _showPremiumModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('وصلت لحد النسخة المجانية'),
      content: const Text(
        'النسخة المجانية تتيح 4 فواتير. اشترك في Premium لإضافة عدد غير محدود.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            // TODO: استدعاء Rewarded Ad حقيقي من AdMob، وعند اكتمال المشاهدة
            // نادِ premium.grantBonusSlot()
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('إعلانات المكافأة ستُفعّل قريباً (TODO)'),
              ),
            );
          },
          child: const Text('شاهد إعلاناً لإضافة فاتورة إضافية مؤقتاً'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: استدعاء Google Play Billing Flow (Subscription)
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الاشتراك سيُفعّل قريباً (TODO)')),
            );
          },
          child: const Text('اشترك الآن'),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final BillProvider billProvider;
  const _EmptyState({required this.billProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(billProvider: billProvider),
            const SizedBox(height: 64),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 48, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('لا توجد فواتير بعد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'أضف أول فاتورة وابدأ في تتبع مواعيد السداد',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleAddBill(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف فاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillsList extends StatelessWidget {
  final List<Bill> bills;
  final BillProvider billProvider;
  const _BillsList({required this.bills, required this.billProvider});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _SummaryRow(billProvider: billProvider),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final bill = bills[index];
                return _BillCard(bill: bill);
              },
              childCount: bills.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final BillProvider billProvider;
  const _SummaryRow({required this.billProvider});

  @override
  Widget build(BuildContext context) {
    final dueSoon = billProvider.dueSoonCount();
    final total = billProvider.approximateMonthlyTotal;
    final activeCount = billProvider.activeBills.length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFE8EEFC),
            value: '$dueSoon',
            label: 'تستحق قريباً',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFE6F7EC),
            value: '${total.toStringAsFixed(0)} ج',
            label: 'هذا الشهر',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFE8EEFC),
            value: '$activeCount',
            label: 'الفواتير النشطة',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final daysLeft = ReminderCalculator.daysUntilDue(
        bill.dueDayOfMonth, DateTime.now());
    final isSoon = daysLeft <= bill.reminderLead.days;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillDetailsScreen(billId: bill.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bill.serviceType.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(bill.serviceType.icon,
                    color: bill.serviceType.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('يوم ${bill.dueDayOfMonth} من كل شهر',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bill.approximateAmount != null)
                    Text('${bill.approximateAmount!.toStringAsFixed(0)} ج',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (isSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysLeft <= 0 ? 'اليوم' : 'بعد $daysLeft أيام',
                        style: const TextStyle(
                            color: Color(0xFFEA580C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

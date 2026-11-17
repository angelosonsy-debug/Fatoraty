import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/bill.dart';
import '../utils/app_launcher.dart';

/// طرق دفع عامة متاحة في مصر — زرارين فعليين بس: تطبيق myFawry الرسمي
/// وتطبيق إنستاباي، وكل واحد منهم:
///  - بيفتح التطبيق نفسه لو متثبّت على الجهاز ("فتح")،
///  - أو بيوديك لصفحته على Google Play علشان تحمّله لو مش متثبّت —
///    نفس الزرار، مفيش فرق في الشكل، بس السلوك بيتغيّر حسب حالة الجهاز.
/// شلنا رابط موقع فوري نهائياً بناءً على طلب صريح: التطبيقين كافيين.
///
/// لو الفاتورة ليها رقم مرجعي (عداد/كارت/هاتف/واي فاي)، بننسخه تلقائياً
/// للـ clipboard أول ما تتفتح التطبيقات دي، عشان يبقى جاهز للصق مباشرة
/// في خانة الدفع — بدل ما المستخدم يرجع يدوّر عليه في التطبيق أو
/// الفاتورة الورقية.
class PaymentMethodsSheet extends StatelessWidget {
  final String? referenceNumber;
  final String? referenceLabel;
  final BillServiceType? serviceType;
  final BillKind? kind;

  const PaymentMethodsSheet({
    super.key,
    this.referenceNumber,
    this.referenceLabel,
    this.serviceType,
    this.kind,
  });

  static Future<void> show(
    BuildContext context, {
    String? referenceNumber,
    String? referenceLabel,
    BillServiceType? serviceType,
    BillKind? kind,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaymentMethodsSheet(
        referenceNumber: referenceNumber,
        referenceLabel: referenceLabel,
        serviceType: serviceType,
        kind: kind,
      ),
    );
  }

  bool get _hasReference =>
      referenceNumber != null && referenceNumber!.trim().isNotEmpty;

  String get _guidanceText {
    if (!_hasReference) {
      return 'فاتورتي بيفكّرك بس — السداد بيتم من برا التطبيق عن طريق أي '
          'من الطرق دي.';
    }
    final label = referenceLabel ?? 'الرقم المطلوب';
    if (kind == BillKind.prepaidCard) {
      return 'هننسخلك $label تلقائي — افتح فوري أو إنستاباي وألصقه في '
          'خانة شحن الكارت.';
    }
    switch (serviceType) {
      case BillServiceType.mobile:
      case BillServiceType.landline:
        return 'هننسخلك رقم الهاتف تلقائي — افتح فوري أو إنستاباي وألصقه '
            'في خانة شحن الرصيد أو الباقة.';
      case BillServiceType.internet:
        return 'هننسخلك $label تلقائي — افتح فوري أو إنستاباي وألصقه في '
            'خانة دفع فاتورة الإنترنت.';
      default:
        return 'هننسخلك $label تلقائي — افتح فوري أو إنستاباي وألصقه في '
            'خانة رقم العداد.';
    }
  }

  Future<void> _openApp(
    BuildContext context, {
    required String packageName,
    required String appLabel,
  }) async {
    HapticFeedback.selectionClick();
    if (_hasReference) {
      await Clipboard.setData(ClipboardData(text: referenceNumber!));
    }
    final opened = await AppLauncher.openOrGoToStore(packageName);
    if (!context.mounted) return;
    final message = !opened
        ? '$appLabel مش متثبّت — بنوديك لصفحته على Google Play'
        : (_hasReference
            ? 'تم نسخ ${referenceLabel ?? "الرقم"} — الصقه في $appLabel'
            : 'بنفتح $appLabel');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          const Text('طرق الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _guidanceText,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (_hasReference) ...[
            const SizedBox(height: 16),
            ReferenceNumberBanner(
              label: referenceLabel ?? 'الرقم المرجعي',
              value: referenceNumber!,
            ),
          ],
          const SizedBox(height: 20),
          _PaymentAppTile(
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF4E5),
            icon: Icons.payments_outlined,
            title: 'تطبيق myFawry',
            subtitle: 'ادفع الفاتورة من تطبيق فوري الرسمي',
            onPressed: () => _openApp(
              context,
              packageName: 'com.fawry.myfawry',
              appLabel: 'myFawry',
            ),
          ),
          const SizedBox(height: 10),
          _PaymentAppTile(
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF1E8FD),
            icon: Icons.account_balance_wallet_rounded,
            title: 'إنستاباي InstaPay',
            subtitle: 'حوّالة فورية من حسابك البنكي لسداد الفاتورة',
            onPressed: () => _openApp(
              context,
              packageName: 'com.egyptianbanks.instapay',
              appLabel: 'إنستاباي',
            ),
          ),
          const SizedBox(height: 16),
          const _InfoTile(
            icon: Icons.phone_android_rounded,
            title: 'محافظ الموبايل',
            text: 'فودافون كاش، أورانج كاش، اتصالات كاش، WE Pay — من تطبيق '
                'المحفظة بتاعتك مباشرة أو بكود USSD.',
          ),
          const SizedBox(height: 10),
          const _InfoTile(
            icon: Icons.account_balance_rounded,
            title: 'تطبيق البنك',
            text: 'أغلب البنوك المصرية بتتيح دفع الفواتير من تطبيق الموبايل بانكينج.',
          ),
          const SizedBox(height: 10),
          const _InfoTile(
            icon: Icons.local_post_office_outlined,
            title: 'مكتب البريد',
            text: 'سداد نقدي مباشر من أي فرع بريد مصر.',
          ),
        ],
      ),
    );
  }
}

/// عرض الرقم المرجعي (عداد/كارت/هاتف/واي فاي) بشكل واضح وكبير، متقسّم
/// لمجموعات زي الكروت البنكية عشان يبقى أسهل في القراءة والمراجعة قبل
/// النسخ — مش مجرد سطر نص عادي. ده التحسين المطلوب لطريقة عرض/نسخ رقم
/// الكارت تحديداً.
class ReferenceNumberBanner extends StatelessWidget {
  final String label;
  final String value;
  const ReferenceNumberBanner({super.key, required this.label, required this.value});

  String get _grouped {
    final digitsOnly = RegExp(r'^[0-9]+$').hasMatch(value);
    if (!digitsOnly || value.length < 5) return value;
    final groups = <String>[];
    for (var i = 0; i < value.length; i += 4) {
      groups.add(value.substring(i, (i + 4).clamp(0, value.length)));
    }
    return groups.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'نسخ',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  _grouped,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentAppTile extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _PaymentAppTile({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: FilledButton(
          onPressed: onPressed,
          child: const Text('فتح'),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoTile({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

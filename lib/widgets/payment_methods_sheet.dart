import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// طرق دفع عامة متاحة في مصر — زرار فعلي بس لفوري (رابط موقعهم الرسمي
/// الموثّق)، والباقي (محافظ موبايل، تطبيقات بنوك، مكتب البريد) نص
/// إرشادي بس، مش روابط مباشرة. السبب: معنديش طريقة أتأكد من صحة روابط
/// deep link لتطبيقات المحافظ (Vodafone Cash، Orange Cash، إلخ) من غير
/// بيئة اختبار حقيقية، وزرار "بيفتح حاجة" ومبيشتغلش أسوأ من مفيش زرار
/// خالص.
class PaymentMethodsSheet extends StatelessWidget {
  const PaymentMethodsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PaymentMethodsSheet(),
    );
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
            'فاتورتي بيفكّرك بس — السداد بيتم من برا التطبيق عن طريق أي من الطرق دي',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Color(0xFFF59E0B)),
              ),
              title: const Text('فوري', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('من الموقع، التطبيق، أو أي منفذ فوري قريب منك'),
              trailing: FilledButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://www.fawry.com')),
                child: const Text('الموقع'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_outlined,
                    color: Color(0xFF2563EB)),
              ),
              title: const Text('تطبيق myFawry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('التطبيق الرسمي لفوري على Google Play'),
              trailing: OutlinedButton(
                onPressed: () => launchUrl(Uri.parse(
                    'https://play.google.com/store/search?q=myFawry&c=apps')),
                child: const Text('تحميل'),
              ),
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

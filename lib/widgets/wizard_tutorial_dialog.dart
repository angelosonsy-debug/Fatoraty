import 'package:material_ui/material_ui.dart';

/// دليل مبسط جداً بيظهر أول مرة بس المستخدم يفتح معالج إضافة فاتورة —
/// شرح سريع للـ 4 خطوات قبل ما يبدأ فعلياً، عشان محدش يتوه.
class WizardTutorialDialog extends StatelessWidget {
  const WizardTutorialDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    // بيتنادى من دوال فحص الـ storage خارجياً (راجع add_bill_wizard_screen)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WizardTutorialDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 32, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'هنضيف أول فاتورة في 4 خطوات بسيطة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const _TutorialStep(
              emoji: '1️⃣',
              text: 'اختار نوع الخدمة — كهرباء، مياه، إنترنت، إلخ',
            ),
            const SizedBox(height: 12),
            const _TutorialStep(
              emoji: '2️⃣',
              text: 'هل هي كارت شحن ولا فاتورة شهرية؟',
            ),
            const SizedBox(height: 12),
            const _TutorialStep(
              emoji: '3️⃣',
              text: 'حدد موعد السداد والمبلغ التقريبي (اختياري)',
            ),
            const SizedBox(height: 12),
            const _TutorialStep(
              emoji: '4️⃣',
              text: 'أكّد — وخلاص، هنفكّرك تلقائي قبل الموعد',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('تمام، يلا نبدأ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final String emoji;
  final String text;
  const _TutorialStep({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ),
      ],
    );
  }
}

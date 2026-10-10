import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _start(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final storage = StorageService();
    await storage.setOnboardingDone();

    // اطلب صلاحية الإشعارات (Android 13+) مباشرة بعد الـ Onboarding
    await NotificationService.instance.requestPermission();

    if (!context.mounted) return;
    // ملاحظة: متستناش نتيجة pushReplacement هنا — الـ Future بتاعها
    // بتكتمل بس لما Dashboard نفسها تتـ"pop"، مش لما تظهر على الشاشة.
    // فتح الـ Wizard تلقائياً بقى مسؤولية Dashboard نفسها (openWizardOnLaunch)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(openWizardOnLaunch: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFBFD7F5), Color(0xFF12141C)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long_rounded,
                      size: 120, color: Colors.white70),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'فاتورتي',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'لا تنسى فاتورة تاني',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4C8DFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تذكير تلقائي بمواعيد سداد الكهرباء والمياه والغاز '
                      'والإنترنت — قبل ما الخدمة تتقطع.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    const _FeatureRow(
                      icon: Icons.bolt_rounded,
                      iconColor: Color(0xFFF5A623),
                      text: 'حساب رصيد كارت الكهرباء بالشرائح',
                    ),
                    const SizedBox(height: 14),
                    const _FeatureRow(
                      icon: Icons.notifications_active_rounded,
                      iconColor: Color(0xFF4C8DFF),
                      text: 'تنبيه قبل الموعد بأيام',
                    ),
                    const SizedBox(height: 14),
                    const _FeatureRow(
                      icon: Icons.smartphone_rounded,
                      iconColor: Color(0xFF22C55E),
                      text: 'بيانات محلية — بدون إنترنت',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _start(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(
                          'أضف أول فاتورة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'مجاني حتى 4 فواتير — بدون تسجيل',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _FeatureRow(
      {required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

import '../providers/bill_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'archive_screen.dart';

// TODO: استبدل برابط صفحة التطبيق الحقيقي على Google Play بعد النشر
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.angelosonsy.fatorty';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final premium = context.watch<PremiumProvider>();
    final billProvider = context.watch<BillProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final usedCount = billProvider.activeBills.length;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة حالة النسخة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (premium.isPremium)
                        const _Badge(text: 'Pro', color: Color(0xFF16A34A))
                      else
                        _Badge(
                            text: 'مجاني',
                            color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      Text(
                        premium.isPremium ? 'نسخة Pro' : 'النسخة المجانية',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (!premium.isPremium) ...[
                    const SizedBox(height: 12),
                    Text('$usedCount / ${premium.currentLimit} فواتير مستخدمة',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (usedCount / premium.currentLimit).clamp(0, 1),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // المظهر
          const _SectionTitle('المظهر'),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeProvider.mode,
              onChanged: (m) => themeProvider.setMode(m!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('تلقائي (حسب النظام)'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('فاتح'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('داكن'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // الإشعارات
          const _SectionTitle('الإشعارات'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded),
                  title: const Text('تفعيل التذكيرات'),
                  value: settings.notificationsEnabled,
                  onChanged: (v) async {
                    await settings.setNotificationsEnabled(v);
                    if (context.mounted) {
                      await context.read<BillProvider>().load();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: const Text('وقت الإشعار'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settings.notificationTime,
                      );
                      if (picked != null) {
                        await settings.setNotificationTime(picked);
                        if (context.mounted) {
                          await context.read<BillProvider>().load();
                        }
                      }
                    },
                    child: Text(
                      settings.notificationTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // البيانات
          const _SectionTitle('البيانات'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('الفواتير المؤرشفة'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('تصدير البيانات'),
                  trailing: _Badge(
                      text: 'Pro', color: Theme.of(context).colorScheme.primary),
                  onTap: () {
                    if (!premium.isPremium) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تصدير البيانات متاح لمشتركي Pro')),
                      );
                      return;
                    }
                    // TODO: نفّذ تصدير CSV/JSON فعلي هنا (متاح فقط لمشتركي Pro)
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // عن التطبيق
          const _SectionTitle('عن التطبيق'),
          Card(
            child: Column(
              children: [
                const _VersionTile(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_border_rounded),
                  title: const Text('قيّم التطبيق'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    } else {
                      launchUrl(Uri.parse(kPlayStoreUrl));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('شارك التطبيق'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Share.share(
                    'جرّب فاتورتي — تطبيق تذكير بمواعيد سداد الفواتير: $kPlayStoreUrl',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TODO: فعّل Banner Ad حقيقي هنا بعد توفر AdMob Ad Unit ID
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('إعلان', style: TextStyle(color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'فاتورتي 🇪🇬 — متنساش فاتورة تاني',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        return ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('الإصدار'),
          trailing: Text(version, style: TextStyle(color: Colors.grey.shade600)),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

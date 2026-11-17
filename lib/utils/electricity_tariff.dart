import 'tiered_tariff.dart';

/// *** آخر تحديث: أغسطس 2026 *** — جهاز تنظيم مرفق الكهرباء وحماية
/// المستهلك. الأسعار بتتغيّر بقرارات حكومية دورية — لو حابب تحدّث
/// الأرقام لاحقاً، غيّر القيم في [tariff.tiers] بس.
class ElectricityTariff {
  ElectricityTariff._();

  static const tariff = TieredTariff(
    lastUpdatedLabel: 'أغسطس 2026',
    unitLabel: 'كيلووات/ساعة',
    tiers: [
      TariffTier(from: 0, to: 50, price: 0.68),
      TariffTier(from: 51, to: 100, price: 0.87),
      TariffTier(from: 101, to: 200, price: 1.06),
      TariffTier(from: 201, to: 350, price: 1.74),
      TariffTier(from: 351, to: 650, price: 2.18),
      TariffTier(from: 651, to: 1000, price: 2.35),
      TariffTier(from: 1001, to: null, price: 2.89),
    ],
    note: 'للعدادات المنزلية العادية (القانونية)، مش للعدادات الكودية '
        'للمباني المخالفة (سعر موحّد مختلف).',
  );
}

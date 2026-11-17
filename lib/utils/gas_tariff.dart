import 'tiered_tariff.dart';

/// *** آخر تحديث: أكتوبر 2026 *** — للمنازل الموصولة بشبكة الغاز
/// الطبيعي الرسمية، مش لأسطوانات البوتاجاز.
class GasTariff {
  GasTariff._();

  static const tariff = TieredTariff(
    lastUpdatedLabel: 'أكتوبر 2026',
    unitLabel: 'متر مكعب',
    tiers: [
      TariffTier(from: 0, to: 30, price: 4.0),
      TariffTier(from: 31, to: 60, price: 5.0),
      TariffTier(from: 61, to: null, price: 6.0),
    ],
    note: 'للمنازل الموصولة بشبكة الغاز الطبيعي الرسمية — مش لأسطوانات '
        'البوتاجاز.',
  );
}

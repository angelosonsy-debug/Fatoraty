import 'tiered_tariff.dart';

/// *** آخر تحديث: يونيو 2026 *** — ملاحظة: الفاتورة الرسمية بتضيف رسم
/// صرف صحي عادةً (~80% من قيمة الاستهلاك) فوق قيمة المياه نفسها.
class WaterTariff {
  WaterTariff._();

  static const tariff = TieredTariff(
    lastUpdatedLabel: 'يونيو 2026',
    unitLabel: 'متر مكعب',
    tiers: [
      TariffTier(from: 0, to: 10, price: 2.0),
      TariffTier(from: 11, to: 20, price: 3.0),
      TariffTier(from: 21, to: 30, price: 4.0),
      TariffTier(from: 31, to: null, price: 4.5),
    ],
    note: 'الرقم ده قيمة استهلاك المياه بس — الفاتورة الرسمية بتضيف '
        'عادةً رسم صرف صحي (~80% من قيمة الاستهلاك) فوق الرقم ده.',
  );
}

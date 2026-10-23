/// شريحة واحدة من شرائح استهلاك الكهرباء المنزلي
class ElectricityTier {
  final int from; // أول كيلووات في الشريحة (شامل)
  final int? to; // آخر كيلووات في الشريحة (شامل)؛ null = بلا حد أعلى
  final double pricePerKwh; // جنيه للكيلووات/ساعة

  const ElectricityTier({required this.from, this.to, required this.pricePerKwh});

  int get size => (to == null) ? -1 : (to! - from + 1);
}

/// شرائح استهلاك الكهرباء المنزلي في مصر — نظام تراكمي (progressive):
/// كل شريحة بتتحاسب بسعرها على الجزء اللي بداخلها بس، مش على إجمالي
/// الاستهلاك بسعر أعلى شريحة.
///
/// *** آخر تحديث: أغسطس 2026 ***
/// المصدر: قرار جهاز تنظيم مرفق الكهرباء وحماية المستهلك (زيادة 12% على
/// معظم الشرائح ما عدا الأولى، سارية من فاتورة أغسطس 2026 اللي بتعكس
/// استهلاك يوليو). الأسعار دي بتتغيّر بقرارات حكومية دورية — الحاسبة دي
/// تقديرية ومش بديل عن الفاتورة الرسمية. لو حابب تحدّث الأرقام لاحقاً،
/// غيّر القيم في [tiers] بس.
class ElectricityTariff {
  ElectricityTariff._();

  static const String lastUpdatedLabel = 'أغسطس 2026';

  static const List<ElectricityTier> tiers = [
    ElectricityTier(from: 0, to: 50, pricePerKwh: 0.68),
    ElectricityTier(from: 51, to: 100, pricePerKwh: 0.87),
    ElectricityTier(from: 101, to: 200, pricePerKwh: 1.06),
    ElectricityTier(from: 201, to: 350, pricePerKwh: 1.74),
    ElectricityTier(from: 351, to: 650, pricePerKwh: 2.18),
    ElectricityTier(from: 651, to: 1000, pricePerKwh: 2.35),
    ElectricityTier(from: 1001, to: null, pricePerKwh: 2.89),
  ];

  /// التكلفة الإجمالية لاستهلاك [kwh] كيلووات/ساعة، محسوبة تراكمياً عبر
  /// كل الشرائح.
  static double costForKwh(double kwh) {
    if (kwh <= 0) return 0;
    var remaining = kwh;
    var total = 0.0;
    for (final tier in tiers) {
      final tierSize = tier.size == -1 ? remaining : tier.size.toDouble();
      final usedInTier = remaining < tierSize ? remaining : tierSize;
      if (usedInTier <= 0) continue;
      total += usedInTier * tier.pricePerKwh;
      remaining -= usedInTier;
      if (remaining <= 0) break;
    }
    return total;
  }

  /// تقدير عدد الكيلووات اللي ميزانية [budget] جنيه ممكن تغطيها — مفيد
  /// لسؤال "رصيد الكارت ده هيكفيني كام كيلو؟". حساب تراكمي عكسي (بيملى
  /// كل شريحة بالترتيب لحد ما الميزانية تخلص)، مش قسمة بسيطة.
  static double kwhForBudget(double budget) {
    if (budget <= 0) return 0;
    var remainingBudget = budget;
    var totalKwh = 0.0;
    for (final tier in tiers) {
      if (tier.size == -1) {
        // آخر شريحة بلا حد أعلى — الباقي كله بيتغطى منها
        totalKwh += remainingBudget / tier.pricePerKwh;
        remainingBudget = 0;
        break;
      }
      final tierCost = tier.size * tier.pricePerKwh;
      if (remainingBudget <= tierCost) {
        totalKwh += remainingBudget / tier.pricePerKwh;
        remainingBudget = 0;
        break;
      } else {
        totalKwh += tier.size;
        remainingBudget -= tierCost;
      }
    }
    return totalKwh;
  }
}

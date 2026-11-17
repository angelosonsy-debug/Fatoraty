/// محرك عام لحساب فواتير الشرائح التراكمية (كهرباء/مياه/غاز) — منطق
/// واحد مشترك بدل تكرار نفس الحساب 3 مرات لكل مرفق.
class TariffTier {
  final int from;
  final int? to;
  final double price;

  const TariffTier({required this.from, this.to, required this.price});

  int get size => (to == null) ? -1 : (to! - from + 1);
}

class TieredTariff {
  final String lastUpdatedLabel;
  final String unitLabel;
  final List<TariffTier> tiers;
  final String? note;

  const TieredTariff({
    required this.lastUpdatedLabel,
    required this.unitLabel,
    required this.tiers,
    this.note,
  });

  double costForUnits(double units) {
    if (units <= 0) return 0;
    var remaining = units;
    var total = 0.0;
    for (final tier in tiers) {
      final tierSize = tier.size == -1 ? remaining : tier.size.toDouble();
      final usedInTier = remaining < tierSize ? remaining : tierSize;
      if (usedInTier <= 0) continue;
      total += usedInTier * tier.price;
      remaining -= usedInTier;
      if (remaining <= 0) break;
    }
    return total;
  }

  double unitsForBudget(double budget) {
    if (budget <= 0) return 0;
    var remainingBudget = budget;
    var totalUnits = 0.0;
    for (final tier in tiers) {
      if (tier.size == -1) {
        totalUnits += remainingBudget / tier.price;
        remainingBudget = 0;
        break;
      }
      final tierCost = tier.size * tier.price;
      if (remainingBudget <= tierCost) {
        totalUnits += remainingBudget / tier.price;
        remainingBudget = 0;
        break;
      } else {
        totalUnits += tier.size;
        remainingBudget -= tierCost;
      }
    }
    return totalUnits;
  }
}

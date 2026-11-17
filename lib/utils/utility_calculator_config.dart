import 'package:material_ui/material_ui.dart';
import '../models/bill.dart';
import 'tiered_tariff.dart';
import 'electricity_tariff.dart';
import 'water_tariff.dart';
import 'gas_tariff.dart';

class UtilityCalculatorConfig {
  final TieredTariff tariff;
  final String title;
  final IconData icon;
  final Color iconColor;
  const UtilityCalculatorConfig({
    required this.tariff,
    required this.title,
    required this.icon,
    required this.iconColor,
  });
}

UtilityCalculatorConfig? utilityCalculatorConfigFor(BillServiceType type) {
  switch (type) {
    case BillServiceType.electricity:
      return UtilityCalculatorConfig(
        tariff: ElectricityTariff.tariff,
        title: 'حاسبة شرائح الكهرباء',
        icon: Icons.bolt_rounded,
        iconColor: Colors.amber.shade700,
      );
    case BillServiceType.water:
      return UtilityCalculatorConfig(
        tariff: WaterTariff.tariff,
        title: 'حاسبة شرائح المياه',
        icon: Icons.water_drop_rounded,
        iconColor: Colors.blue.shade600,
      );
    case BillServiceType.gas:
      return UtilityCalculatorConfig(
        tariff: GasTariff.tariff,
        title: 'حاسبة شرائح الغاز',
        icon: Icons.local_fire_department_rounded,
        iconColor: Colors.deepOrange.shade600,
      );
    default:
      return null;
  }
}

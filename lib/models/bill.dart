import 'package:flutter/material.dart';

/// نوع الخدمة — لكل نوع أيقونة ولون مميز حسب مرجع التصميم
enum BillServiceType {
  gas,
  water,
  electricity,
  mobile,
  landline,
  internet,
  subscription,
  custom,
}

/// نوع الفاتورة: كارت شحن (مسبق الدفع) أو فاتورة شهرية (آجلة)
enum BillKind {
  prepaidCard,
  monthlyBill,
}

/// وحدة تكرار دورة السداد
enum BillCycleUnit { day, week, month, year }

extension BillCycleUnitX on BillCycleUnit {
  /// اسم الوحدة المفرد (يُستخدم في نص "كل X يوم/أسبوع/شهر/سنة")
  String get unitLabel {
    switch (this) {
      case BillCycleUnit.day:
        return 'يوم';
      case BillCycleUnit.week:
        return 'أسبوع';
      case BillCycleUnit.month:
        return 'شهر';
      case BillCycleUnit.year:
        return 'سنة';
    }
  }

  static BillCycleUnit fromName(String name) => BillCycleUnit.values
      .firstWhere((e) => e.name == name, orElse: () => BillCycleUnit.month);
}

/// دورات سداد جاهزة شائعة — تُستخدم كـ "اختصارات" في واجهة الاختيار بدل ما
/// المستخدم يدخل رقم ووحدة يدوياً في كل مرة لحالة شائعة زي "شهري" أو
/// "ربع سنوي". لو محدش منها اتناسب، في خيار "مخصص" بيسمح بأي قيمة.
class BillingPreset {
  final int value;
  final BillCycleUnit unit;
  const BillingPreset(this.value, this.unit);

  static const weekly = BillingPreset(1, BillCycleUnit.week);
  static const monthly = BillingPreset(1, BillCycleUnit.month);
  static const quarterly = BillingPreset(3, BillCycleUnit.month);
  static const semiAnnual = BillingPreset(6, BillCycleUnit.month);
  static const yearly = BillingPreset(1, BillCycleUnit.year);

  static const all = [weekly, monthly, quarterly, semiAnnual, yearly];

  bool matches(int v, BillCycleUnit u) => value == v && unit == u;
}

/// نص وصفي لدورة سداد مُعرّفة بقيمة ووحدة — بيرجع أسماء شائعة (شهري، ربع
/// سنوي..) للحالات المعروفة، وتنسيق عام ("كل X وحدة") لأي قيمة مخصصة.
String billCycleLabel(int value, BillCycleUnit unit) {
  if (value == 1) {
    switch (unit) {
      case BillCycleUnit.day:
        return 'يومي';
      case BillCycleUnit.week:
        return 'أسبوعي';
      case BillCycleUnit.month:
        return 'شهري';
      case BillCycleUnit.year:
        return 'سنوي';
    }
  }
  if (unit == BillCycleUnit.month && value == 3) return 'ربع سنوي';
  if (unit == BillCycleUnit.month && value == 6) return 'نصف سنوي';
  return 'كل $value ${unit.unitLabel}';
}

/// مدة التذكير قبل الموعد
enum ReminderLeadTime {
  oneDay,
  twoDays,
  threeDays,
  week,
  twoWeeks,
}

extension ReminderLeadTimeX on ReminderLeadTime {
  int get days {
    switch (this) {
      case ReminderLeadTime.oneDay:
        return 1;
      case ReminderLeadTime.twoDays:
        return 2;
      case ReminderLeadTime.threeDays:
        return 3;
      case ReminderLeadTime.week:
        return 7;
      case ReminderLeadTime.twoWeeks:
        return 14;
    }
  }

  String get label {
    switch (this) {
      case ReminderLeadTime.oneDay:
        return 'يوم واحد';
      case ReminderLeadTime.twoDays:
        return 'يومين';
      case ReminderLeadTime.threeDays:
        return '3 أيام';
      case ReminderLeadTime.week:
        return 'أسبوع';
      case ReminderLeadTime.twoWeeks:
        return 'أسبوعين';
    }
  }

  static ReminderLeadTime fromName(String name) =>
      ReminderLeadTime.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ReminderLeadTime.twoDays,
      );
}

extension BillServiceTypeX on BillServiceType {
  String get label {
    switch (this) {
      case BillServiceType.gas:
        return 'غاز';
      case BillServiceType.water:
        return 'مياه';
      case BillServiceType.electricity:
        return 'كهرباء';
      case BillServiceType.mobile:
        return 'موبايل';
      case BillServiceType.landline:
        return 'خط أرضي';
      case BillServiceType.internet:
        return 'إنترنت';
      case BillServiceType.subscription:
        return 'اشتراك';
      case BillServiceType.custom:
        return 'فاتورة مخصصة';
    }
  }

  IconData get icon {
    switch (this) {
      case BillServiceType.gas:
        return Icons.local_fire_department_rounded;
      case BillServiceType.water:
        return Icons.water_drop_rounded;
      case BillServiceType.electricity:
        return Icons.bolt_rounded;
      case BillServiceType.mobile:
        return Icons.smartphone_rounded;
      case BillServiceType.landline:
        return Icons.phone_rounded;
      case BillServiceType.internet:
        return Icons.wifi_rounded;
      case BillServiceType.subscription:
        return Icons.receipt_long_rounded;
      case BillServiceType.custom:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BillServiceType.gas:
        return const Color(0xFFE53E5E);
      case BillServiceType.water:
        return const Color(0xFF3B82F6);
      case BillServiceType.electricity:
        return const Color(0xFFF5A623);
      case BillServiceType.mobile:
        return const Color(0xFF8B5CF6);
      case BillServiceType.landline:
        return const Color(0xFF8B5CF6);
      case BillServiceType.internet:
        return const Color(0xFF22C55E);
      case BillServiceType.subscription:
        return const Color(0xFFF97316);
      case BillServiceType.custom:
        return const Color(0xFFF97316);
    }
  }

  static BillServiceType fromName(String name) =>
      BillServiceType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => BillServiceType.custom,
      );

  /// الدورة الافتراضية المتوقعة لكل نوع خدمة في الواقع — مثلاً فواتير
  /// الخط الأرضي في مصر غالباً ربع سنوية مش شهرية. ده مجرد اقتراح أولي
  /// بيتملى في معالج الإضافة، والمستخدم حر يغيّره لأي دورة تانية.
  BillingPreset get defaultCyclePreset {
    switch (this) {
      case BillServiceType.landline:
        return BillingPreset.quarterly;
      default:
        return BillingPreset.monthly;
    }
  }
}

extension BillKindX on BillKind {
  String get label =>
      this == BillKind.prepaidCard ? 'كارت شحن' : 'فاتورة شهرية';

  static BillKind fromName(String name) => BillKind.values.firstWhere(
        (e) => e.name == name,
        orElse: () => BillKind.monthlyBill,
      );
}

class Bill {
  final String id;
  final String name;
  final BillServiceType serviceType;
  final BillKind kind;

  /// تاريخ استحقاق مرجعي (أول/أقرب ميعاد معروف) — نقطة الانطلاق لحساب كل
  /// الدورات الجاية. حلّ محل "يوم السداد في الشهر" القديم عشان يدعم أي
  /// دورة (أسبوعي، ربع سنوي، سنوي، مخصص)، مش بس شهري.
  final DateTime anchorDate;

  /// كل كام وحدة بتتكرر الفاتورة (مثلاً 3 لو ربع سنوي)
  final int cycleValue;

  /// وحدة التكرار (يوم/أسبوع/شهر/سنة)
  final BillCycleUnit cycleUnit;

  final double? approximateAmount;
  final ReminderLeadTime reminderLead;
  final DateTime createdAt;
  final bool archived;

  Bill({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.kind,
    required this.anchorDate,
    required this.cycleValue,
    required this.cycleUnit,
    this.approximateAmount,
    required this.reminderLead,
    required this.createdAt,
    this.archived = false,
  });

  String get cycleLabel => billCycleLabel(cycleValue, cycleUnit);

  Bill copyWith({
    String? name,
    BillServiceType? serviceType,
    BillKind? kind,
    DateTime? anchorDate,
    int? cycleValue,
    BillCycleUnit? cycleUnit,
    double? approximateAmount,
    bool clearAmount = false,
    ReminderLeadTime? reminderLead,
    bool? archived,
  }) {
    return Bill(
      id: id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      kind: kind ?? this.kind,
      anchorDate: anchorDate ?? this.anchorDate,
      cycleValue: cycleValue ?? this.cycleValue,
      cycleUnit: cycleUnit ?? this.cycleUnit,
      approximateAmount:
          clearAmount ? null : (approximateAmount ?? this.approximateAmount),
      reminderLead: reminderLead ?? this.reminderLead,
      createdAt: createdAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serviceType': serviceType.name,
        'kind': kind.name,
        'anchorDate': anchorDate.toIso8601String(),
        'cycleValue': cycleValue,
        'cycleUnit': cycleUnit.name,
        'approximateAmount': approximateAmount,
        'reminderLead': reminderLead.name,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    // توافق رجعي: لو فيه بيانات قديمة محفوظة بصيغة dueDayOfMonth (قبل
    // دعم الدورات المرنة)، نحوّلها لـ anchorDate + دورة شهرية افتراضية
    // بدل ما نرميها أو نرمي exception.
    DateTime anchorDate;
    int cycleValue;
    BillCycleUnit cycleUnit;
    if (json.containsKey('anchorDate')) {
      anchorDate = DateTime.parse(json['anchorDate'] as String);
      cycleValue = json['cycleValue'] as int? ?? 1;
      cycleUnit = BillCycleUnitX.fromName(
          json['cycleUnit'] as String? ?? BillCycleUnit.month.name);
    } else {
      final legacyDay = json['dueDayOfMonth'] as int? ?? 1;
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final clampedDay = legacyDay.clamp(1, daysInMonth);
      anchorDate = DateTime(now.year, now.month, clampedDay);
      cycleValue = 1;
      cycleUnit = BillCycleUnit.month;
    }
    return Bill(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceType: BillServiceTypeX.fromName(json['serviceType'] as String),
      kind: BillKindX.fromName(json['kind'] as String),
      anchorDate: anchorDate,
      cycleValue: cycleValue,
      cycleUnit: cycleUnit,
      approximateAmount: (json['approximateAmount'] as num?)?.toDouble(),
      reminderLead:
          ReminderLeadTimeX.fromName(json['reminderLead'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      archived: json['archived'] as bool? ?? false,
    );
  }
}

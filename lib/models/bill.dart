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
  final int dueDayOfMonth; // 1-31
  final double? approximateAmount;
  final ReminderLeadTime reminderLead;
  final DateTime createdAt;
  final bool archived;

  Bill({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.kind,
    required this.dueDayOfMonth,
    this.approximateAmount,
    required this.reminderLead,
    required this.createdAt,
    this.archived = false,
  });

  Bill copyWith({
    String? name,
    BillServiceType? serviceType,
    BillKind? kind,
    int? dueDayOfMonth,
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
      dueDayOfMonth: dueDayOfMonth ?? this.dueDayOfMonth,
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
        'dueDayOfMonth': dueDayOfMonth,
        'approximateAmount': approximateAmount,
        'reminderLead': reminderLead.name,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        name: json['name'] as String,
        serviceType: BillServiceTypeX.fromName(json['serviceType'] as String),
        kind: BillKindX.fromName(json['kind'] as String),
        dueDayOfMonth: json['dueDayOfMonth'] as int,
        approximateAmount: (json['approximateAmount'] as num?)?.toDouble(),
        reminderLead: ReminderLeadTimeX.fromName(json['reminderLead'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
      );
}

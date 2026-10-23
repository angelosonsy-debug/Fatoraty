/// سجل دفعة واحدة لفاتورة — "اللي فعلاً حصل"، على عكس البيانات التقديرية
/// (approximateAmount) اللي المستخدم دخلها وقت إنشاء الفاتورة. ده بيفتح
/// الباب لسجل مدفوعات حقيقي وتتبّع مصروفات فعلية بدل تقديرية بس.
class PaymentRecord {
  final String id;
  final String billId;
  final String billName; // نسخة من الاسم وقت الدفع (لو الفاتورة اتحذفت بعدين)
  final double amount;
  final DateTime paidAt;

  PaymentRecord({
    required this.id,
    required this.billId,
    required this.billName,
    required this.amount,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'billId': billId,
        'billName': billName,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'] as String,
        billId: json['billId'] as String,
        billName: json['billName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}

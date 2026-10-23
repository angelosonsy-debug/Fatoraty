import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bill.dart';
import '../models/payment_record.dart';

/// استثناء مخصص لأخطاء الاستيراد — بنفرّقه عن أي exception تاني عشان
/// نعرض رسالة مفهومة للمستخدم بدل تفاصيل تقنية.
class BackupImportException implements Exception {
  final String message;
  BackupImportException(this.message);
  @override
  String toString() => message;
}

/// نتيجة قراءة ملف نسخة احتياطية — فواتير + سجل مدفوعات مع بعض.
class BackupData {
  final List<Bill> bills;
  final List<PaymentRecord> payments;
  BackupData({required this.bills, required this.payments});
}

/// النسخ الاحتياطي الكامل (JSON) — لاسترجاع كل البيانات زي ما هي (بما
/// فيها الفواتير المؤرشفة)، مفيد لو المستخدم غيّر موبايل أو مسح التطبيق
/// بالغلط. التصدير الـ CSV (لمشتركي Pro) منفصل عن ده — غرضه القراءة/
/// الفتح في برامج زي Excel، مش بالضرورة قابل لاسترجاع كامل الدقة.
class BackupService {
  // v1: فواتير بس. v2: ضاف سجل المدفوعات. ملفات v1 القديمة لسه قابلة
  // للقراءة — مفتاح "payments" هيبقى غائب فيها، وده متعامل معاه كقائمة
  // فاضية بدل ما يترفض الملف كله.
  static const _formatVersion = 2;

  Map<String, dynamic> _buildBackupMap(
    List<Bill> bills,
    List<PaymentRecord> payments,
  ) =>
      {
        'app': 'fatorty',
        'formatVersion': _formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'bills': bills.map((b) => b.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  /// يحفظ نسخة احتياطية كملف JSON مؤقت ويفتح شاشة المشاركة العادية
  /// (حفظ على الجهاز، إرسال، رفع على Drive، إلخ — حسب اختيار المستخدم).
  Future<void> shareBackupFile(
    List<Bill> bills,
    List<PaymentRecord> payments,
  ) async {
    final map = _buildBackupMap(bills, payments);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(map);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/fatorty_backup_$stamp.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'نسخة احتياطية - فاتورتي',
    );
  }

  /// يفتح منتقي ملفات عشان المستخدم يختار ملف نسخة احتياطية سابقة، ويرجّع
  /// الفواتير وسجل المدفوعات المستخرجين منه. بيرمي [BackupImportException]
  /// برسالة واضحة بالعربي لو الملف مش صالح.
  Future<BackupData> pickAndParseBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw BackupImportException('لم يتم اختيار أي ملف');
    }

    final picked = result.files.single;
    String content;
    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else {
      throw BackupImportException('تعذّر قراءة الملف المختار');
    }

    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('root is not an object');
      }
      map = decoded;
    } catch (_) {
      throw BackupImportException(
          'الملف ده مش نسخة احتياطية صالحة من فاتورتي');
    }

    final rawBills = map['bills'];
    if (rawBills is! List) {
      throw BackupImportException('الملف لا يحتوي على بيانات فواتير صالحة');
    }

    final bills = <Bill>[];
    for (final entry in rawBills) {
      try {
        bills.add(Bill.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        // تجاهل فاتورة واحدة تالفة داخل الملف، كمّل الباقي بدل ما نرفض
        // النسخة الاحتياطية كلها بسبب عنصر واحد معطوب.
      }
    }

    if (bills.isEmpty) {
      throw BackupImportException('مفيش فواتير صالحة داخل الملف ده');
    }

    final payments = <PaymentRecord>[];
    final rawPayments = map['payments']; // قد يكون غائب في ملفات v1 قديمة
    if (rawPayments is List) {
      for (final entry in rawPayments) {
        try {
          payments.add(PaymentRecord.fromJson(entry as Map<String, dynamic>));
        } catch (_) {
          // تجاهل سجل دفعة تالف واحد
        }
      }
    }

    return BackupData(bills: bills, payments: payments);
  }

  /// تصدير CSV (ميزة Pro) — للعرض في Excel أو Google Sheets.
  Future<void> shareCsvFile(List<Bill> bills) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'الاسم,النوع,نوع الفاتورة,دورة السداد,تاريخ الاستحقاق القادم,'
      'المبلغ التقريبي,التذكير قبل (أيام),مؤرشفة',
    );
    for (final b in bills) {
      String esc(String s) => '"${s.replaceAll('"', '""')}"';
      buffer.writeln([
        esc(b.name),
        esc(b.serviceType.label),
        esc(b.kind.label),
        esc(b.cycleLabel),
        '${b.anchorDate.year}-${b.anchorDate.month.toString().padLeft(2, '0')}-${b.anchorDate.day.toString().padLeft(2, '0')}',
        b.approximateAmount?.toStringAsFixed(2) ?? '',
        esc(b.reminderLeads.map((r) => '${r.days} يوم').join(' / ')),
        b.archived ? 'نعم' : 'لا',
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/fatorty_export_$stamp.csv');
    // BOM عشان Excel يفتح العربي صح
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())]);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'تصدير بيانات - فاتورتي',
    );
  }
}

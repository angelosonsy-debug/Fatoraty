import 'package:flutter/material.dart';
import '../services/storage_service.dart';

const int kFreeBillLimit = 4;

/// بنية جاهزة لـ Premium/AdMob بنفس نمط Mahfazty.
/// TODO: اربط isPremium فعلياً بـ Google Play Billing (Subscription) بدل
/// القيمة المخزنة محلياً — التخزين المحلي هنا placeholder فقط للتطوير.
class PremiumProvider extends ChangeNotifier {
  final StorageService _storage;
  PremiumProvider(this._storage);

  bool isPremium = false;
  DateTime? bonusSlotExpiry;
  bool loaded = false;

  Future<void> load() async {
    isPremium = await _storage.isPremium();
    bonusSlotExpiry = await _storage.bonusSlotExpiry();
    _clearExpiredBonusIfNeeded();
    loaded = true;
    notifyListeners();
  }

  void _clearExpiredBonusIfNeeded() {
    if (bonusSlotExpiry != null && bonusSlotExpiry!.isBefore(DateTime.now())) {
      bonusSlotExpiry = null;
      _storage.clearBonusSlot();
    }
  }

  /// الحد الأقصى الحالي لعدد الفواتير النشطة المسموح بها
  int get currentLimit {
    if (isPremium) return 1 << 30; // غير محدود فعلياً
    _clearExpiredBonusIfNeeded();
    return bonusSlotExpiry != null ? kFreeBillLimit + 1 : kFreeBillLimit;
  }

  bool canAddBill(int currentActiveCount) => currentActiveCount < currentLimit;

  /// TODO: ينادى من نجاح شراء الاشتراك عبر Google Play Billing
  Future<void> activatePremium() async {
    isPremium = true;
    await _storage.setPremium(true);
    notifyListeners();
  }

  /// TODO: ينادى بعد مشاهدة Rewarded Ad بنجاح (AdMob placeholder حالياً)
  Future<void> grantBonusSlot() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    bonusSlotExpiry = expiry;
    await _storage.setBonusSlotExpiry(expiry);
    notifyListeners();
  }
}

import 'package:material_ui/material_ui.dart';
import '../services/storage_service.dart';

const int kFreeBillLimit = 4;

/// أقصى عدد سلوتات إضافية ممكن فتحها بإعلانات المكافأة (مش بالاشتراك).
/// يعني أقصى حد فواتير "مجاني + إعلانات" = kFreeBillLimit + kMaxBonusSlots.
const int kMaxBonusSlots = 2;

/// بنية جاهزة لـ Premium/AdMob بنفس نمط Mahfazty.
/// TODO: اربط isPremium فعلياً بـ Google Play Billing (Subscription) بدل
/// القيمة المخزنة محلياً — التخزين المحلي هنا placeholder فقط للتطوير.
class PremiumProvider extends ChangeNotifier {
  final StorageService _storage;
  PremiumProvider(this._storage);

  bool isPremium = false;
  List<DateTime> bonusSlotExpiries = [];
  bool loaded = false;

  Future<void> load() async {
    try {
      isPremium = await _storage.isPremium();
      bonusSlotExpiries = await _storage.bonusSlotExpiries();
      await _clearExpiredBonusSlotsIfNeeded();
    } catch (_) {
      // لو فشلت القراءة، نكمل بالقيم الافتراضية (مجاني) بدل ما نسيب
      // loaded عالقة false للأبد.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _clearExpiredBonusSlotsIfNeeded() async {
    final now = DateTime.now();
    final before = bonusSlotExpiries.length;
    bonusSlotExpiries =
        bonusSlotExpiries.where((e) => e.isAfter(now)).toList();
    if (bonusSlotExpiries.length != before) {
      await _storage.saveBonusSlotExpiries(bonusSlotExpiries);
    }
  }

  /// الحد الأقصى الحالي لعدد الفواتير النشطة المسموح بها
  int get currentLimit {
    if (isPremium) return 1 << 30; // غير محدود فعلياً
    return kFreeBillLimit + bonusSlotExpiries.length;
  }

  bool canAddBill(int currentActiveCount) => currentActiveCount < currentLimit;

  /// هل لسه فيه سلوت إضافي ممكن يتفتح بإعلان مكافأة (أقل من الحد
  /// الأقصى المسموح به، kMaxBonusSlots)؟ لو لأ، الخيار ده لازم يختفي
  /// من واجهة PremiumModal ويفضل بس خيار الاشتراك.
  bool get canGrantMoreBonusSlots =>
      !isPremium && bonusSlotExpiries.length < kMaxBonusSlots;

  /// TODO: ينادى من نجاح شراء الاشتراك عبر Google Play Billing
  Future<void> activatePremium() async {
    isPremium = true;
    await _storage.setPremium(true);
    notifyListeners();
  }

  /// TODO: ينادى بعد مشاهدة Rewarded Ad بنجاح (AdMob placeholder حالياً).
  /// بيرجع false من غير ما يعمل حاجة لو وصلنا أصلاً لأقصى عدد سلوتات
  /// إضافية مسموح بيها (kMaxBonusSlots) — الشاشة المستدعية لازم تتأكد
  /// من canGrantMoreBonusSlots الأول قبل ما تعرض زرار المشاهدة أصلاً.
  Future<bool> grantBonusSlot() async {
    if (!canGrantMoreBonusSlots) return false;
    final expiry = DateTime.now().add(const Duration(days: 30));
    bonusSlotExpiries = [...bonusSlotExpiries, expiry];
    await _storage.saveBonusSlotExpiries(bonusSlotExpiries);
    notifyListeners();
    return true;
  }
}

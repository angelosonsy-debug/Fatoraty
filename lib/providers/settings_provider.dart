import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  SettingsProvider(this._storage);

  bool notificationsEnabled = true;
  TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool loaded = false;

  Future<void> load() async {
    notificationsEnabled = await _storage.notificationsEnabled();
    final t = await _storage.notificationTime();
    notificationTime = TimeOfDay(hour: t.hour, minute: t.minute);
    loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    await _storage.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    notificationTime = time;
    await _storage.setNotificationTime(time.hour, time.minute);
    notifyListeners();
  }
}

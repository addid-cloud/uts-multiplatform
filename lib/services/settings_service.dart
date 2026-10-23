import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan pengguna (key-value) memakai Shared Preferences.
class SettingsService {
  static const _kDark = 'dark_mode';
  static const _kNewest = 'sort_newest';

  static Future<bool> isDark() async =>
      (await SharedPreferences.getInstance()).getBool(_kDark) ?? false;

  static Future<void> setDark(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kDark, v);

  static Future<bool> isNewestFirst() async =>
      (await SharedPreferences.getInstance()).getBool(_kNewest) ?? true;

  static Future<void> setNewestFirst(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kNewest, v);
}

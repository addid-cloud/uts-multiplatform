import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatatanApp());
}

class CatatanApp extends StatefulWidget {
  const CatatanApp({super.key});

  @override
  State<CatatanApp> createState() => _CatatanAppState();
}

class _CatatanAppState extends State<CatatanApp> {
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final dark = await SettingsService.isDark().timeout(
        const Duration(seconds: 15),
      );
      if (mounted) setState(() => _dark = dark);
    } on Exception catch (error, stackTrace) {
      debugPrint('Gagal memuat preferensi tema: $error\n$stackTrace');
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => _dark = !_dark);
    await SettingsService.setDark(_dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Harian',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      home: HomeScreen(isDark: _dark, onToggleTheme: _toggleTheme),
    );
  }
}

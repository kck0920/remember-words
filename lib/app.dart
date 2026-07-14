import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'home/home_screen.dart';
import 'features/review/data/repositories/review_repository.dart';

final _reviewRepo = ReviewRepository();

class VocaTreeApp extends ConsumerWidget {
  const VocaTreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    
    return MaterialApp(
      title: 'VocaTree',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final value = await _reviewRepo.getSetting('dark_mode');
    if (value != null) {
      state = value == 'true';
    }
  }

  Future<void> setDarkMode(bool value) async {
    await _reviewRepo.setSetting('dark_mode', value.toString());
    state = value;
  }
}

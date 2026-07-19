import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/words/presentation/screens/word_list_screen.dart';
import '../features/review/presentation/screens/review_screen.dart';
import '../features/quiz/presentation/screens/quiz_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/data/services/backup_service.dart';
import '../features/settings/data/services/review_reminder_service.dart';

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerAutoBackup();
    _checkReviewReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _triggerAutoBackup();
    }
  }

  Future<void> _triggerAutoBackup() async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final enabled = await backupService.isAutoBackupEnabled();
      if (enabled) {
        await backupService.autoBackup();
      }
    } catch (_) {}
  }

  Future<void> _checkReviewReminder() async {
    try {
      final reminderService = ref.read(reviewReminderServiceProvider);
      await reminderService.init();
      final shouldShow = await reminderService.shouldShowReminder();
      if (shouldShow && mounted) {
        await reminderService.showNotification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('복습할 단어가 있습니다! (알림 발송됨)'),
            action: SnackBarAction(
              label: '복습하기',
              onPressed: () {
                ref.read(currentTabIndexProvider.notifier).state = 1;
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          WordListScreen(),
          ReviewScreen(),
          QuizScreen(),
          MatchingScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '단어장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.autorenew),
            label: '복습',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: '퀴즈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: '매칭',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

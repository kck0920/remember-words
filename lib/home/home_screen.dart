import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/words/presentation/screens/word_list_screen.dart';
import '../features/review/presentation/screens/review_screen.dart';
import '../features/quiz/presentation/screens/quiz_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

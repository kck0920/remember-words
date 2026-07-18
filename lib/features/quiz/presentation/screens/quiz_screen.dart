import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../words/data/models/word.dart';
import '../../../words/presentation/screens/word_list_screen.dart';
import 'meaning_quiz_screen.dart';
import 'fill_blank_quiz_screen.dart';
import 'meaning_typing_screen.dart';
import 'spelling_typing_screen.dart';

final quizWordsProvider = FutureProvider<List<Word>>((ref) async {
  final repo = ref.watch(wordRepositoryProvider);
  final words = await repo.getAllWords();
  if (words.length < 4) return [];
  words.shuffle();
  return words.take(10).toList();
});

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(quizWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈'),
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildQuizOptions(context, ref, words);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('에러: $error')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '퀴즈를 풀려면 최소 4개 이상의 단어가 필요합니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '단어장을 먼저 등록해주세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOptions(BuildContext context, WidgetRef ref, List<Word> words) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '퀴즈 유형 선택',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          _buildQuizOption(
            context,
            title: '영어 → 뜻 맞추기',
            description: '영어 단어를 보고 올바른 한국어 뜻을 선택하세요',
            icon: Icons.translate,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeaningQuizScreen(words: words),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _buildQuizOption(
            context,
            title: '빈칸 채우기',
            description: '예문의 빈칸에 알맞은 단어를 입력하세요',
            icon: Icons.edit_note,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FillBlankQuizScreen(words: words),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildQuizOption(
            context,
            title: '뜻 타이핑',
            description: '영어 단어를 보고 한국어 뜻을 타이핑하세요 (부분 일치 허용)',
            icon: Icons.keyboard,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeaningTypingScreen(words: words),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildQuizOption(
            context,
            title: '철자 타이핑',
            description: '한국어 뜻을 보고 영어 단어를 타이핑하세요 (오타 허용)',
            icon: Icons.spellcheck,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpellingTypingScreen(words: words),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '퀴즈 정보',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('• 문제 수: ${words.length > 10 ? 10 : words.length}문제'),
                  Text('• 사용 단어: 전체 단어 중 무작위 10개'),
                  const SizedBox(height: 8),
                  Text(
                    '팁: 자주 틀리는 단어는 복습에서 다시 학습하세요!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

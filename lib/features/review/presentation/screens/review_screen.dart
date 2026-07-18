import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_card.dart';
import '../../data/repositories/review_repository.dart';
import '../../../words/data/models/word.dart';
import '../../../words/presentation/screens/word_list_screen.dart';
import 'flashcard_screen.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => ReviewRepository());

final reviewMethodProvider = FutureProvider<ReviewMethod>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final value = await repo.getSetting('review_method');
  switch (value) {
    case 'fixed':
      return ReviewMethod.fixed;
    case 'sm2':
      return ReviewMethod.sm2;
    default:
      return ReviewMethod.linear;
  }
});

final fixedIntervalDaysProvider = FutureProvider<int?>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final value = await repo.getSetting('fixed_interval_days');
  return value != null ? int.tryParse(value) : null;
});

final dueReviewCardsProvider = FutureProvider<List<ReviewCard>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getDueReviewCards();
});

final reviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewStats();
});

final hasReviewedTodayProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.hasReviewedToday();
});

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 리뷰카드 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureReviewCards();
    });
  }

  Future<void> _ensureReviewCards() async {
    final repo = ref.read(reviewRepositoryProvider);
    final createdCount = await repo.ensureReviewCardsExist();
    
    if (createdCount > 0) {
      // 리뷰카드가 생성되면 provider 갱신
      ref.invalidate(dueReviewCardsProvider);
      ref.invalidate(reviewStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCardsAsync = ref.watch(dueReviewCardsProvider);
    final statsAsync = ref.watch(reviewStatsProvider);
    final hasReviewedTodayAsync = ref.watch(hasReviewedTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('복습'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(context, statsAsync),
            const SizedBox(height: 24),
            
            Text(
              '복습할 단어',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            dueCardsAsync.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return hasReviewedTodayAsync.when(
                    data: (hasReviewed) => _buildEmptyState(context, hasReviewed),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _buildEmptyState(context, false),
                  );
                }
                return Column(
                  children: [
                    _buildDueCountBanner(context, cards.length),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _startReview(context, cards);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('복습 시작하기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('에러: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          data: (stats) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '학습 현황',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      '전체 단어',
                      '${stats['totalWords']}',
                      Icons.book,
                    ),
                    _buildStatItem(
                      context,
                      '복습 예정',
                      '${stats['dueForReview']}',
                      Icons.autorenew,
                    ),
                    _buildStatItem(
                      context,
                      '정답률',
                      '${stats['accuracy']}%',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('에러: $error'),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDueCountBanner(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            '$count개의 단어가 복습을 기다리고 있습니다',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasReviewedToday) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasReviewedToday ? Icons.check_circle : Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasReviewedToday ? '오늘 복습을 완료했습니다!' : '복습할 단어가 없습니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasReviewedToday ? '내일 다시 복습하세요' : '먼저 단어를 추가해주세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _startReview(BuildContext context, List<ReviewCard> cards) async {
    final wordRepo = ref.read(wordRepositoryProvider);
    final words = <Word>[];
    
    for (final card in cards) {
      final word = await wordRepo.getWordById(card.wordId);
      if (word != null) {
        words.add(word);
      }
    }

    if (words.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardScreen(words: words),
        ),
      ).then((_) {
        ref.invalidate(dueReviewCardsProvider);
        ref.invalidate(reviewStatsProvider);
      });
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/presentation/screens/review_screen.dart';

class ReviewReminderService {
  final ReviewRepository _reviewRepository;

  ReviewReminderService(this._reviewRepository);

  /// 알림이 활성화되어 있는지 확인
  Future<bool> isReminderEnabled() async {
    final value = await _reviewRepository.getSetting('reminder_enabled');
    return value == 'true';
  }

  /// 알림 활성화/비활성화
  Future<void> setReminderEnabled(bool enabled) async {
    await _reviewRepository.setSetting('reminder_enabled', enabled ? 'true' : 'false');
  }

  /// 알림 시간 가져오기 (HH:mm 형식)
  Future<String> getReminderTime() async {
    final value = await _reviewRepository.getSetting('reminder_time');
    return value ?? '09:00'; // 기본값 오전 9시
  }

  /// 알림 시간 설정
  Future<void> setReminderTime(String time) async {
    await _reviewRepository.setSetting('reminder_time', time);
  }

  /// 리뷰 알림이 필요한지 확인 (오늘 아직 복습하지 않았고, 복습 대상이 있는 경우)
  Future<bool> shouldShowReminder() async {
    final enabled = await isReminderEnabled();
    if (!enabled) return false;

    final hasReviewed = await _reviewRepository.hasReviewedToday();
    if (hasReviewed) return false;

    final dueCards = await _reviewRepository.getDueReviewCards();
    return dueCards.isNotEmpty;
  }
}

final reviewReminderServiceProvider = Provider<ReviewReminderService>((ref) {
  final reviewRepository = ref.watch(reviewRepositoryProvider);
  return ReviewReminderService(reviewRepository);
});

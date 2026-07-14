import 'package:uuid/uuid.dart';

enum ReviewMethod {
  linear,
  fixed,
}

class ReviewCard {
  final String id;
  final String wordId;
  final ReviewMethod reviewMethod;
  final int? fixedIntervalDays;
  final DateTime nextReviewDate;
  final int reviewCount;
  final DateTime createdAt;

  ReviewCard({
    String? id,
    required this.wordId,
    required this.reviewMethod,
    this.fixedIntervalDays,
    required this.nextReviewDate,
    this.reviewCount = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Linear schedule: 1 -> 3 -> 7 -> 30 days
  static const List<int> linearSchedule = [1, 3, 7, 30];

  DateTime getNextReviewDate() {
    if (reviewMethod == ReviewMethod.fixed && fixedIntervalDays != null) {
      return DateTime.now().add(Duration(days: fixedIntervalDays!));
    }
    
    // Linear method
    final scheduleIndex = reviewCount.clamp(0, linearSchedule.length - 1);
    final daysToAdd = linearSchedule[scheduleIndex];
    return DateTime.now().add(Duration(days: daysToAdd));
  }

  ReviewCard incrementReviewCount() {
    return ReviewCard(
      id: id,
      wordId: wordId,
      reviewMethod: reviewMethod,
      fixedIntervalDays: fixedIntervalDays,
      nextReviewDate: getNextReviewDate(),
      reviewCount: reviewCount + 1,
      createdAt: createdAt,
    );
  }

  bool get isDueForReview {
    return DateTime.now().isAfter(nextReviewDate) || 
           DateTime.now().isAtSameMomentAs(nextReviewDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': wordId,
      'review_method': reviewMethod == ReviewMethod.linear ? 'linear' : 'fixed',
      'fixed_interval_days': fixedIntervalDays,
      'next_review_date': nextReviewDate.toIso8601String(),
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReviewCard.fromMap(Map<String, dynamic> map) {
    return ReviewCard(
      id: map['id'],
      wordId: map['word_id'],
      reviewMethod: map['review_method'] == 'linear'
          ? ReviewMethod.linear
          : ReviewMethod.fixed,
      fixedIntervalDays: map['fixed_interval_days'],
      nextReviewDate: DateTime.parse(map['next_review_date']),
      reviewCount: map['review_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReviewCard(id: $id, wordId: $wordId, method: $reviewMethod, nextReview: $nextReviewDate)';
  }
}

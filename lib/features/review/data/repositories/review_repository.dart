import 'package:sqflite/sqflite.dart';
import '../models/review_card.dart';
import '../../../../shared/services/database_service.dart';

class ReviewRepository {
  Future<String?> getSetting(String key) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await DatabaseService.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<ReviewCard>> getAllReviewCards() async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('review_cards');
    return maps.map((map) => ReviewCard.fromMap(map)).toList();
  }

  Future<ReviewCard?> getReviewCardByWordId(String wordId) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'review_cards',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
    if (maps.isEmpty) return null;
    return ReviewCard.fromMap(maps.first);
  }

  Future<List<ReviewCard>> getDueReviewCards() async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'review_cards',
      where: 'next_review_date <= ?',
      whereArgs: [now],
    );
    return maps.map((map) => ReviewCard.fromMap(map)).toList();
  }

  Future<void> insertReviewCard(ReviewCard card) async {
    final db = await DatabaseService.database;
    await db.insert('review_cards', card.toMap());
  }

  Future<void> updateReviewCard(ReviewCard card) async {
    final db = await DatabaseService.database;
    await db.update(
      'review_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteReviewCard(String id) async {
    final db = await DatabaseService.database;
    await db.delete(
      'review_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReviewCardByWordId(String wordId) async {
    final db = await DatabaseService.database;
    await db.delete(
      'review_cards',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  Future<void> deleteAllReviewCards() async {
    final db = await DatabaseService.database;
    await db.delete('review_cards');
  }

  Future<void> logReview({
    required String wordId,
    required bool isCorrect,
  }) async {
    final db = await DatabaseService.database;
    await db.insert('review_logs', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'word_id': wordId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'is_correct': isCorrect ? 1 : 0,
    });
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    final db = await DatabaseService.database;
    
    final totalWords = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    final dueCards = await db.rawQuery(
      'SELECT COUNT(*) as count FROM review_cards WHERE next_review_date <= ?',
      [DateTime.now().toIso8601String()],
    );
    final totalReviews = await db.rawQuery('SELECT COUNT(*) as count FROM review_logs');
    final correctReviews = await db.rawQuery(
      'SELECT COUNT(*) as count FROM review_logs WHERE is_correct = 1',
    );

    final totalCount = totalWords.first['count'] as int;
    final dueCount = dueCards.first['count'] as int;
    final reviewCount = totalReviews.first['count'] as int;
    final correctCount = correctReviews.first['count'] as int;

    return {
      'totalWords': totalCount,
      'dueForReview': dueCount,
      'totalReviews': reviewCount,
      'accuracy': reviewCount > 0 ? (correctCount / reviewCount * 100).round() : 0,
    };
  }
}

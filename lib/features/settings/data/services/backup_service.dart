import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/file_picker_helper.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../words/data/models/word.dart';
import '../../../words/data/repositories/word_repository.dart';
import '../../../words/presentation/screens/word_list_screen.dart'; // for wordRepositoryProvider

class BackupResult {
  final int importedCount;
  final int updatedCount;

  BackupResult({required this.importedCount, required this.updatedCount});
}

class BackupService {
  final WordRepository _wordRepository;

  BackupService(this._wordRepository);

  Future<int> exportBackup() async {
    final words = await _wordRepository.getAllWords();
    if (words.isEmpty) {
      return 0;
    }

    final jsonList = words.map((w) => w.toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    
    await saveJsonFile(jsonString, 'vocatree_backup.json');
    return words.length;
  }

  Future<BackupResult?> importBackup() async {
    final jsonString = await pickJsonFile();
    if (jsonString == null) {
      return null; // User cancelled
    }

    return importBackupFromString(jsonString);
  }

  // Extracted method to allow direct testing without mocking file picker UI
  Future<BackupResult> importBackupFromString(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException('올바른 백업 파일 형식이 아닙니다 (리스트 구조 필요)');
    }

    final existingWords = await _wordRepository.getAllWords();
    final existingByEnglish = {
      for (var w in existingWords) w.english.trim().toLowerCase(): w
    };

    int importedCount = 0;
    int updatedCount = 0;

    final List<Word> wordsToInsert = [];
    final List<Word> wordsToUpdate = [];

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final english = item['english'] as String?;
        final korean = item['korean'] as String?;
        
        if (english == null || english.isEmpty || korean == null || korean.isEmpty) {
          continue; // Skip invalid entries
        }

        final key = english.trim().toLowerCase();
        final existing = existingByEnglish[key];

        final word = Word(
          id: existing?.id ?? item['id'] as String?,
          english: english,
          korean: korean,
          exampleSentence: item['example_sentence'] as String?,
          pronunciation: item['pronunciation'] as String?,
          tags: item['tags'] != null
              ? (item['tags'] as String).split(',').where((t) => t.isNotEmpty).toList()
              : null,
          difficulty: item['difficulty'] as int? ?? 3,
          memo: item['memo'] as String?,
          createdAt: item['created_at'] != null ? DateTime.parse(item['created_at'] as String) : null,
          updatedAt: DateTime.now(),
        );

        if (existing != null) {
          wordsToUpdate.add(word);
          updatedCount++;
        } else {
          wordsToInsert.add(word);
          importedCount++;
        }
      }
    }

    // Perform DB batch operations
    if (wordsToInsert.isNotEmpty) {
      await _wordRepository.insertWords(wordsToInsert);
    }
    for (final w in wordsToUpdate) {
      await _wordRepository.updateWord(w);
    }

    return BackupResult(importedCount: importedCount, updatedCount: updatedCount);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final wordRepository = ref.watch(wordRepositoryProvider);
  return BackupService(wordRepository);
});

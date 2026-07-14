import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../data/services/backup_service.dart';
import '../../../words/presentation/screens/word_list_screen.dart';
import '../../../review/data/models/review_card.dart';
import '../../../review/presentation/screens/review_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '화면'),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 테마 사용'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(darkModeProvider.notifier).setDarkMode(value);
            },
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          const Divider(),
          
          _buildSectionHeader(context, '복습'),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('복습 방식'),
            subtitle: const Text('간격 반복 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReviewSettingsDialog(context, ref);
            },
          ),
          const Divider(),
          
          _buildSectionHeader(context, '데이터 관리'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('내보내기'),
            subtitle: const Text('단어장을 JSON 파일로 저장'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _exportData(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('가져오기'),
            subtitle: const Text('JSON 파일에서 단어장 복원'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _importData(context, ref);
            },
          ),
          const Divider(),
          
          _buildSectionHeader(context, '위험 구역'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('모든 단어 삭제', style: TextStyle(color: Colors.red)),
            subtitle: const Text('등록된 모든 단어를 삭제합니다'),
            onTap: () {
              _showDeleteAllDialog(context, ref);
            },
          ),
          const Divider(),
          
          _buildSectionHeader(context, '정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('VocaTree'),
            subtitle: Text('버전 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReviewSettingsDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    final currentMethodValue = await repo.getSetting('review_method');
    var selectedMethod = currentMethodValue == 'fixed'
        ? ReviewMethod.fixed
        : ReviewMethod.linear;
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('복습 방식 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ReviewMethod>(
                title: const Text('레이니어'),
                subtitle: const Text('1일 → 3일 → 7일 → 30일'),
                value: ReviewMethod.linear,
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedMethod = value);
                  }
                },
              ),
              RadioListTile<ReviewMethod>(
                title: const Text('고정 간격'),
                subtitle: const Text('매일/2일/3일/7일/14일/30일 중 선택'),
                value: ReviewMethod.fixed,
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedMethod = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                await repo.setSetting(
                  'review_method',
                  selectedMethod == ReviewMethod.fixed ? 'fixed' : 'linear',
                );
                ref.invalidate(reviewMethodProvider);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (selectedMethod == ReviewMethod.fixed) {
                  _showFixedIntervalDialog(context, ref);
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFixedIntervalDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    final currentValue = await repo.getSetting('fixed_interval_days');
    int selectedDays = currentValue != null ? (int.tryParse(currentValue) ?? 7) : 7;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('고정 간격 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(title: const Text('1일마다'), value: 1, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
              RadioListTile<int>(title: const Text('2일마다'), value: 2, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
              RadioListTile<int>(title: const Text('3일마다'), value: 3, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
              RadioListTile<int>(title: const Text('7일마다'), value: 7, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
              RadioListTile<int>(title: const Text('14일마다'), value: 14, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
              RadioListTile<int>(title: const Text('30일마다'), value: 30, groupValue: selectedDays, onChanged: (value) { if (value != null) setDialogState(() => selectedDays = value); }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                await repo.setSetting(
                  'fixed_interval_days',
                  selectedDays.toString(),
                );
                ref.invalidate(fixedIntervalDaysProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$selectedDays일 간격으로 설정되었습니다')),
                  );
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final count = await backupService.exportBackup();
      
      if (count == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('내보낼 단어가 없습니다')),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count개의 단어를 내보냈습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final result = await backupService.importBackup();
      if (result == null) {
        return; // User cancelled
      }

      // Invalidate providers to refresh UI
      ref.invalidate(wordsProvider);
      ref.invalidate(filteredWordsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '가져오기 완료: 새 단어 ${result.importedCount}개 추가, 기존 단어 ${result.updatedCount}개 업데이트'
            )
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가져오기 실패: $e')),
        );
      }
    }
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 단어 삭제'),
        content: const Text('정말로 모든 단어를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(wordRepositoryProvider);
              await repo.deleteAllWords();
              ref.invalidate(wordsProvider);
              ref.invalidate(filteredWordsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 단어가 삭제되었습니다')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

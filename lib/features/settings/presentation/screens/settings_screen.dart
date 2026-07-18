import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/review_reminder_service.dart';
import '../../../words/presentation/screens/word_list_screen.dart';
import '../../../review/data/models/review_card.dart';
import '../../../review/presentation/screens/review_screen.dart';
import '../../../quiz/presentation/screens/quiz_screen.dart';
import '../../../matching/presentation/screens/matching_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSetting();
  }

  Future<void> _loadAutoBackupSetting() async {
    final backupService = ref.read(backupServiceProvider);
    final enabled = await backupService.isAutoBackupEnabled();
    if (mounted) {
      setState(() {
        _autoBackupEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _buildThemeColorPicker(context, ref),

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
          _buildReminderSettings(context, ref),
          const Divider(),
          
          _buildSectionHeader(context, '데이터 관리'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('내보내기'),
            subtitle: const Text('단어장을 ZIP 파일로 저장'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _exportData(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('가져오기'),
            subtitle: const Text('ZIP 파일에서 단어장 복원'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _importData(context, ref);
            },
          ),
          _buildAutoBackupToggle(context, ref),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('학습 통계'),
            subtitle: const Text('전체 학습 현황 보기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
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

  Widget _buildAutoBackupToggle(BuildContext context, WidgetRef ref) {
    final backupService = ref.read(backupServiceProvider);
    return SwitchListTile(
      title: const Text('자동 백업'),
      subtitle: const Text('앱 시작 시 자동으로 백업'),
      value: _autoBackupEnabled,
      onChanged: (value) async {
        await backupService.setAutoBackupEnabled(value);
        setState(() {
          _autoBackupEnabled = value;
        });
      },
      secondary: const Icon(Icons.cloud_upload),
    );
  }

  Widget _buildThemeColorPicker(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(primaryColorProvider);
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('테마 색상'),
      subtitle: const Text('주요 색상 변경'),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: () => _showColorPicker(context, ref),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFF44336), // Red
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 색상 선택'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = ref.read(primaryColorProvider) == color;
            return GestureDetector(
              onTap: () {
                ref.read(primaryColorProvider.notifier).setPrimaryColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildReminderSettings(BuildContext context, WidgetRef ref) {
    final reminderService = ref.read(reviewReminderServiceProvider);
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        reminderService.isReminderEnabled(),
        reminderService.getReminderTime(),
      ]),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data?[0] as bool? ?? false;
        final time = snapshot.data?[1] as String? ?? '09:00';
        return ExpansionTile(
          leading: const Icon(Icons.notifications),
          title: const Text('복습 알림'),
          subtitle: Text(isEnabled ? '$time 알림' : '알림 비활성화'),
          children: [
            SwitchListTile(
              title: const Text('알림 활성화'),
              value: isEnabled,
              onChanged: (value) async {
                await reminderService.setReminderEnabled(value);
                if (context.mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              title: const Text('알림 시간'),
              trailing: Text(time),
              onTap: isEnabled ? () => _showTimePicker(context, ref, reminderService, time) : null,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref, ReviewReminderService service, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && context.mounted) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await service.setReminderTime(timeStr);
      setState(() {});
    }
  }

  void _showReviewSettingsDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reviewRepositoryProvider);
    final currentMethodValue = await repo.getSetting('review_method');
    ReviewMethod selectedMethod;
    switch (currentMethodValue) {
      case 'fixed':
        selectedMethod = ReviewMethod.fixed;
        break;
      case 'sm2':
        selectedMethod = ReviewMethod.sm2;
        break;
      default:
        selectedMethod = ReviewMethod.linear;
    }
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('복습 방식 설정'),
          content: RadioGroup<ReviewMethod>(
            groupValue: selectedMethod,
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedMethod = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RadioListTile<ReviewMethod>(
                  title: Text('레이니어'),
                  subtitle: Text('1일 → 3일 → 7일 → 30일'),
                  value: ReviewMethod.linear,
                ),
                const RadioListTile<ReviewMethod>(
                  title: Text('고정 간격'),
                  subtitle: Text('매일/2일/3일/7일/14일/30일 중 선택'),
                  value: ReviewMethod.fixed,
                ),
                const RadioListTile<ReviewMethod>(
                  title: Text('SM-2 (지능형)'),
                  subtitle: Text('학습 상태에 따라 간격 자동 조절'),
                  value: ReviewMethod.sm2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                String methodStr;
                switch (selectedMethod) {
                  case ReviewMethod.fixed:
                    methodStr = 'fixed';
                    break;
                  case ReviewMethod.sm2:
                    methodStr = 'sm2';
                    break;
                  default:
                    methodStr = 'linear';
                }
                await repo.setSetting('review_method', methodStr);
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
          content: RadioGroup<int>(
            groupValue: selectedDays,
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedDays = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RadioListTile<int>(title: Text('1일마다'), value: 1),
                const RadioListTile<int>(title: Text('2일마다'), value: 2),
                const RadioListTile<int>(title: Text('3일마다'), value: 3),
                const RadioListTile<int>(title: Text('7일마다'), value: 7),
                const RadioListTile<int>(title: Text('14일마다'), value: 14),
                const RadioListTile<int>(title: Text('30일마다'), value: 30),
              ],
            ),
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
      ref.invalidate(quizWordsProvider);
      ref.invalidate(matchingWordsProvider);
      ref.invalidate(reviewStatsProvider);
      ref.invalidate(dueReviewCardsProvider);

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
              ref.invalidate(quizWordsProvider);
              ref.invalidate(matchingWordsProvider);
              ref.invalidate(reviewStatsProvider);
              ref.invalidate(dueReviewCardsProvider);
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

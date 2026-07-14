import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word.dart';
import '../../../review/data/models/review_card.dart';
import '../../../review/presentation/screens/review_screen.dart';
import 'word_list_screen.dart';

class WordFormScreen extends ConsumerStatefulWidget {
  final Word? word;

  const WordFormScreen({super.key, this.word});

  @override
  ConsumerState<WordFormScreen> createState() => _WordFormScreenState();
}

class _WordFormScreenState extends ConsumerState<WordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _englishController;
  late TextEditingController _koreanController;
  late TextEditingController _exampleController;
  late TextEditingController _pronunciationController;
  late TextEditingController _memoController;
  late TextEditingController _tagController;
  int _difficulty = 3;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _englishController = TextEditingController(text: widget.word?.english ?? '');
    _koreanController = TextEditingController(text: widget.word?.korean ?? '');
    _exampleController = TextEditingController(text: widget.word?.exampleSentence ?? '');
    _pronunciationController = TextEditingController(text: widget.word?.pronunciation ?? '');
    _memoController = TextEditingController(text: widget.word?.memo ?? '');
    _tagController = TextEditingController();
    _difficulty = widget.word?.difficulty ?? 3;
    _tags = widget.word?.tags ?? [];
  }

  @override
  void dispose() {
    _englishController.dispose();
    _koreanController.dispose();
    _exampleController.dispose();
    _pronunciationController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.word != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '단어 수정' : '단어 추가'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteWord,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: '영어 단어 *',
                hintText: '예: hello',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '영어 단어를 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _koreanController,
              decoration: const InputDecoration(
                labelText: '한국어 뜻 *',
                hintText: '예: 안녕',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '한국어 뜻을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pronunciationController,
              decoration: const InputDecoration(
                labelText: '발음 기호',
                hintText: '예: /həˈloʊ/',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: '예문',
                hintText: '예: Hello, how are you?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildDifficultySelector(),
            const SizedBox(height: 16),
            _buildTagInput(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '추가 메모사항...',
              ),
              maxLines: 12,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveWord,
              child: Text(isEditing ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('난이도'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = _difficulty == level;
            
            Color color;
            switch (level) {
              case 1:
              case 2:
                color = Colors.green;
                break;
              case 3:
                color = Colors.orange;
                break;
              case 4:
              case 5:
                color = Colors.red;
                break;
              default:
                color = Colors.orange;
            }

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _difficulty = level;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _getDifficultyLabel(_difficulty),
          style: TextStyle(
            color: _getDifficultyColor(_difficulty),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return '매우 쉬움';
      case 2:
        return '쉬움';
      case 3:
        return '보통';
      case 4:
        return '어려움';
      case 5:
        return '매우 어려움';
      default:
        return '보통';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('태그'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              );
            }),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '태그 추가...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_tags.contains(value)) {
                    setState(() {
                      _tags.add(value);
                      _tagController.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveWord() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(wordRepositoryProvider);
    final reviewRepo = ref.read(reviewRepositoryProvider);
    final reviewMethodValue = await reviewRepo.getSetting('review_method');
    final reviewMethod = reviewMethodValue == 'fixed' ? ReviewMethod.fixed : ReviewMethod.linear;
    final fixedInterval = reviewMethodValue == 'fixed' 
        ? (int.tryParse(await reviewRepo.getSetting('fixed_interval_days') ?? '') ?? 7)
        : null;
    
    if (widget.word != null) {
      final updatedWord = widget.word!.copyWith(
        english: _englishController.text.trim(),
        korean: _koreanController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        exampleSentence: _exampleController.text.trim(),
        tags: _tags,
        difficulty: _difficulty,
        memo: _memoController.text.trim(),
      );
      await repo.updateWord(updatedWord);
    } else {
      final newWord = Word(
        english: _englishController.text.trim(),
        korean: _koreanController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        exampleSentence: _exampleController.text.trim(),
        tags: _tags,
        difficulty: _difficulty,
        memo: _memoController.text.trim(),
      );
      await repo.insertWord(newWord);

      final newCard = ReviewCard(
        wordId: newWord.id,
        reviewMethod: reviewMethod,
        fixedIntervalDays: reviewMethod == ReviewMethod.fixed ? fixedInterval : null,
        nextReviewDate: DateTime.now(),
      );
      await reviewRepo.insertReviewCard(newCard);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteWord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 단어를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(wordRepositoryProvider);
      final reviewRepo = ref.read(reviewRepositoryProvider);
      await reviewRepo.deleteReviewCardByWordId(widget.word!.id);
      await repo.deleteWord(widget.word!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../words/data/models/word.dart';
import 'review_screen.dart';

enum FlashcardMode {
  basic, // Tap to flip, swipe for correct/incorrect
  input, // Type the answer
}

class FlashcardScreen extends ConsumerStatefulWidget {
  final List<Word> words;

  const FlashcardScreen({super.key, required this.words});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  int _currentIndex = 0;
  bool _isShowingFront = true;
  FlashcardMode _mode = FlashcardMode.basic;
  String _userInput = '';
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isShowingFront = !_isShowingFront;
    });
  }

  void _nextCard({bool? isCorrect}) async {
    if (isCorrect != null) {
      await _recordReview(isCorrect);
    }

    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _isShowingFront = true;
        _isCorrect = null;
        _userInput = '';
      });
      _flipController.reset();
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _recordReview(bool isCorrect) async {
    final repo = ref.read(reviewRepositoryProvider);
    final word = widget.words[_currentIndex];
    
    await repo.logReview(
      wordId: word.id,
      isCorrect: isCorrect,
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('복습 완료!'),
        content: const Text('모든 단어를 복습했습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.words.length}'),
        actions: [
          PopupMenuButton<FlashcardMode>(
            icon: Icon(
              _mode == FlashcardMode.basic ? Icons.touch_app : Icons.keyboard,
            ),
            onSelected: (mode) {
              setState(() {
                _mode = mode;
                _isShowingFront = true;
                _userInput = '';
                _isCorrect = null;
              });
              _flipController.reset();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: FlashcardMode.basic,
                child: Text('기본 모드 (스와이프)'),
              ),
              const PopupMenuItem(
                value: FlashcardMode.input,
                child: Text('입력 모드 (타이핑)'),
              ),
            ],
          ),
        ],
      ),
      body: _mode == FlashcardMode.basic
          ? _buildBasicMode(word)
          : _buildInputMode(word),
    );
  }

  Widget _buildBasicMode(Word word) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! > 0) {
                _nextCard(isCorrect: true);
              } else if (details.primaryVelocity! < 0) {
                _nextCard(isCorrect: false);
              }
            },
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.14159;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: _isShowingFront
                      ? _buildFrontCard(word)
                      : Transform(
                          transform: Matrix4.identity()..rotateY(3.14159),
                          alignment: Alignment.center,
                          child: _buildBackCard(word),
                        ),
                );
              },
            ),
          ),
        ),
        _buildBasicControls(),
      ],
    );
  }

  Widget _buildFrontCard(Word word) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.english,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (word.pronunciation != null && word.pronunciation!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                word.pronunciation!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              '탭하여 뒤집기',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Word word) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.korean,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  word.exampleSentence!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _nextCard(isCorrect: false),
            icon: const Icon(Icons.close),
            label: const Text('몰랐다'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _flipCard,
            icon: const Icon(Icons.flip),
            label: const Text('뒤집기'),
          ),
          ElevatedButton.icon(
            onPressed: () => _nextCard(isCorrect: true),
            icon: const Icon(Icons.check),
            label: const Text('알았다'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputMode(Word word) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.14159;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: _isShowingFront
                      ? _buildFrontCard(word)
                      : Transform(
                          transform: Matrix4.identity()..rotateY(3.14159),
                          alignment: Alignment.center,
                          child: _buildBackCard(word),
                        ),
                );
              },
            ),
          ),
        ),
        _buildInputControls(word),
      ],
    );
  }

  Widget _buildInputControls(Word word) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '뜻을 입력하세요',
              hintText: '한국어 뜻을 타이핑하세요',
            ),
            onChanged: (value) {
              _userInput = value;
            },
            onSubmitted: (value) {
              _checkInput(word);
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: _flipCard,
                child: const Text('뒤집기'),
              ),
              ElevatedButton(
                onPressed: () => _checkInput(word),
                child: const Text('확인'),
              ),
            ],
          ),
          if (_isCorrect != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCorrect! ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect! ? '정답입니다!' : '오답입니다',
                    style: TextStyle(
                      color: _isCorrect! ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _checkInput(Word word) {
    final isCorrect = _userInput.trim().toLowerCase() == word.korean.trim().toLowerCase();
    setState(() {
      _isCorrect = isCorrect;
    });
    
    if (!isCorrect && !_isShowingFront) {
      _flipCard();
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextCard(isCorrect: isCorrect);
      }
    });
  }
}

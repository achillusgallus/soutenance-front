import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/models/flashcard.dart';
import 'package:togoschool/services/flashcard_service.dart';
import 'dart:math';

class StudentFlashcardsPage extends StatefulWidget {
  final int? courseId;
  final String? courseName;

  const StudentFlashcardsPage({super.key, this.courseId, this.courseName});

  @override
  State<StudentFlashcardsPage> createState() => _StudentFlashcardsPageState();
}

class _StudentFlashcardsPageState extends State<StudentFlashcardsPage> {
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = true;
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    final cards = await _flashcardService.getFlashcards(widget.courseId ?? 0);
    setState(() {
      _flashcards = cards;
      _isLoading = false;
    });
  }

  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.courseName != null
              ? 'Révision - ${widget.courseName}'
              : 'Flashcards',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _isFlipped = !_isFlipped),
                        child: _buildFlashcard(_flashcards[_currentIndex]),
                      ),
                    ),
                  ),
                ),
                _buildControls(),
              ],
            ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carte ${_currentIndex + 1} sur ${_flashcards.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                '${((_currentIndex + 1) / _flashcards.length * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _flashcards.length,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(_isFlipped) != child!.key);
            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            tilt *= isUnder ? -1.0 : 1.0;
            final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: _isFlipped
          ? _buildCardSide(
              card.answer,
              'Réponse',
              const Color(0xFF10B981),
              const ValueKey(true),
            )
          : _buildCardSide(
              card.question,
              'Question',
              const Color(0xFF6366F1),
              const ValueKey(false),
            ),
    );
  }

  Widget _buildCardSide(String content, String label, Color color, Key key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: key,
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Icon(
              FontAwesomeIcons.repeat,
              color: Colors.grey.withOpacity(0.3),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            onPressed: _previousCard,
            icon: FontAwesomeIcons.arrowLeft,
            label: 'Précédent',
            isEnabled: _currentIndex > 0,
          ),
          _buildControlButton(
            onPressed: _nextCard,
            icon: FontAwesomeIcons.arrowRight,
            label: 'Suivant',
            isEnabled: _currentIndex < _flashcards.length - 1,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isEnabled = true,
    bool isPrimary = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              if (icon == FontAwesomeIcons.arrowLeft) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : Colors.grey,
                ),
              ),
              if (icon == FontAwesomeIcons.arrowRight) ...[
                const SizedBox(width: 8),
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary ? Colors.white : Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FontAwesomeIcons.layerGroup, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune flashcard disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

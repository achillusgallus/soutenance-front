import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class StudentCalendarWidget extends StatefulWidget {
  const StudentCalendarWidget({super.key});

  @override
  State<StudentCalendarWidget> createState() => _StudentCalendarWidgetState();
}

class _StudentCalendarWidgetState extends State<StudentCalendarWidget> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _quizDates = [];
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
    _loadMockData();
  }

  void _loadMockData() {
    // Données de démonstration pour les quiz
    setState(() {
      _quizDates = [
        {
          'date': DateTime(2026, 1, 28),
          'title': 'Quiz Mathématiques',
          'course': 'Algèbre',
          'time': '14:00',
        },
        {
          'date': DateTime(2026, 1, 30),
          'title': 'Quiz Physique',
          'course': 'Mécanique',
          'time': '10:00',
        },
        {
          'date': DateTime(2026, 2, 2),
          'title': 'Quiz Chimie',
          'course': 'Organique',
          'time': '16:00',
        },
      ];

      _reminders = [
        {
          'date': DateTime(2026, 1, 26),
          'title': 'Réviser chapitre 5',
          'type': 'study',
        },
        {
          'date': DateTime(2026, 1, 27),
          'title': 'Exercices pratiques',
          'type': 'practice',
        },
      ];
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final events = <Map<String, dynamic>>[];

    // Ajouter les quiz
    for (final quiz in _quizDates) {
      if (_isSameDay(quiz['date'], day)) {
        events.add({...quiz, 'type': 'quiz'});
      }
    }

    // Ajouter les rappels
    for (final reminder in _reminders) {
      if (_isSameDay(reminder['date'], day)) {
        events.add({...reminder, 'type': 'reminder'});
      }
    }

    return events;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildCalendar(theme),
          const SizedBox(height: 16),
          _buildEventsList(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(FontAwesomeIcons.chevronLeft, color: Colors.white),
          ),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(
              FontAwesomeIcons.chevronRight,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeekdayHeaders(theme),
          const SizedBox(height: 8),
          _buildCalendarGrid(theme),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(ThemeData theme) {
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    final daysInMonth = lastDayOfMonth.day;
    final daysInPrevMonth = startingWeekday;

    return Column(
      children: List.generate(6, (weekIndex) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final dayNumber = weekIndex * 7 + dayIndex - daysInPrevMonth + 1;

            if (dayNumber <= 0 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox());
            }

            final day = DateTime(
              _currentMonth.year,
              _currentMonth.month,
              dayNumber,
            );
            final events = _getEventsForDay(day);
            final isSelected =
                _selectedDate != null && _isSameDay(day, _selectedDate!);
            final isToday = _isSameDay(day, DateTime.now());

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isToday
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.primaryColor)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? AppTheme.primaryColor
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (events.isNotEmpty)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events.take(3).map((event) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: event['type'] == 'quiz'
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildEventsList(ThemeData theme) {
    if (_selectedDate == null) return const SizedBox();

    final events = _getEventsForDay(_selectedDate!);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Événements du ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Aucun événement ce jour-ci',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...events.map((event) => _buildEventCard(event, theme)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, ThemeData theme) {
    final isQuiz = event['type'] == 'quiz';
    final color = isQuiz ? AppTheme.errorColor : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isQuiz ? FontAwesomeIcons.vial : FontAwesomeIcons.bell,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (isQuiz && event['course'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event['course'],
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
                if (isQuiz && event['time'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Heure: ${event['time']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showAddReminderDialog();
            },
            icon: Icon(FontAwesomeIcons.plus, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    final TextEditingController reminderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un rappel'),
        content: TextField(
          controller: reminderController,
          decoration: const InputDecoration(
            hintText: 'Entrez votre rappel...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (reminderController.text.trim().isNotEmpty) {
                setState(() {
                  _reminders.add({
                    'date': _selectedDate,
                    'title': reminderController.text.trim(),
                    'type': 'reminder',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rappel ajouté'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'database_helper.dart';

// STATIC: The Flutter application starts here.
void main() {
  runApp(const MyApp());
}

// STATIC: Contains application-level settings.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Study Planner',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// LOGIC: HomeScreen changes when database data, filters, or time changes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  // LOGIC: Goals are loaded from SQLite, not from a hardcoded list.
  final List<Map<String, dynamic>> _goals = [];

  // LOGIC: One shared database helper.
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // LOGIC: Stores the selected filter.
  String _selectedFilter = 'All';

  // LOGIC: Controls the initial loading state.
  bool _isLoading = true;

  // LOGIC: Stores an error message if database loading fails.
  String? _databaseError;

  // LOGIC: Refreshes time-based information.
  Timer? _timeTimer;

  // STATIC: Study tips used by the hourly tip logic.
  final List<String> _studyTips = [
    'Study for 25 minutes, then take a short 5-minute break.',
    'Start with the most difficult subject while your mind is fresh.',
    'Review your notes briefly after every study session.',
    'Break large topics into smaller and manageable tasks.',
    'Keep your phone away while studying to avoid distractions.',
    'Use active recall instead of only reading your notes.',
    'Create a checklist and mark each completed study task.',
    'Revise difficult topics more than once during the week.',
    'Explain a topic to someone else to test your understanding.',
    'Take short breaks to improve focus and avoid mental fatigue.',
    'Set one clear goal before starting every study session.',
    'Practice questions after studying to check your understanding.',
  ];

  // LOGIC: Starts the timer and loads saved goals from SQLite.
  @override
  void initState() {
    super.initState();

    _timeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (Timer timer) {
        if (mounted) {
          setState(() {});
        }
      },
    );

    _loadGoals();
  }

  // LOGIC: Stops the timer when the screen is removed.
  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  // LOGIC: SELECT — loads all saved goals into _goals.
  Future<void> _loadGoals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _databaseError = null;
      });
    }

    try {
      final List<Map<String, dynamic>> savedGoals =
          await _databaseHelper.getAllGoals();

      if (!mounted) {
        return;
      }

      setState(() {
        _goals
          ..clear()
          ..addAll(savedGoals);

        _isLoading = false;
        _databaseError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _databaseError = 'Could not load goals from the database.';
      });
    }
  }

  // LOGIC: fold() calculates total planned study hours.
  int get _totalHours {
    return _goals.fold<int>(
      0,
      (int total, Map<String, dynamic> goal) {
        return total + (goal['hours'] as int);
      },
    );
  }

  // LOGIC: where() selects completed goals and length counts them.
  int get _completedGoals {
    return _goals.where(
      (Map<String, dynamic> goal) {
        return goal['done'] as bool;
      },
    ).length;
  }

  // LOGIC: Calculates progress between 0 and 1.
  double get _progress {
    if (_goals.isEmpty) {
      return 0;
    }

    return _completedGoals / _goals.length;
  }

  // LOGIC: Converts progress into a percentage.
  int get _progressPercentage {
    return (_progress * 100).round();
  }

  // LOGIC: Returns a greeting based on the current hour.
  String get _greetingMessage {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  // LOGIC: Returns a greeting subtitle based on the current hour.
  String get _greetingSubtitle {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Start your day with focus and clear study goals.';
    } else if (hour < 17) {
      return 'Keep going and make the most of your study time.';
    } else {
      return 'Finish your day strongly and complete your goals.';
    }
  }

  // LOGIC: Selects a greeting icon based on the current time.
  IconData get _greetingIcon {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      return Icons.light_mode_outlined;
    } else {
      return Icons.nightlight_round;
    }
  }

  // LOGIC: Selects greeting colours that match the app theme.
  List<Color> get _greetingColors {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return [
        Colors.indigo.shade800,
        Colors.indigo.shade600,
        Colors.blue.shade500,
      ];
    } else if (hour < 17) {
      return [
        Colors.indigo.shade900,
        Colors.indigo.shade700,
        Colors.blue.shade600,
      ];
    } else {
      return [
        Colors.deepPurple.shade900,
        Colors.indigo.shade900,
        Colors.blueGrey.shade700,
      ];
    }
  }

  // LOGIC: Formats the current time.
  String get _formattedCurrentTime {
    final DateTime now = DateTime.now();
    int hour = now.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final String minute = now.minute.toString().padLeft(2, '0');
    final String period = now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // LOGIC: Selects a different tip every hour.
  String get _currentStudyTip {
    final int tipIndex = DateTime.now().hour % _studyTips.length;
    return _studyTips[tipIndex];
  }

  // LOGIC: Returns the current hour label.
  String get _currentHourLabel {
    final DateTime now = DateTime.now();
    int hour = now.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final String period = now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:00 $period';
  }

  // LOGIC: Returns original indexes of goals matching the selected filter.
  List<int> get _visibleGoalIndexes {
    final List<int> indexes = [];

    for (int index = 0; index < _goals.length; index++) {
      final bool isDone = _goals[index]['done'] as bool;

      if (_selectedFilter == 'All') {
        indexes.add(index);
      } else if (_selectedFilter == 'Pending' && !isDone) {
        indexes.add(index);
      } else if (_selectedFilter == 'Done' && isDone) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  // LOGIC: Chooses the empty-state message.
  String get _emptyMessage {
    if (_goals.isEmpty) {
      return 'No goals yet — add one!';
    }

    if (_selectedFilter == 'Done') {
      return 'No completed goals yet.';
    }

    if (_selectedFilter == 'Pending') {
      return 'Great work! No pending goals.';
    }

    return 'No goals available.';
  }

  // LOGIC: Chooses the empty-state icon.
  IconData get _emptyIcon {
    if (_selectedFilter == 'Done') {
      return Icons.check_circle_outline;
    }

    if (_selectedFilter == 'Pending') {
      return Icons.celebration_outlined;
    }

    return Icons.menu_book_outlined;
  }

  // STATIC: Shows a temporary message.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // LOGIC: Changes the selected filter.
  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // LOGIC: UPDATE — changes the done value in SQLite and _goals.
  Future<void> _toggleGoal(int index) async {
    final Map<String, dynamic> goal = _goals[index];
    final int id = goal['id'] as int;
    final String subject = goal['subject'] as String;
    final bool newStatus = !(goal['done'] as bool);

    try {
      await _databaseHelper.updateGoalStatus(
        id: id,
        done: newStatus,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _goals[index]['done'] = newStatus;
      });

      _showMessage(
        newStatus
            ? 'Great job! $subject completed.'
            : '$subject marked as pending.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not update the goal.');
      }
    }
  }

  // LOGIC: INSERT — saves a new goal in SQLite and stores its id.
  Future<void> _openAddGoalScreen() async {
    final Map<String, dynamic>? newGoal =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const AddGoalScreen();
        },
      ),
    );

    if (newGoal == null || !mounted) {
      return;
    }

    try {
      final int generatedId =
          await _databaseHelper.insertGoal(newGoal);

      if (!mounted) {
        return;
      }

      final Map<String, dynamic> savedGoal = {
        'id': generatedId,
        'subject': newGoal['subject'],
        'hours': newGoal['hours'],
        'done': newGoal['done'],
      };

      setState(() {
        _goals.add(savedGoal);
        _selectedFilter = 'All';
      });

      _showMessage(
        '${savedGoal['subject']} was added successfully.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not save the new goal.');
      }
    }
  }

  // LOGIC: UPDATE — edits the SQLite row and _goals.
  Future<void> _openEditGoalScreen(int index) async {
    final Map<String, dynamic>? updatedGoal =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddGoalScreen(
            initialGoal: Map<String, dynamic>.from(
              _goals[index],
            ),
          );
        },
      ),
    );

    if (updatedGoal == null || !mounted) {
      return;
    }

    try {
      await _databaseHelper.updateGoal(updatedGoal);

      if (!mounted) {
        return;
      }

      setState(() {
        _goals[index] = updatedGoal;
      });

      _showMessage(
        '${updatedGoal['subject']} was updated successfully.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not update the goal.');
      }
    }
  }

  // LOGIC: DELETE — confirms and removes a goal by its database id.
  Future<void> _confirmDelete(int index) async {
    final Map<String, dynamic> selectedGoal = _goals[index];
    final String subject = selectedGoal['subject'] as String;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // STATIC: Delete confirmation dialog.
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 42,
          ),
          title: Text('Delete $subject?'),
          content: const Text(
            'Are you sure you want to remove this study goal?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final Map<String, dynamic> deletedGoal =
        Map<String, dynamic>.from(selectedGoal);

    final int deletedIndex = index;
    final int id = deletedGoal['id'] as int;

    try {
      await _databaseHelper.deleteGoal(id);

      if (!mounted) {
        return;
      }

      setState(() {
        _goals.removeAt(index);
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$subject deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              _restoreDeletedGoal(
                deletedGoal,
                deletedIndex,
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not delete the goal.');
      }
    }
  }

  // LOGIC: INSERT — restores one deleted row and list item.
  Future<void> _restoreDeletedGoal(
    Map<String, dynamic> goal,
    int originalIndex,
  ) async {
    try {
      await _databaseHelper.restoreGoal(goal);

      if (!mounted) {
        return;
      }

      int insertIndex = originalIndex;

      if (insertIndex > _goals.length) {
        insertIndex = _goals.length;
      }

      setState(() {
        _goals.insert(insertIndex, goal);
      });
    } catch (error) {
      if (mounted) {
        _showMessage('Could not restore the goal.');
      }
    }
  }

  // LOGIC: DELETE — removes all completed goals from SQLite and _goals.
  Future<void> _clearCompletedGoals() async {
    if (_completedGoals == 0) {
      return;
    }

    final int completedCount = _completedGoals;

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // STATIC: Clear-completed confirmation dialog.
        return AlertDialog(
          icon: const Icon(
            Icons.cleaning_services,
            color: Colors.indigo,
            size: 42,
          ),
          title: const Text('Clear completed goals?'),
          content: Text(
            'This will remove $completedCount completed '
            '${completedCount == 1 ? 'goal' : 'goals'}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    final List<Map<String, dynamic>> removedGoals =
        _goals
            .where(
              (Map<String, dynamic> goal) {
                return goal['done'] as bool;
              },
            )
            .map(
              (Map<String, dynamic> goal) {
                return Map<String, dynamic>.from(goal);
              },
            )
            .toList();

    try {
      await _databaseHelper.deleteCompletedGoals();

      if (!mounted) {
        return;
      }

      setState(() {
        _goals.removeWhere(
          (Map<String, dynamic> goal) {
            return goal['done'] as bool;
          },
        );
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$completedCount completed '
            '${completedCount == 1 ? 'goal was' : 'goals were'} removed.',
          ),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              _restoreCompletedGoals(removedGoals);
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not clear completed goals.');
      }
    }
  }

  // LOGIC: INSERT — restores completed rows and reloads the list.
  Future<void> _restoreCompletedGoals(
    List<Map<String, dynamic>> goals,
  ) async {
    try {
      await _databaseHelper.restoreGoals(goals);

      if (!mounted) {
        return;
      }

      await _loadGoals();
    } catch (error) {
      if (mounted) {
        _showMessage('Could not restore completed goals.');
      }
    }
  }

  // LOGIC: Selects an icon based on the subject name.
  IconData _getSubjectIcon(String subject) {
    final String name = subject.toLowerCase();

    if (name.contains('math')) {
      return Icons.calculate;
    }

    if (name.contains('mobile') ||
        name.contains('flutter') ||
        name.contains('programming')) {
      return Icons.phone_android;
    }

    if (name.contains('database')) {
      return Icons.storage;
    }

    if (name.contains('network')) {
      return Icons.router;
    }

    if (name.contains('web')) {
      return Icons.language;
    }

    return Icons.menu_book;
  }

  // LOGIC: Selects a colour based on the subject name.
  Color _getSubjectColor(String subject) {
    final String name = subject.toLowerCase();

    if (name.contains('math')) {
      return Colors.blue;
    }

    if (name.contains('mobile') ||
        name.contains('flutter') ||
        name.contains('programming')) {
      return Colors.teal;
    }

    if (name.contains('database')) {
      return Colors.orange;
    }

    if (name.contains('network')) {
      return Colors.purple;
    }

    if (name.contains('web')) {
      return Colors.blue;
    }

    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> visibleIndexes = _visibleGoalIndexes;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // STATIC: Main application bar.
      appBar: AppBar(
        title: const Text(
          'My Study Planner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$_completedGoals/${_goals.length} done',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      // LOGIC: Shows loading, an error, or the saved data.
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _databaseError != null
              ? _buildDatabaseError()
              : _buildHomeContent(visibleIndexes),

      // STATIC: Opens the Add Goal screen.
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoalScreen,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  // STATIC: Database error interface.
  Widget _buildDatabaseError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storage_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _databaseError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadGoals,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // STATIC: Complete Home Screen content.
  Widget _buildHomeContent(List<int> visibleIndexes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreetingSection(),
        const SizedBox(height: 22),

        const Text(
          'Study Overview',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  icon: Icons.menu_book,
                  value: '${_goals.length}',
                  label: 'Goals',
                ),
                StatItem(
                  icon: Icons.schedule,
                  value: '$_totalHours',
                  label: 'Hours',
                ),
                StatItem(
                  icon: Icons.check_circle,
                  value: '$_completedGoals',
                  label: 'Done',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        _buildProgressCard(),
        const SizedBox(height: 18),
        _buildStudyTipSection(),
        const SizedBox(height: 24),

        Row(
          children: [
            const Expanded(
              child: Text(
                'My Study Goals',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  _completedGoals > 0 ? _clearCompletedGoals : null,
              tooltip: 'Clear Completed Goals',
              icon: const Icon(Icons.cleaning_services),
            ),
          ],
        ),

        const SizedBox(height: 8),
        _buildFilters(),
        const SizedBox(height: 14),

        if (visibleIndexes.isEmpty)
          _buildEmptyState()
        else
          ...visibleIndexes.map(_buildGoalCard),

        const SizedBox(height: 80),
      ],
    );
  }

  // STATIC: Time-based greeting section.
  Widget _buildGreetingSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _greetingColors,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _greetingColors.first.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              _greetingIcon,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _greetingSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formattedCurrentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATIC: Live progress card.
  Widget _buildProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_progressPercentage%',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: Colors.indigo.shade100,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_completedGoals of ${_goals.length} goals completed',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATIC: Hourly Study Tip section.
  Widget _buildStudyTipSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade600,
            Colors.indigo.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1.3,
              ),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Study Tip of the Hour',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentHourLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  _currentStudyTip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATIC: Goal filters.
  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _selectedFilter == 'All',
          onSelected: (_) {
            _changeFilter('All');
          },
        ),
        ChoiceChip(
          label: const Text('Pending'),
          selected: _selectedFilter == 'Pending',
          onSelected: (_) {
            _changeFilter('Pending');
          },
        ),
        ChoiceChip(
          label: const Text('Done'),
          selected: _selectedFilter == 'Done',
          onSelected: (_) {
            _changeFilter('Done');
          },
        ),
      ],
    );
  }

  // STATIC: Empty-state interface.
  Widget _buildEmptyState() {
    return Container(
      height: 230,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _emptyIcon,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // STATIC: Builds one goal card.
  Widget _buildGoalCard(int originalIndex) {
    final Map<String, dynamic> goal = _goals[originalIndex];

    final String subject = goal['subject'] as String;
    final int hours = goal['hours'] as int;
    final bool isDone = goal['done'] as bool;
    final Color subjectColor = _getSubjectColor(subject);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDone ? Colors.green.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _toggleGoal(originalIndex);
              },
              tooltip: isDone ? 'Mark as pending' : 'Mark as done',
              icon: Icon(
                isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isDone ? Colors.green : Colors.indigo,
                size: 31,
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: subjectColor.withOpacity(0.15),
              child: Icon(
                _getSubjectIcon(subject),
                color: subjectColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? Colors.green.shade800
                          : Colors.black,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '$hours ${hours == 1 ? 'hour' : 'hours'} planned',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone ? 'Done' : 'Pending',
                    style: TextStyle(
                      color: isDone
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _openEditGoalScreen(originalIndex);
                      },
                      tooltip: 'Edit Goal',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.indigo.shade600,
                        size: 23,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _confirmDelete(originalIndex);
                      },
                      tooltip: 'Delete Goal',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// STATIC: Reusable statistics widget.
class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.indigo,
          size: 30,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// LOGIC: The same form adds a new goal or edits an existing goal.
class AddGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? initialGoal;

  const AddGoalScreen({
    super.key,
    this.initialGoal,
  });

  @override
  State<AddGoalScreen> createState() {
    return _AddGoalScreenState();
  }
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: Controllers read user input.
  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _hoursController =
      TextEditingController();

  // LOGIC: Store validation messages.
  String? _subjectError;
  String? _hoursError;

  // LOGIC: True when editing an existing goal.
  bool get _isEditing {
    return widget.initialGoal != null;
  }

  // LOGIC: Loads existing values into the form.
  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? goal = widget.initialGoal;

    if (goal != null) {
      _subjectController.text = goal['subject'] as String;
      _hoursController.text = (goal['hours'] as int).toString();
    }
  }

  // LOGIC: Validates and returns a new or updated goal.
  void _saveGoal() {
    final String subject = _subjectController.text.trim();
    final String hoursText = _hoursController.text.trim();
    final int? hours = int.tryParse(hoursText);

    String? subjectError;
    String? hoursError;

    if (subject.isEmpty) {
      subjectError = 'Please enter a subject name.';
    }

    if (hoursText.isEmpty) {
      hoursError = 'Please enter the number of hours.';
    } else if (hours == null) {
      hoursError = 'Hours must be a valid number.';
    } else if (hours <= 0) {
      hoursError = 'Hours must be greater than zero.';
    }

    setState(() {
      _subjectError = subjectError;
      _hoursError = hoursError;
    });

    if (subjectError != null || hoursError != null) {
      return;
    }

    final Map<String, dynamic> goalToReturn;

    if (_isEditing) {
      // LOGIC: Copying preserves id and done.
      goalToReturn =
          Map<String, dynamic>.from(widget.initialGoal!);

      goalToReturn['subject'] = subject;
      goalToReturn['hours'] = hours!;
    } else {
      goalToReturn = {
        'subject': subject,
        'hours': hours!,
        'done': false,
      };
    }

    // CONNECTION POINT: Returns form data to HomeScreen.
    Navigator.pop(context, goalToReturn);
  }

  // LOGIC: Releases controller resources.
  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // STATIC: Title changes for add or edit mode.
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Study Goal' : 'Add Study Goal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      // STATIC: Form content.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade900,
                    Colors.indigo.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _isEditing
                          ? Icons.edit_note_rounded
                          : Icons.add_task_rounded,
                      size: 40,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isEditing
                        ? 'Update Your Goal'
                        : 'Create a New Goal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEditing
                        ? 'Change the subject name or planned study hours.'
                        : 'Enter the subject and your planned study time.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            TextField(
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Subject name',
                hintText: 'Example: Mobile Programming',
                prefixIcon: const Icon(Icons.menu_book),
                errorText: _subjectError,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.indigo,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_subjectError != null) {
                  setState(() {
                    _subjectError = null;
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Number of hours',
                hintText: 'Example: 3',
                prefixIcon: const Icon(Icons.schedule),
                errorText: _hoursError,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.indigo,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_hoursError != null) {
                  setState(() {
                    _hoursError = null;
                  });
                }
              },
              onSubmitted: (_) {
                _saveGoal();
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: _saveGoal,
                icon: Icon(
                  _isEditing
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_task_rounded,
                  size: 25,
                ),
                label: Text(
                  _isEditing
                      ? 'Update Study Goal'
                      : 'Create Study Goal',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.indigo.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _goals = [
    {
      'subject': 'Web Technology',
      'hours': 3,
      'done': false,
    },
    {
      'subject': 'Advanced Mobile Application',
      'hours': 5,
      'done': true,
    },
    {
      'subject': 'Database Programming',
      'hours': 3,
      'done': false,
    },
  ];

  String _selectedFilter = 'All';

  int get _totalHours {
    int total = 0;

    for (final goal in _goals) {
      total += goal['hours'] as int;
    }

    return total;
  }

  int get _completedGoals {
    int completed = 0;

    for (final goal in _goals) {
      if (goal['done'] as bool) {
        completed++;
      }
    }

    return completed;
  }

  double get _progress {
    if (_goals.isEmpty) {
      return 0;
    }

    return _completedGoals / _goals.length;
  }

  int get _progressPercentage {
    return (_progress * 100).round();
  }

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

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _toggleGoal(int index) {
    final String subject = _goals[index]['subject'] as String;

    setState(() {
      final bool currentStatus = _goals[index]['done'] as bool;
      _goals[index]['done'] = !currentStatus;
    });

    final bool isDone = _goals[index]['done'] as bool;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDone
              ? 'Great job! $subject completed.'
              : '$subject marked as pending.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAddGoalScreen() async {
    final Map<String, dynamic>? newGoal =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const AddGoalScreen();
        },
      ),
    );

    if (newGoal == null || !mounted) {
      return;
    }

    setState(() {
      _goals.add(newGoal);
    });

    final String subject = newGoal['subject'] as String;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$subject was added successfully.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final String subject = _goals[index]['subject'] as String;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
        Map<String, dynamic>.from(_goals[index]);

    final int deletedIndex = index;

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
            int insertIndex = deletedIndex;

            if (insertIndex > _goals.length) {
              insertIndex = _goals.length;
            }

            setState(() {
              _goals.insert(insertIndex, deletedGoal);
            });
          },
        ),
      ),
    );
  }

  Future<void> _clearCompletedGoals() async {
    if (_completedGoals == 0) {
      return;
    }

    final int completedCount = _completedGoals;

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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

    final List<MapEntry<int, Map<String, dynamic>>> removedGoals = [];

    for (int index = 0; index < _goals.length; index++) {
      if (_goals[index]['done'] == true) {
        removedGoals.add(
          MapEntry(
            index,
            Map<String, dynamic>.from(_goals[index]),
          ),
        );
      }
    }

    setState(() {
      _goals.removeWhere(
        (goal) => goal['done'] == true,
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
            setState(() {
              for (final entry in removedGoals) {
                int insertIndex = entry.key;

                if (insertIndex > _goals.length) {
                  insertIndex = _goals.length;
                }

                _goals.insert(
                  insertIndex,
                  Map<String, dynamic>.from(entry.value),
                );
              }
            });
          },
        ),
      ),
    );
  }

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

  IconData get _emptyIcon {
    if (_selectedFilter == 'Done') {
      return Icons.check_circle_outline;
    }

    if (_selectedFilter == 'Pending') {
      return Icons.celebration_outlined;
    }

    return Icons.menu_book_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> visibleIndexes = _visibleGoalIndexes;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'My Study Planner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade800,
                  Colors.indigo.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.school,
                    size: 35,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Stay focused and complete your study goals.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  _buildStat(
                    icon: Icons.menu_book,
                    number: '${_goals.length}',
                    label: 'Goals',
                  ),
                  _buildStat(
                    icon: Icons.schedule,
                    number: '$_totalHours',
                    label: 'Hours',
                  ),
                  _buildStat(
                    icon: Icons.check_circle,
                    number: '$_completedGoals',
                    label: 'Done',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
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
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.indigo.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Tip of the Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Study for 25 minutes, then take a short '
                        '5-minute break before continuing.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
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
          Wrap(
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
          ),
          const SizedBox(height: 14),
          if (visibleIndexes.isEmpty)
            Container(
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
            )
          else
            ...visibleIndexes.map(
              (originalIndex) {
                final Map<String, dynamic> goal =
                    _goals[originalIndex];

                final String subject = goal['subject'] as String;
                final int hours = goal['hours'] as int;
                final bool isDone = goal['done'] as bool;
                final Color subjectColor =
                    _getSubjectColor(subject);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDone
                      ? Colors.green.shade50
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _toggleGoal(originalIndex);
                          },
                          tooltip: isDone
                              ? 'Mark as pending'
                              : 'Mark as done',
                          icon: Icon(
                            isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isDone
                                ? Colors.green
                                : Colors.indigo,
                            size: 31,
                          ),
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              subjectColor.withOpacity(0.15),
                          child: Icon(
                            _getSubjectIcon(subject),
                            color: subjectColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
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
                                  Text(
                                    '$hours '
                                    '${hours == 1 ? 'hour' : 'hours'} planned',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            _confirmDelete(originalIndex);
                          },
                          tooltip: 'Delete Goal',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGoalScreen,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String number,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.indigo,
          size: 30,
        ),
        const SizedBox(height: 6),
        Text(
          number,
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

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() {
    return _AddGoalScreenState();
  }
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _hoursController =
      TextEditingController();

  String? _subjectError;
  String? _hoursError;

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

    final Map<String, dynamic> newGoal = {
      'subject': subject,
      'hours': hours!,
      'done': false,
    };

    Navigator.pop(context, newGoal);
  }

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
      appBar: AppBar(
        title: const Text(
          'Add Study Goal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
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
                    Colors.indigo.shade800,
                    Colors.indigo.shade500,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.add_task,
                      size: 38,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Create a New Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Enter the subject and your planned study time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
              height: 52,
              child: FilledButton.icon(
                onPressed: _saveGoal,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
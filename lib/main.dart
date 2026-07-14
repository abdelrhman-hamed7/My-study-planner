import 'package:flutter/material.dart';

// STATIC: The application starts from the main function.
void main() {
  runApp(const MyApp());
}

// STATIC: MyApp contains application-level settings that do not change.
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

// LOGIC: HomeScreen is stateful because goals and filters can change.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  // LOGIC: This list is the main source of goal data.
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

  // LOGIC: Stores the currently selected filter.
  String _selectedFilter = 'All';

  // LOGIC: fold() adds the hours of every goal.
  int get _totalHours {
    return _goals.fold<int>(
      0,
      (total, goal) {
        return total + (goal['hours'] as int);
      },
    );
  }

  // LOGIC: where() keeps completed goals, then length counts them.
  int get _completedGoals {
    return _goals.where(
      (goal) {
        return goal['done'] as bool;
      },
    ).length;
  }

  // LOGIC: Calculates progress as a value between 0 and 1.
  double get _progress {
    if (_goals.isEmpty) {
      return 0;
    }

    return _completedGoals / _goals.length;
  }

  // LOGIC: Converts decimal progress into a percentage.
  int get _progressPercentage {
    return (_progress * 100).round();
  }

  // LOGIC: Returns original indexes of goals matching the filter.
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

  // LOGIC: Changes the selected filter and rebuilds the screen.
  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // LOGIC: Reverses the done status of one goal.
  void _toggleGoal(int index) {
    final String subject = _goals[index]['subject'] as String;

    setState(() {
      final bool currentStatus = _goals[index]['done'] as bool;
      _goals[index]['done'] = !currentStatus;
    });

    final bool isDone = _goals[index]['done'] as bool;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // STATIC: Displays temporary feedback after changing a goal.
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

  // LOGIC: Opens AddGoalScreen and waits for a returned goal.
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

    // STATIC: Displays confirmation after adding a goal.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$subject was added successfully.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // LOGIC: Asks for confirmation before deleting a goal.
  Future<void> _confirmDelete(int index) async {
    final String subject = _goals[index]['subject'] as String;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // STATIC: Confirmation dialog interface.
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
              // CONNECTION POINT: UI calls logic and returns false.
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              // CONNECTION POINT: UI calls logic and returns true.
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

    // LOGIC: Saves a copy so the deletion can be undone.
    final Map<String, dynamic> deletedGoal =
        Map<String, dynamic>.from(_goals[index]);

    final int deletedIndex = index;

    // LOGIC: Removes the selected goal.
    setState(() {
      _goals.removeAt(index);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // STATIC: Shows an Undo action after deletion.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$subject deleted.'),
        action: SnackBarAction(
          label: 'UNDO',

          // CONNECTION POINT: UI calls logic to restore the goal.
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

  // LOGIC: Removes all completed goals after confirmation.
  Future<void> _clearCompletedGoals() async {
    if (_completedGoals == 0) {
      return;
    }

    final int completedCount = _completedGoals;

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // STATIC: Clear completed goals confirmation dialog.
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
              // CONNECTION POINT: UI closes without deleting.
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              // CONNECTION POINT: UI confirms the operation.
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

    // LOGIC: Saves completed goals and their original indexes.
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

    // LOGIC: Removes every completed goal.
    setState(() {
      _goals.removeWhere(
        (goal) {
          return goal['done'] == true;
        },
      );
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // STATIC: Shows the result and provides Undo.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$completedCount completed '
          '${completedCount == 1 ? 'goal was' : 'goals were'} removed.',
        ),
        action: SnackBarAction(
          label: 'UNDO',

          // CONNECTION POINT: UI calls logic to restore removed goals.
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
    // LOGIC: Calculates the currently visible indexes.
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

        // CONNECTION POINT: Logic values flow into the AppBar UI.
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_completedGoals / ${_goals.length} done',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      // STATIC: Main scrollable page layout.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STATIC: Welcome section.
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

          // STATIC: Statistics section title.
          const Text(
            'Study Overview',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // STATIC: Statistics card.
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

              // CONNECTION POINT:
              // Computed logic values flow into reusable StatItem widgets.
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

          // STATIC: Progress card.
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

                      // CONNECTION POINT:
                      // Calculated percentage flows from logic to UI.
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

                    // CONNECTION POINT:
                    // Decimal progress flows into the progress indicator.
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.indigo.shade100,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // CONNECTION POINT:
                  // Completed and total counts flow into UI text.
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

          // STATIC: Study tip banner.
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

          // STATIC: Goal list heading and clear button.
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

              // CONNECTION POINT:
              // Button calls logic only when completed goals exist.
              IconButton(
                onPressed:
                    _completedGoals > 0 ? _clearCompletedGoals : null,
                tooltip: 'Clear Completed Goals',
                icon: const Icon(Icons.cleaning_services),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // STATIC: Goal filter controls.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),

                // CONNECTION POINT: Logic controls chip selection.
                selected: _selectedFilter == 'All',

                // CONNECTION POINT: UI calls filter logic.
                onSelected: (_) {
                  _changeFilter('All');
                },
              ),
              ChoiceChip(
                label: const Text('Pending'),

                // CONNECTION POINT: Logic controls chip selection.
                selected: _selectedFilter == 'Pending',

                // CONNECTION POINT: UI calls filter logic.
                onSelected: (_) {
                  _changeFilter('Pending');
                },
              ),
              ChoiceChip(
                label: const Text('Done'),

                // CONNECTION POINT: Logic controls chip selection.
                selected: _selectedFilter == 'Done',

                // CONNECTION POINT: UI calls filter logic.
                onSelected: (_) {
                  _changeFilter('Done');
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // LOGIC: Conditional rendering for empty or non-empty lists.
          if (visibleIndexes.isEmpty)
            // STATIC: Empty-state interface.
            Container(
              height: 230,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CONNECTION POINT:
                  // Logic chooses which empty-state icon is displayed.
                  Icon(
                    _emptyIcon,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),

                  // CONNECTION POINT:
                  // Logic chooses which empty-state message is displayed.
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
            // LOGIC: Builds one goal card for every visible index.
            ...visibleIndexes.map(
              (originalIndex) {
                final Map<String, dynamic> goal =
                    _goals[originalIndex];

                final String subject = goal['subject'] as String;
                final int hours = goal['hours'] as int;
                final bool isDone = goal['done'] as bool;
                final Color subjectColor =
                    _getSubjectColor(subject);

                // STATIC: One goal card interface.
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),

                  // CONNECTION POINT:
                  // Done status controls the card colour.
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
                        // CONNECTION POINT:
                        // UI button calls toggle logic.
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

                        // STATIC: Subject icon.
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
                              // CONNECTION POINT:
                              // Subject and done status flow into styled text.
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDone
                                      ? Colors.green.shade800
                                      : Colors.black,

                                  // LOGIC: Done goals receive a strikethrough.
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // CONNECTION POINT:
                              // Planned hours flow from logic into UI.
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

                        // CONNECTION POINT:
                        // Done status selects the status label.
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

                        // CONNECTION POINT:
                        // Delete button calls confirmation logic.
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

      // STATIC: Floating button used to open AddGoalScreen.
      floatingActionButton: FloatingActionButton(
        // CONNECTION POINT:
        // UI button calls navigation logic.
        onPressed: _openAddGoalScreen,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// STATIC: Reusable statistics widget.
// It is used three times for Goals, Hours, and Done.
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

// LOGIC: AddGoalScreen is stateful because input errors can change.
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() {
    return _AddGoalScreenState();
  }
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: Controllers read text from the input fields.
  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _hoursController =
      TextEditingController();

  // LOGIC: These variables store validation error messages.
  String? _subjectError;
  String? _hoursError;

  // LOGIC: Validates input and returns a new goal.
  void _saveGoal() {
    final String subject = _subjectController.text.trim();
    final String hoursText = _hoursController.text.trim();
    final int? hours = int.tryParse(hoursText);

    String? subjectError;
    String? hoursError;

    // LOGIC: Validates the subject field.
    if (subject.isEmpty) {
      subjectError = 'Please enter a subject name.';
    }

    // LOGIC: Validates the hours field.
    if (hoursText.isEmpty) {
      hoursError = 'Please enter the number of hours.';
    } else if (hours == null) {
      hoursError = 'Hours must be a valid number.';
    } else if (hours <= 0) {
      hoursError = 'Hours must be greater than zero.';
    }

    // LOGIC: Updates validation messages on the screen.
    setState(() {
      _subjectError = subjectError;
      _hoursError = hoursError;
    });

    // LOGIC: Stops saving when validation fails.
    if (subjectError != null || hoursError != null) {
      return;
    }

    // LOGIC: Creates a new goal with default done status false.
    final Map<String, dynamic> newGoal = {
      'subject': subject,
      'hours': hours!,
      'done': false,
    };

    // CONNECTION POINT:
    // Logic sends the new goal back to HomeScreen.
    Navigator.pop(context, newGoal);
  }

  // LOGIC: Releases controller resources when the screen closes.
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

      // STATIC: Add Goal application bar.
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

      // STATIC: Add Goal screen content.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // STATIC: Add Goal introduction section.
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

            // STATIC: Subject input field.
            TextField(
              // CONNECTION POINT:
              // Controller transfers typed UI text into logic.
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Subject name',
                hintText: 'Example: Mobile Programming',
                prefixIcon: const Icon(Icons.menu_book),

                // CONNECTION POINT:
                // Logic error message flows into the input field.
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

              // CONNECTION POINT:
              // UI typing calls logic to clear an old error.
              onChanged: (_) {
                if (_subjectError != null) {
                  setState(() {
                    _subjectError = null;
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            // STATIC: Hours input field.
            TextField(
              // CONNECTION POINT:
              // Controller transfers typed UI text into logic.
              controller: _hoursController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Number of hours',
                hintText: 'Example: 3',
                prefixIcon: const Icon(Icons.schedule),

                // CONNECTION POINT:
                // Logic error message flows into the input field.
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

              // CONNECTION POINT:
              // UI typing calls logic to clear an old error.
              onChanged: (_) {
                if (_hoursError != null) {
                  setState(() {
                    _hoursError = null;
                  });
                }
              },

              // CONNECTION POINT:
              // Keyboard submit action calls save logic.
              onSubmitted: (_) {
                _saveGoal();
              },
            ),

            const SizedBox(height: 28),

            // STATIC: Styled Save button.
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                // CONNECTION POINT:
                // UI button calls validation and save logic.
                onPressed: _saveGoal,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // STATIC: Cancel button.
            TextButton(
              // CONNECTION POINT:
              // UI button closes the screen without returning data.
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
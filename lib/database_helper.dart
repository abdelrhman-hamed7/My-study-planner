import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

// LOGIC: This class controls all SQLite database operations.
class DatabaseHelper {
  // LOGIC: Private constructor prevents creating many instances.
  DatabaseHelper._internal();

  // LOGIC: One shared database helper instance.
  static final DatabaseHelper instance =
      DatabaseHelper._internal();

  // STATIC: Database and table information.
  static const String databaseName =
      'study_planner.db';

  static const int databaseVersion = 1;

  static const String goalsTable = 'goals';

  // LOGIC: Stores the opened database connection.
  Database? _database;

  // LOGIC: Returns the existing database or opens it.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();

    return _database!;
  }

  // LOGIC: Creates the database file path and opens it.
  Future<Database> _openDatabase() async {
    // LOGIC: Gets the correct database folder on the device.
    final String databasesPath =
        await getDatabasesPath();

    // LOGIC: Joins the folder with the database filename.
    final String fullDatabasePath = path.join(
      databasesPath,
      databaseName,
    );

    // LOGIC: Opens the database or creates it.
    return openDatabase(
      fullDatabasePath,
      version: databaseVersion,
      onCreate: _createDatabase,
    );
  }

  // LOGIC: Creates the goals table the first time the app opens.
  Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
    await database.execute(
      '''
      CREATE TABLE $goalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        hours INTEGER NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
      ''',
    );
  }

  // LOGIC: Converts Flutter data into SQLite data.
  Map<String, Object?> _convertGoalForDatabase(
    Map<String, dynamic> goal, {
    bool includeId = false,
  }) {
    final Map<String, Object?> databaseGoal = {
      'subject': goal['subject'] as String,
      'hours': goal['hours'] as int,

      // SQLite stores true as 1 and false as 0.
      'done': (goal['done'] as bool) ? 1 : 0,
    };

    // LOGIC: Include the id only when restoring deleted data.
    if (includeId && goal['id'] != null) {
      databaseGoal['id'] = goal['id'] as int;
    }

    return databaseGoal;
  }

  // LOGIC: Converts SQLite data into Flutter data.
  Map<String, dynamic> _convertGoalFromDatabase(
    Map<String, Object?> row,
  ) {
    return {
      'id': row['id'] as int,
      'subject': row['subject'] as String,
      'hours': row['hours'] as int,

      // SQLite 1 becomes true and 0 becomes false.
      'done': (row['done'] as int) == 1,
    };
  }

  // ============================================================
  // SELECT
  // ============================================================

  // LOGIC: Loads all saved goals from the database.
  Future<List<Map<String, dynamic>>>
      getAllGoals() async {
    final Database databaseConnection =
        await database;

    final List<Map<String, Object?>> rows =
        await databaseConnection.query(
      goalsTable,
      orderBy: 'id ASC',
    );

    return rows
        .map(
          (Map<String, Object?> row) {
            return _convertGoalFromDatabase(row);
          },
        )
        .toList();
  }

  // ============================================================
  // INSERT
  // ============================================================

  // LOGIC: Inserts a new goal and returns its generated id.
  Future<int> insertGoal(
    Map<String, dynamic> goal,
  ) async {
    final Database databaseConnection =
        await database;

    final int generatedId =
        await databaseConnection.insert(
      goalsTable,
      _convertGoalForDatabase(goal),
    );

    return generatedId;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  // LOGIC: Updates the subject, hours, and done status.
  Future<int> updateGoal(
    Map<String, dynamic> goal,
  ) async {
    final Database databaseConnection =
        await database;

    final int id = goal['id'] as int;

    return databaseConnection.update(
      goalsTable,
      _convertGoalForDatabase(goal),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // LOGIC: Updates only the done status.
  Future<int> updateGoalStatus({
    required int id,
    required bool done,
  }) async {
    final Database databaseConnection =
        await database;

    return databaseConnection.update(
      goalsTable,
      {
        // SQLite stores Boolean values as integers.
        'done': done ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  // LOGIC: Deletes one goal using its unique id.
  Future<int> deleteGoal(int id) async {
    final Database databaseConnection =
        await database;

    return databaseConnection.delete(
      goalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // LOGIC: Deletes every completed goal.
  Future<int> deleteCompletedGoals() async {
    final Database databaseConnection =
        await database;

    return databaseConnection.delete(
      goalsTable,
      where: 'done = ?',
      whereArgs: [1],
    );
  }

  // ============================================================
  // UNDO OPERATIONS
  // ============================================================

  // LOGIC: Restores one deleted goal with its original id.
  Future<void> restoreGoal(
    Map<String, dynamic> goal,
  ) async {
    final Database databaseConnection =
        await database;

    await databaseConnection.insert(
      goalsTable,
      _convertGoalForDatabase(
        goal,
        includeId: true,
      ),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // LOGIC: Restores several completed goals.
  Future<void> restoreGoals(
    List<Map<String, dynamic>> goals,
  ) async {
    final Database databaseConnection =
        await database;

    // LOGIC: Transaction performs all restorations together.
    await databaseConnection.transaction(
      (Transaction transaction) async {
        for (final Map<String, dynamic> goal
            in goals) {
          await transaction.insert(
            goalsTable,
            _convertGoalForDatabase(
              goal,
              includeId: true,
            ),
            conflictAlgorithm:
                ConflictAlgorithm.replace,
          );
        }
      },
    );
  }

  // LOGIC: Closes the database connection.
  Future<void> closeDatabase() async {
    final Database? currentDatabase = _database;

    if (currentDatabase != null) {
      await currentDatabase.close();
      _database = null;
    }
  }
}
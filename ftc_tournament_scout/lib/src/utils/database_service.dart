import 'dart:convert';

import 'package:ftc_tournament_scout/src/shared/classes/classes.dart';
import 'package:ftc_tournament_scout/src/shared/classes/team_stats.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../shared/classes/team.dart';
import 'result.dart';

class DatabaseService {
  DatabaseService({required this.databaseFactory});

  final DatabaseFactory databaseFactory;

  static const _kTableTeams = 'teams';
  static const _kColumnNumber = 'number';
  static const _kColumnName = 'name';
  static const _kColumnCustomTeamInfo = 'customTeamInfo';
  static const _kColumnTeamStats = 'teamStats';

  Database? _database;

  bool isOpen() => _database != null;

  Future<void> open() async {
    print(
      'Database path: ${join(await databaseFactory.getDatabasesPath(), 'app_database.db')}',
    );

    _database = await databaseFactory.openDatabase(
      join(await databaseFactory.getDatabasesPath(), 'app_database.db'),
      options: OpenDatabaseOptions(
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE $_kTableTeams($_kColumnNumber INTEGER PRIMARY KEY, $_kColumnName TEXT, $_kColumnCustomTeamInfo TEXT, $_kColumnTeamStats TEXT)',
          );
        },
        version: 1,
      ),
    );
  }

  Future<Result<Team>> insert(Team team) async {
    try {
      await _database!.insert(_kTableTeams, {
        _kColumnNumber: team.number,
        _kColumnName: team.name,
        _kColumnCustomTeamInfo: jsonEncode(team.customTeamInfo.toJson()),
        _kColumnTeamStats: jsonEncode(team.teamStats.toJson()),
      });
      return Result.ok(team);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Function to update team already in database. Team is selected based on the team number in the supplied team.
  /// The properties of the matching team in the database are updated based on the supplied team
  Future<Result<Team>> update(Team team) async {
    try {
      await _database!.update(
        _kTableTeams,
        {
          _kColumnName: team.name,
          _kColumnCustomTeamInfo: jsonEncode(team.customTeamInfo.toJson()),
          _kColumnTeamStats: jsonEncode(team.teamStats.toJson()),
        },
        where: '$_kColumnNumber = ?',
        whereArgs: [team.number],
      );
      return Result.ok(team);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Team>>> getAll() async {
    try {
      final entries = await _database!.query(
        _kTableTeams,
        columns: [
          _kColumnNumber,
          _kColumnName,
          _kColumnCustomTeamInfo,
          _kColumnTeamStats,
        ],
      );
      final list = entries
          .map(
            (element) => Team(
              number: element[_kColumnNumber] as int,
              name: element[_kColumnName] as String,
              customTeamInfo: CustomTeamInfo.fromJson(
                jsonDecode(element[_kColumnCustomTeamInfo] as String)
                    as Map<String, dynamic>,
              ),
              teamStats: TeamStats.fromJson(
                jsonDecode(element[_kColumnTeamStats] as String)
                    as Map<String, dynamic>,
              ),
            ),
          )
          .toList();
      return Result.ok(list);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(int teamNumber) async {
    try {
      final rowsDeleted = await _database!.delete(
        _kTableTeams,
        where: '$_kColumnNumber = ?',
        whereArgs: [teamNumber],
      );
      if (rowsDeleted == 0) {
        return Result.error(
          Exception('No team found with teamNumber: $teamNumber'),
        );
      }
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future close() async {
    await _database?.close();
    _database = null;
  }
}

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'sample_jobs.dart';

class LocalRepository {
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(p.join(await getDatabasesPath(), 'jobpilot.db'), version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE profile (id INTEGER PRIMARY KEY CHECK(id = 1), data TEXT NOT NULL)');
      await db.execute('CREATE TABLE jobs (id TEXT PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL, location TEXT NOT NULL, description TEXT NOT NULL, skills TEXT NOT NULL, source TEXT NOT NULL, application_url TEXT NOT NULL, score INTEGER NOT NULL, matched_skills TEXT NOT NULL, gaps TEXT NOT NULL, explanation TEXT NOT NULL, status TEXT NOT NULL, updated_at TEXT NOT NULL, error TEXT NOT NULL, is_sample INTEGER NOT NULL, UNIQUE(title, company, location, source))');
      await db.execute('CREATE TABLE status_history (id INTEGER PRIMARY KEY AUTOINCREMENT, job_id TEXT NOT NULL, status TEXT NOT NULL, changed_at TEXT NOT NULL, note TEXT NOT NULL)');
    });
    return _database!;
  }
  Future<void> seed() async {
    final db = await database;
    final batch = db.batch();
    for (final job in sampleJobs) {
      batch.insert('jobs', job.copyWith(updatedAt: DateTime.now().toUtc().toIso8601String()).toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
  Future<ResumeProfile> loadProfile() async {
    final rows = await (await database).query('profile', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? ResumeProfile() : ResumeProfile.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }
  Future<void> saveProfile(ResumeProfile profile) async {
    await (await database).insert('profile', {'id': 1, 'data': jsonEncode(profile.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<List<Job>> loadJobs() async => (await (await database).query('jobs', orderBy: 'score DESC, title ASC')).map(Job.fromRow).toList();
  Future<void> saveJobs(List<Job> jobs) async {
    final batch = (await database).batch();
    for (final job in jobs) {
      final row = job.toRow()..remove('id');
      batch.update('jobs', row, where: 'id = ?', whereArgs: [job.id]);
    }
    await batch.commit(noResult: true);
  }
  Future<void> updateStatus(Job job) async {
    final db = await database;
    await db.transaction((txn) async {
      final row = job.toRow()..remove('id');
      await txn.update('jobs', row, where: 'id = ?', whereArgs: [job.id]);
      await txn.insert('status_history', {'job_id': job.id, 'status': job.status.name, 'changed_at': job.updatedAt, 'note': job.error});
    });
  }
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('profile');
      await txn.delete('jobs');
      await txn.delete('status_history');
    });
  }
}

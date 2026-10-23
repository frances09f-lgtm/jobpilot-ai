import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../core/manual_job_service.dart';
import 'models.dart';

class LocalRepository {
  LocalRepository({this.databasePath});
  final String? databasePath;
  Database? _database;
  static const _jobsSql = 'CREATE TABLE jobs (id TEXT PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL, location TEXT NOT NULL, description TEXT NOT NULL, skills TEXT NOT NULL, source TEXT NOT NULL, application_url TEXT NOT NULL, score INTEGER NOT NULL, matched_skills TEXT NOT NULL, gaps TEXT NOT NULL, explanation TEXT NOT NULL, status TEXT NOT NULL, updated_at TEXT NOT NULL, error TEXT NOT NULL, UNIQUE(title, company, location, source))';
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(databasePath ?? p.join(await getDatabasesPath(), 'jobpilot.db'), version: 3,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE profile (id INTEGER PRIMARY KEY CHECK(id = 1), data TEXT NOT NULL)');
        await db.execute(_jobsSql);
        await db.execute('CREATE TABLE status_history (id INTEGER PRIMARY KEY AUTOINCREMENT, job_id TEXT NOT NULL, status TEXT NOT NULL, changed_at TEXT NOT NULL, note TEXT NOT NULL)');
      }, onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Remove legacy demo records AND their practice history. Keep real
          // listings, profile edits and the original resume. Drop demo metadata.
          await db.execute('DELETE FROM status_history WHERE job_id IN (SELECT id FROM jobs WHERE is_sample = 1)');
          await db.execute('DELETE FROM jobs WHERE is_sample = 1');
          await db.execute('ALTER TABLE jobs RENAME TO legacy_jobs');
          await db.execute(_jobsSql);
          await db.execute('INSERT INTO jobs (id,title,company,location,description,skills,source,application_url,score,matched_skills,gaps,explanation,status,updated_at,error) SELECT id,title,company,location,description,skills,source,application_url,score,matched_skills,gaps,explanation,status,updated_at,error FROM legacy_jobs');
          await db.execute('DROP TABLE legacy_jobs');
          await db.execute('DROP TABLE IF EXISTS app_settings');
        }
      });
    return _database!;
  }
  Future<ResumeProfile> loadProfile() async {
    final rows = await (await database).query('profile', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? ResumeProfile() : ResumeProfile.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }
  Future<void> saveProfile(ResumeProfile profile) async {
    await (await database).insert('profile', {'id': 1, 'data': jsonEncode(profile.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<List<Job>> loadJobs() async => (await (await database).query('jobs', orderBy: 'score DESC, title ASC')).map(Job.fromRow).toList();
  Future<void> addJob(Job job) async {
    await (await database).transaction((txn) async {
      final existing = (await txn.query('jobs')).map(Job.fromRow);
      if (existing.any((j) => ManualJobService.sameListing(j, job))) {
        throw const FormatException('This job is already saved. Open its existing tracker entry.');
      }
      await txn.insert('jobs', job.toRow());
    });
  }
  Future<void> saveJobs(List<Job> jobs) async {
    final batch = (await database).batch();
    for (final job in jobs) {
      final row = job.toRow()..remove('id');
      batch.update('jobs', row, where: 'id = ?', whereArgs: [job.id]);
    }
    await batch.commit(noResult: true);
  }
  Future<void> updateStatus(Job job) async {
    await (await database).transaction((txn) async {
      final row = job.toRow()..remove('id');
      await txn.update('jobs', row, where: 'id = ?', whereArgs: [job.id]);
      await txn.insert('status_history', {'job_id': job.id, 'status': job.status.name, 'changed_at': job.updatedAt, 'note': job.error});
    });
  }
  Future<void> clearAll() async {
    await (await database).transaction((txn) async {
      await txn.delete('profile');
      await txn.delete('jobs');
      await txn.delete('status_history');
    });
  }
  Future<void> close() async { await _database?.close(); _database = null; }
}

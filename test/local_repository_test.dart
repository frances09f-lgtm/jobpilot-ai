import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jobpilot_ai/data/local_repository.dart';
import 'package:jobpilot_ai/data/models.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late String path;
  setUp(() async { dir = await Directory.systemTemp.createTemp('jobpilot-test'); path = '${dir.path}/test.db'; });
  tearDown(() async { await dir.delete(recursive: true); });
  const real = Job(id: 'real', title: 'Flutter Developer', company: 'Test fixture', location: '', description: 'Dart', skills: ['Dart']);
  test('fresh database and clear stay empty; manual jobs persist and deduplicate', () async {
    final repo = LocalRepository(databasePath: path);
    try {
      expect(await repo.loadJobs(), isEmpty);
      await repo.addJob(real);
      await expectLater(repo.addJob(real), throwsFormatException);
      final updated = real.copyWith(status: ApplicationStatus.applied, error: 'Manually recorded', updatedAt: '2026-01-01T00:00:00Z');
      await repo.updateStatus(updated);
      expect((await repo.loadJobs()).single.status, ApplicationStatus.applied);
      expect(await (await repo.database).query('status_history'), hasLength(1));
      await repo.clearAll();
      expect(await repo.loadJobs(), isEmpty);
      expect(await (await repo.database).query('status_history'), isEmpty);
    } finally { await repo.close(); }
  });
  for (final version in [1, 2]) {
    test('upgrade v$version deletes legacy demo jobs/history and preserves real profile', () async {
      final legacy = await openDatabase(path, version: version, onCreate: (db, _) async {
        await db.execute('CREATE TABLE profile (id INTEGER PRIMARY KEY, data TEXT NOT NULL)');
        await db.execute('CREATE TABLE jobs (id TEXT PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL, location TEXT NOT NULL, description TEXT NOT NULL, skills TEXT NOT NULL, source TEXT NOT NULL, application_url TEXT NOT NULL, score INTEGER NOT NULL, matched_skills TEXT NOT NULL, gaps TEXT NOT NULL, explanation TEXT NOT NULL, status TEXT NOT NULL, updated_at TEXT NOT NULL, error TEXT NOT NULL, is_sample INTEGER NOT NULL)');
        await db.execute('CREATE TABLE status_history (id INTEGER PRIMARY KEY AUTOINCREMENT, job_id TEXT NOT NULL, status TEXT NOT NULL, changed_at TEXT NOT NULL, note TEXT NOT NULL)');
        if (version == 2) await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      });
      final legacyProfile = ResumeProfile(fields: {'name': 'Edited person', 'location': 'Edited city'}, rawText: 'saved text', resumePath: '/private/resume.pdf');
      // JSON comes from the public model, no personal user information.
      final helper = LocalRepository(databasePath: path);
      await legacy.insert('jobs', {...real.toRow(), 'is_sample': 0});
      await legacy.insert('jobs', {...real.toRow(), 'id': 'legacy-demo', 'is_sample': 1});
      for (final id in ['real', 'legacy-demo']) {
        await legacy.insert('status_history', {'job_id': id, 'status': 'applied', 'changed_at': '', 'note': ''});
      }
      await legacy.close();
      try {
        await helper.saveProfile(legacyProfile);
        expect((await helper.loadJobs()).map((j) => j.id), ['real']);
        expect((await helper.loadProfile()).get('location'), 'Edited city');
        expect((await helper.loadProfile()).resumePath, '/private/resume.pdf');
        final db = await helper.database;
        expect((await db.query('status_history')).single['job_id'], 'real');
        expect((await db.rawQuery('PRAGMA table_info(jobs)')).any((r) => r['name'] == 'is_sample'), isFalse);
        expect(await db.rawQuery("SELECT name FROM sqlite_master WHERE name = 'app_settings'"), isEmpty);
      } finally { await helper.close(); }
    });
  }
}

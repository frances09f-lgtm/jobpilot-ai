import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/matching_service.dart';
import 'package:jobpilot_ai/data/models.dart';
import 'package:jobpilot_ai/data/sample_jobs.dart';

void main() {
  final matcher = MatchingService();
  const job = Job(id: 'test', title: 'Flutter Developer', company: 'Sample', location: 'Pune', description: 'Sample', skills: ['Flutter', 'Dart']);
  test('full skills, inferred role and explicit location produce 100', () {
    final result = matcher.match(job, ResumeProfile(fields: {'skills': 'Flutter, Dart', 'location': 'Pune'}));
    expect(result.score, 100);
    expect(result.matchedSkills, ['Flutter', 'Dart']);
    expect(result.gaps, isEmpty);
    expect(result.status, ApplicationStatus.matched);
    expect(result.explanation, contains('Skills: 70/70'));
  });
  test('missing location receives no location points', () {
    expect(matcher.match(job, ResumeProfile(fields: {'skills': 'Flutter, Dart'})).score, 90);
  });
  test('partial match records gaps and bounded score', () {
    final result = matcher.match(job, ResumeProfile(fields: {'skills': 'Flutter'}));
    expect(result.score, 55);
    expect(result.gaps, ['Dart']);
  });
  test('empty profile scores zero and never guesses location', () {
    final result = matcher.match(job, ResumeProfile());
    expect(result.score, 0);
    expect(result.matchedSkills, isEmpty);
  });
  test('manual status is preserved when profile changes', () {
    final result = matcher.match(job.copyWith(status: ApplicationStatus.applied), ResumeProfile(fields: {'skills': 'Flutter, Dart'}));
    expect(result.status, ApplicationStatus.applied);
  });
  test('all samples have unique keys and no fake application URL', () {
    expect(sampleJobs.map((j) => j.id).toSet().length, sampleJobs.length);
    expect(sampleJobs.every((j) => j.isSample && j.applicationUrl.isEmpty), true);
    for (final sample in sampleJobs) {
      final result = matcher.match(sample, ResumeProfile(fields: {'skills': 'Flutter, Dart, Java, SQLite'}));
      expect(result.score, inInclusiveRange(0, 100));
    }
  });
  test('status row roundtrip stores every status, dates and errors', () {
    for (final status in ApplicationStatus.values) {
      final result = Job.fromRow(job.copyWith(status: status, updatedAt: '2026-01-01T00:00:00Z', error: 'User note').toRow());
      expect(result.status, status);
      expect(result.error, 'User note');
      expect(result.updatedAt, '2026-01-01T00:00:00Z');
    }
  });
}

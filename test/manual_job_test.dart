import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/manual_job_service.dart';
import 'package:jobpilot_ai/core/matching_service.dart';
import 'package:jobpilot_ai/data/models.dart';
void main() {
  final service = ManualJobService();
  Job job({String title = 'Flutter Developer', String company = 'Test company', String location = '', String url = ''}) => service.create(title: title, company: company, location: location, description: 'Build Flutter apps using Dart and SQLite.', applicationUrl: url, id: 'test-only');
  test('manual listing preserves supplied fields and empty unknowns', () {
    final j = job();
    expect(j.source, 'Manual'); expect(j.location, ''); expect(j.applicationUrl, '');
    expect(j.skills, ['Flutter', 'Dart', 'SQLite']);
    expect(Job.fromRow(j.toRow()).title, j.title);
  });
  test('manual jobs match and keep user tracker decisions', () {
    final j = MatchingService().match(job().copyWith(status: ApplicationStatus.applied), ResumeProfile(fields: {'skills': 'Flutter, Dart, SQLite'}));
    expect(j.score, greaterThan(70)); expect(j.status, ApplicationStatus.applied);
  });
  test('duplicate identity ignores case and extra whitespace', () {
    expect(ManualJobService.sameListing(job(), job(title: ' flutter  DEVELOPER ', company: ' TEST company ')), isTrue);
    expect(ManualJobService.sameListing(job(url: 'https://example.test/jobs/1'), job(title: 'Different', url: 'https://example.test/jobs/1#apply')), isTrue);
  });
  test('required fields and unsafe URLs are rejected', () {
    expect(() => job(title: ''), throwsFormatException);
    expect(() => job(url: 'javascript:alert(1)'), throwsFormatException);
    expect(() => job(url: 'http://example.test'), throwsFormatException);
    expect(() => job(url: 'https://user:secret@example.test'), throwsFormatException);
  });
}

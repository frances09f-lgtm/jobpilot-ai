import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/app/app_controller.dart';
import 'package:jobpilot_ai/data/models.dart';
import 'package:jobpilot_ai/data/sample_jobs.dart';
void main() {
  test('sample switch hides display records without deleting jobs or statuses', () {
    final jobs = [sampleJobs.first.copyWith(status: ApplicationStatus.ready)];
    final hidden = AppData(ResumeProfile(), jobs, hideSampleJobs: true);
    expect(hidden.visibleJobs, isEmpty);
    expect(hidden.jobs.single.status, ApplicationStatus.ready);
    expect(AppData(hidden.profile, hidden.jobs).visibleJobs.length, 1);
  });
  test('visibility never hides non-sample records', () {
    const real = Job(id: 'test-only', title: 'Test', company: 'Test', location: '', description: '', skills: [], isSample: false);
    expect(AppData(ResumeProfile(), [sampleJobs.first, real], hideSampleJobs: true).visibleJobs, [real]);
  });
}

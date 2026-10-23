import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/document_extractor.dart';
import '../core/matching_service.dart';
import '../core/resume_parser.dart';
import '../core/manual_job_service.dart';
import '../data/local_repository.dart';
import '../data/models.dart';

final repositoryProvider = Provider((ref) => LocalRepository());
final appProvider = AsyncNotifierProvider<AppController, AppData>(AppController.new);
class AppData {
  const AppData(this.profile, this.jobs);
  final ResumeProfile profile;
  final List<Job> jobs;
}
class AppController extends AsyncNotifier<AppData> {
  LocalRepository get repo => ref.read(repositoryProvider);
  @override
  Future<AppData> build() async {
    final stored = await repo.loadProfile();
    final profile = ResumeParser().prefillMissing(stored);
    if (profile.fields.toString() != stored.fields.toString()) await repo.saveProfile(profile);
    final jobs = (await repo.loadJobs()).map((j) => MatchingService().match(j, profile)).toList();
    await repo.saveJobs(jobs);
    return AppData(profile, jobs);
  }
  Future<ResumeProfile?> importResume({void Function(int)? onStage}) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    if (file == null) return null;
    onStage?.call(0);
    final length = file.lengthSync() ?? await file.length();
    if (length != null && length > DocumentExtractor.maxBytes) throw const FormatException('Choose a resume under 10 MB.');
    final bytes = await file.readAsBytes();
    onStage?.call(1);
    final text = await DocumentExtractor().extract(file.name, bytes);
    onStage?.call(2);
    final profile = ResumeParser().parse(text, resumeName: file.name);
    onStage?.call(3);
    final directory = await getApplicationDocumentsDirectory();
    final resumeDirectory = Directory(p.join(directory.path, 'resumes'));
    await resumeDirectory.create(recursive: true);
    final path = p.join(resumeDirectory.path, 'resume_${DateTime.now().microsecondsSinceEpoch}.${file.name.split('.').last.toLowerCase()}');
    await File(path).writeAsBytes(bytes, flush: true);
    return ResumeProfile(fields: profile.fields, rawText: text, resumePath: path, resumeName: file.name);
  }
  Future<void> saveProfile(ResumeProfile profile) async {
    final current = state.requireValue;
    final jobs = current.jobs.map((j) => MatchingService().match(j, profile)).toList();
    await repo.saveProfile(profile);
    await repo.saveJobs(jobs);
    state = AsyncData(AppData(profile, jobs));
    if (current.profile.resumePath.isNotEmpty && current.profile.resumePath != profile.resumePath) {
      final old = File(current.profile.resumePath);
      if (await old.exists()) await old.delete();
    }
  }
  Future<Job> addManualJob({required String title, required String company, required String location, required String description, required String applicationUrl}) async {
    final current = state.requireValue;
    final job = ManualJobService().create(title: title, company: company, location: location, description: description, applicationUrl: applicationUrl);
    final matched = MatchingService().match(job, current.profile);
    await repo.addJob(matched);
    state = AsyncData(AppData(current.profile, await repo.loadJobs()));
    return matched;
  }
  Future<void> setStatus(Job job, ApplicationStatus status, String note) async {
    final current = state.requireValue;
    final updated = job.copyWith(status: status, error: note, updatedAt: DateTime.now().toUtc().toIso8601String());
    await repo.updateStatus(updated);
    state = AsyncData(AppData(current.profile, current.jobs.map((j) => j.id == job.id ? updated : j).toList()));
  }
  Future<void> clearAll() async {
    final directory = await getApplicationDocumentsDirectory();
    final resumes = Directory(p.join(directory.path, 'resumes'));
    if (await resumes.exists()) await resumes.delete(recursive: true);
    await repo.clearAll();
    state = AsyncData(AppData(ResumeProfile(), const []));
  }
}

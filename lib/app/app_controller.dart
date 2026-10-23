import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/document_extractor.dart';
import '../core/matching_service.dart';
import '../core/resume_parser.dart';
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
    await repo.seed();
    final profile = await repo.loadProfile();
    final jobs = (await repo.loadJobs()).map((j) => MatchingService().match(j, profile)).toList();
    await repo.saveJobs(jobs);
    return AppData(profile, jobs);
  }

  Future<ResumeProfile?> importResume() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    if (file == null) return null;
    final length = file.lengthSync() ?? await file.length();
    if (length != null && length > DocumentExtractor.maxBytes) throw const FormatException('Choose a resume under 10 MB.');
    final bytes = await file.readAsBytes();
    final text = await DocumentExtractor().extract(file.name, bytes);
    final directory = await getApplicationDocumentsDirectory();
    final resumeDirectory = Directory(p.join(directory.path, 'resumes'));
    await resumeDirectory.create(recursive: true);
    final path = p.join(resumeDirectory.path, 'resume_${DateTime.now().microsecondsSinceEpoch}.${file.name.split('.').last.toLowerCase()}');
    await File(path).writeAsBytes(bytes, flush: true);
    return ResumeParser().parse(text, resumePath: path, resumeName: file.name);
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
    await repo.seed();
    state = AsyncData(AppData(ResumeProfile(), await repo.loadJobs()));
  }
}

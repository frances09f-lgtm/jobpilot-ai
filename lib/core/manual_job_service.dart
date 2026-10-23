import '../data/models.dart';
import 'resume_parser.dart';

/// User-entered listings only. No bundled listings and no network discovery.
class ManualJobService {
  static String normalize(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  static String? urlError(String value) {
    if (value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return 'Use an HTTPS application URL, or leave it empty.';
    }
    return null;
  }
  static String _url(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri == null ? value.trim() : uri.replace(fragment: '').toString();
  }
  static bool sameListing(Job a, Job b) =>
    (normalize(a.title) == normalize(b.title) && normalize(a.company) == normalize(b.company) && normalize(a.location) == normalize(b.location)) ||
    (a.applicationUrl.isNotEmpty && b.applicationUrl.isNotEmpty && _url(a.applicationUrl) == _url(b.applicationUrl));
  Job create({required String title, required String company, required String location, required String description, required String applicationUrl, String? id}) {
    if (title.trim().isEmpty || company.trim().isEmpty || description.trim().isEmpty) {
      throw const FormatException('Title, company and description are required.');
    }
    final error = urlError(applicationUrl);
    if (error != null) throw FormatException(error);
    final now = DateTime.now().toUtc();
    return Job(id: id ?? 'manual-${now.microsecondsSinceEpoch}', title: title.trim(), company: company.trim(), location: location.trim(),
      description: description.trim(), applicationUrl: applicationUrl.trim(), source: 'Manual',
      skills: ResumeParser.knownSkills.where((s) => ResumeParser.containsTerm(description, s)).toList(), updatedAt: now.toIso8601String());
  }
}

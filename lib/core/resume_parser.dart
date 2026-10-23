import '../data/models.dart';

/// Candidate fields copied from text, never supplied from defaults or a model.
/// Every candidate is reviewed in the profile editor before use.
class ResumeParser {
  static const knownSkills = <String>['Flutter', 'Dart', 'Kotlin', 'Java', 'Python', 'JavaScript', 'TypeScript', 'React', 'Node.js', 'SQL', 'SQLite', 'Firebase', 'REST', 'Git', 'HTML', 'CSS', 'Excel', 'Power BI', 'C++', 'C#', 'Swift', 'Android', 'iOS', 'Docker', 'AWS'];
  static const sectionNames = <String, String>{
    'education': 'education', 'academic qualifications': 'education',
    'experience': 'experience', 'work experience': 'experience', 'employment': 'experience',
    'skills': 'skills', 'technical skills': 'skills', 'technologies': 'skills',
    'projects': 'projects', 'personal projects': 'projects',
    'certifications': 'certifications', 'certificates': 'certifications',
    'summary': '_skip', 'professional summary': '_skip', 'objective': '_skip',
    'contact': '_skip', 'contact details': '_skip', 'interests': '_skip', 'languages': '_skip', 'achievements': '_skip',
  };
  static bool containsTerm(String text, String term) => RegExp('(?<![a-zA-Z0-9])${RegExp.escape(term)}(?![a-zA-Z0-9])', caseSensitive: false).hasMatch(text);

  ResumeProfile parse(String text, {String resumePath = '', String resumeName = ''}) {
    final result = {for (final key in profileFields) key: ''};
    final lines = text.replaceAll('\r', '').split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    result['email'] = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}').firstMatch(text)?.group(0) ?? '';
    result['phone'] = RegExp(r'(?<!\d)(?:\+\d{1,3}[\s\-]?)?(?:\(?\d{3}\)?[\s\-]?)?\d{3}[\s\-]?\d{4}(?!\d)').firstMatch(text)?.group(0) ?? '';
    String? section;
    final sections = <String, List<String>>{};
    for (final line in lines) {
      final colon = line.indexOf(':');
      final heading = (colon >= 0 ? line.substring(0, colon) : line).trim().toLowerCase();
      if (sectionNames.containsKey(heading)) {
        section = sectionNames[heading];
        if (colon >= 0 && line.substring(colon + 1).trim().isNotEmpty) {
          sections.putIfAbsent(section!, () => []).add(line.substring(colon + 1).trim());
        }
        continue;
      }
      if (section != null && section != '_skip') sections.putIfAbsent(section, () => []).add(line);
      for (final field in ['name', 'location', 'roles']) {
        final aliases = field == 'location' ? 'location|address|city' : field == 'roles' ? 'role|job title|target role|roles' : 'name|full name';
        final match = RegExp('^(?:$aliases)\\s*:\\s*(.+)\$', caseSensitive: false).firstMatch(line);
        if (match != null) result[field] = match.group(1)!.trim();
      }
    }
    // Top-line names are deliberately not guessed. Unlabelled name/address stay empty.
    for (final field in ['education', 'experience', 'projects', 'certifications']) {
      result[field] = sections[field]?.join('\n') ?? '';
    }
    result['skills'] = sections['skills']?.join('\n') ?? knownSkills.where((s) => containsTerm(text, s)).join(', ');
    return ResumeProfile(fields: result, rawText: text, resumePath: resumePath, resumeName: resumeName);
  }

  /// Suggestions, not employment or eligibility facts; kept separate from fields.
  List<String> suggestedRoles(ResumeProfile profile) {
    final skills = profile.get('skills');
    return [
      if (containsTerm(skills, 'Flutter')) 'Flutter Developer',
      if (containsTerm(skills, 'Java')) 'Java Developer',
      if (containsTerm(skills, 'Python') && containsTerm(skills, 'SQL')) 'Data Analyst',
      if (containsTerm(skills, 'React') || containsTerm(skills, 'JavaScript')) 'Web Developer',
      if (containsTerm(skills, 'Kotlin') || containsTerm(skills, 'Android')) 'Android Developer',
    ];
  }
}

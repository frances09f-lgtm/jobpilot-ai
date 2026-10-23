import '../data/models.dart';
import 'resume_location_parser.dart';

/// Copies resume evidence only. Uncertain fields remain empty for review.
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
  static final _email = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
  static bool containsTerm(String text, String term) => RegExp('(?<![a-zA-Z0-9])${RegExp.escape(term)}(?![a-zA-Z0-9])', caseSensitive: false).hasMatch(text);
  static String normalizeText(String text) => text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll('\u00a0', ' ').replaceAll('\u200b', '').replaceAll('\ufeff', '').replaceAll('ﬁ', 'fi').replaceAll('ﬂ', 'fl');
  static String _heading(String line) => line.split(':').first.trim().toLowerCase();
  static String _phone(String text) {
    // Horizontal whitespace only prevents joining education years across lines.
    for (final line in text.split('\n')) {
      for (final m in RegExp(r'(?<![\w])\+?\d(?:[ \t().\-]*\d){8,14}(?!\d)').allMatches(line)) {
        final value = m.group(0)!.trim();
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 10 || digits.length > 15) continue;
        if (!value.startsWith('+') && digits.length != 10) continue;
        if (RegExp(r'\d{4}\s*-\s*\d{4}').hasMatch(value)) continue;
        return value;
      }
    }
    return '';
  }
  static bool _nameLike(String value) {
    if (value.length > 70 || !RegExp(r"^[\p{L}][\p{L}\p{M} .’'\-]+$", unicode: true).hasMatch(value)) return false;
    final words = value.split(RegExp(r'\s+'));
    if (words.length < 2 || words.length > 5) return false;
    const rejected = ['resume', 'curriculum', 'vitae', 'developer', 'engineer', 'designer', 'analyst', 'manager', 'intern', 'student', 'university', 'college', 'contact', 'summary', 'objective', 'profile', 'skills', 'experience', 'education', 'mobile', 'software', 'application', 'applications', 'technical', 'professional', 'personal', 'address', 'location', 'projects'];
    if (rejected.any((word) => containsTerm(value, word))) return false;
    return words.every((word) => word.isNotEmpty && word[0] == word[0].toUpperCase());
  }
  ResumeProfile parse(String text, {String resumePath = '', String resumeName = ''}) {
    final normalized = normalizeText(text);
    final result = {for (final key in profileFields) key: ''};
    final lines = normalized.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    result['email'] = _email.firstMatch(normalized)?.group(0) ?? '';
    result['phone'] = _phone(normalized);
    String? section;
    final sections = <String, List<String>>{};
    for (final line in lines) {
      final colon = line.indexOf(':');
      final heading = _heading(line);
      if (sectionNames.containsKey(heading)) {
        section = sectionNames[heading];
        if (colon >= 0 && line.substring(colon + 1).trim().isNotEmpty) {
          sections.putIfAbsent(section!, () => []).add(line.substring(colon + 1).trim());
        }
        continue;
      }
      var identity = false;
      for (final field in ['name', 'roles']) {
        final aliases = field == 'location' ? 'location|address|city' : field == 'roles' ? 'role|job title|target role|roles' : 'name|full name';
        final match = RegExp('^(?:$aliases)\\s*[:|]\\s*(.+)\$', caseSensitive: false).firstMatch(line);
        if (match != null) {
          result[field] = match.group(1)!.trim();
          identity = true;
        }
      }
      if (!identity && section != null && section != '_skip') {
        sections.putIfAbsent(section, () => []).add(line);
      }
    }
    // An unlabelled name is a review candidate only in the contact header with
    // email/phone nearby. Never derive identity from an email or file name.
    final header = <String>[];
    for (final line in lines.take(10)) {
      final heading = _heading(line);
      if (sectionNames.containsKey(heading) && !['contact', 'contact details'].contains(heading)) break;
      header.add(line);
    }
    final contactHeader = header.any((l) => _email.hasMatch(l) || _phone(l).isNotEmpty);
    if (result['name']!.isEmpty && contactHeader) {
      final candidates = header.take(4).map((l) => l.split(RegExp(r'\s*[|•]\s*')).first.trim()).where((v) => _nameLike(v) && !ResumeLocationParser.locationShape(v)).toList();
      if (candidates.length == 1) result['name'] = candidates.single;
    }
    result['location'] = ResumeLocationParser().parse(lines, header);
    for (final field in ['education', 'experience', 'projects', 'certifications']) {
      result[field] = sections[field]?.join('\n') ?? '';
    }
    result['skills'] = sections['skills']?.join('\n') ?? knownSkills.where((s) => containsTerm(normalized, s)).join(', ');
    return ResumeProfile(fields: result, rawText: text, resumePath: resumePath, resumeName: resumeName);
  }
  /// Fills old blanks from stored text without overwriting existing user edits.
  ResumeProfile prefillMissing(ResumeProfile current) {
    if (current.rawText.trim().isEmpty) return current;
    final parsed = parse(current.rawText);
    return ResumeProfile(fields: {for (final key in profileFields) key: current.get(key).trim().isEmpty ? parsed.get(key) : current.get(key)}, rawText: current.rawText, resumePath: current.resumePath, resumeName: current.resumeName);
  }
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

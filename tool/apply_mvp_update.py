"""Idempotent source migration for the Phase 1 maintenance release. No network."""
from pathlib import Path

def write(path, content):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding='utf-8')

def replace(path, old, new):
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    if old not in text:
        if new in text:
            return
        raise RuntimeError(f'Migration anchor missing: {path}: {old[:80]}')
    p.write_text(text.replace(old, new), encoding='utf-8')

write('lib/core/resume_parser.dart', r'''import '../data/models.dart';

/// Only copies evidence in resume text. Uncertain fields stay empty for review.
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
    // Horizontal whitespace only: years on adjacent lines must not become a phone.
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
    return words.every((word) => word.isNotEmpty && (word[0] == word[0].toUpperCase()));
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
        if (colon >= 0 && line.substring(colon + 1).trim().isNotEmpty) sections.putIfAbsent(section!, () => []).add(line.substring(colon + 1).trim());
        continue;
      }
      var identity = false;
      for (final field in ['name', 'location', 'roles']) {
        final aliases = field == 'location' ? 'location|address|city' : field == 'roles' ? 'role|job title|target role|roles' : 'name|full name';
        final match = RegExp('^(?:$aliases)\\s*[:|]\\s*(.+)\$', caseSensitive: false).firstMatch(line);
        if (match != null) { result[field] = match.group(1)!.trim(); identity = true; }
      }
      if (!identity && section != null && section != '_skip') sections.putIfAbsent(section, () => []).add(line);
    }
    // Unlabelled name is a review candidate only in the contact header, with
    // an actual email/phone nearby. Never derive a name from an email/filename.
    final header = <String>[];
    for (final line in lines.take(10)) {
      final heading = _heading(line);
      if (sectionNames.containsKey(heading) && !['contact', 'contact details'].contains(heading)) break;
      header.add(line);
    }
    final contactHeader = header.any((l) => _email.hasMatch(l) || _phone(l).isNotEmpty);
    if (result['name']!.isEmpty && contactHeader) {
      final candidates = header.take(4).map((l) => l.split(RegExp(r'\s*[|•]\s*')).first.trim()).where(_nameLike).toList();
      if (candidates.length == 1) result['name'] = candidates.single;
    }
    if (result['location']!.isEmpty && contactHeader) {
      final candidates = <String>[];
      for (final line in header) {
        for (final segment in line.split(RegExp(r'[|•]'))) {
          final value = segment.trim();
          // Copy a place-shaped contact segment; no city database/default.
          if (value.contains(',') && !value.contains('@') && value.length < 100 &&
              RegExp(r'^[\p{L}\p{M} .\-]+,\s*[\p{L}\p{M} ,\-]+(?:\s+\d{4,8})?$', unicode: true).hasMatch(value) &&
              !knownSkills.any((s) => containsTerm(value, s)) && !_nameLike(value.replaceAll(',', ' '))) {
            candidates.add(value);
          }
        }
      }
      // A comma-separated place also looks like a name after punctuation is
      // removed, so accept it only when the first name candidate is separate.
      if (candidates.isEmpty && result['name']!.isNotEmpty) {
        for (final line in header) {
          for (final segment in line.split(RegExp(r'[|•]'))) {
            final value = segment.trim();
            if (value.contains(',') && !value.contains('@') && value.length < 100 &&
                RegExp(r'^[\p{L}\p{M} .\-]+,\s*[\p{L}\p{M} ,\-]+(?:\s+\d{4,8})?$', unicode: true).hasMatch(value) &&
                !knownSkills.any((s) => containsTerm(value, s)) && value != result['name']) candidates.add(value);
          }
        }
      }
      if (candidates.toSet().length == 1) result['location'] = candidates.first;
    }
    for (final field in ['education', 'experience', 'projects', 'certifications']) { result[field] = sections[field]?.join('\n') ?? ''; }
    result['skills'] = sections['skills']?.join('\n') ?? knownSkills.where((s) => containsTerm(normalized, s)).join(', ');
    return ResumeProfile(fields: result, rawText: text, resumePath: resumePath, resumeName: resumeName);
  }

  /// Upgrade old profiles from their stored text without overwriting user edits.
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
''')

replace('lib/core/document_extractor.dart', "      return text;", "      return text;") if False else None
replace('lib/core/document_extractor.dart', "    final xml = XmlDocument.parse(utf8.decode(document.content));\n    return xml.descendants", "    final extras = archive.files.where((f) => RegExp(r'^word/(?:header|footer)\\d+\\.xml$').hasMatch(f.name)).toList()..sort((a, b) => a.name.compareTo(b.name));\n    final parts = [...extras.where((f) => f.name.contains('/header')), document, ...extras.where((f) => f.name.contains('/footer'))];\n    if (parts.fold<int>(0, (sum, f) => sum + f.size) > 2 * 1024 * 1024) throw const FormatException('DOCX text exceeds the 2 MB extraction limit.');\n    return parts.map((part) => _paragraphs(utf8.decode(part.content))).join('\\n');\n  }\n\n  String _paragraphs(String source) {\n    final xml = XmlDocument.parse(source);\n    return xml.descendants")

replace('lib/data/local_repository.dart', "version: 1, onCreate:", "version: 2, onCreate:")
replace('lib/data/local_repository.dart', "      });\n      return _database!;", "        await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');\n      }, onUpgrade: (db, oldVersion, newVersion) async {\n        if (oldVersion < 2) await db.execute('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');\n      });\n      return _database!;")
replace('lib/data/local_repository.dart', "    Future<void> clearAll() async {", "    Future<bool> loadHideSampleJobs() async {\n      final rows = await (await database).query('app_settings', where: 'key = ?', whereArgs: ['hide_sample_jobs']);\n      return rows.isNotEmpty && rows.first['value'] == 'true';\n    }\n    Future<void> saveHideSampleJobs(bool value) async {\n      await (await database).insert('app_settings', {'key': 'hide_sample_jobs', 'value': value.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);\n    }\n    Future<void> clearAll() async {")
replace('lib/data/local_repository.dart', "        await txn.delete('status_history');", "        await txn.delete('status_history');\n        await txn.delete('app_settings');")

replace('lib/app/app_controller.dart', '    const AppData(this.profile, this.jobs);', '    const AppData(this.profile, this.jobs, {this.hideSampleJobs = false});')
replace('lib/app/app_controller.dart', '    final List<Job> jobs;', '    final List<Job> jobs;\n    final bool hideSampleJobs;\n    List<Job> get visibleJobs => jobs.where((j) => !hideSampleJobs || !j.isSample).toList();')
replace('lib/app/app_controller.dart', '      final profile = await repo.loadProfile();', '      final stored = await repo.loadProfile();\n      final profile = ResumeParser().prefillMissing(stored);\n      if (profile.fields.toString() != stored.fields.toString()) await repo.saveProfile(profile);')
replace('lib/app/app_controller.dart', '      return AppData(profile, jobs);', '      return AppData(profile, jobs, hideSampleJobs: await repo.loadHideSampleJobs());')
replace('lib/app/app_controller.dart', '      state = AsyncData(AppData(profile, jobs));', '      state = AsyncData(AppData(profile, jobs, hideSampleJobs: current.hideSampleJobs));')
replace('lib/app/app_controller.dart', 'current.jobs.map((j) => j.id == job.id ? updated : j).toList()));', 'current.jobs.map((j) => j.id == job.id ? updated : j).toList(), hideSampleJobs: current.hideSampleJobs));')
replace('lib/app/app_controller.dart', '    Future<void> clearAll() async {', '    Future<void> setHideSampleJobs(bool value) async {\n      final current = state.requireValue;\n      await repo.saveHideSampleJobs(value);\n      state = AsyncData(AppData(current.profile, current.jobs, hideSampleJobs: value));\n    }\n    Future<void> clearAll() async {')

write('lib/features/pilot_logo.dart', '''import 'package:flutter/material.dart';

/// Original vector artwork, matching the Android launcher. No fonts or network.
class PilotLogo extends StatelessWidget {
  const PilotLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(label: 'JobPilot AI logo', image: true, child: SizedBox(width: size, height: size, child: CustomPaint(painter: _PilotLogoPainter())));
}
class _PilotLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(24)), Paint()..color = const Color(0xFF0A0F1F));
    final plane = Path()..moveTo(24, 48)..lineTo(84, 26)..lineTo(62, 84)..lineTo(50, 61)..close();
    canvas.drawPath(plane, Paint()..shader = const LinearGradient(colors: [Color(0xFF5B8CFF), Color(0xFFA78BFA)]).createShader(const Rect.fromLTWH(24, 26, 60, 58)));
    final fold = Path()..moveTo(50, 61)..lineTo(84, 26)..lineTo(40, 54)..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFF263863));
    final shine = Path()..moveTo(24, 48)..lineTo(84, 26)..lineTo(40, 54)..close();
    canvas.drawPath(shine, Paint()..color = const Color(0xFF93B4FF));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
''')

replace('lib/features/home_screen.dart', "import 'ui_components.dart';", "import 'ui_components.dart';\nimport 'pilot_logo.dart';")
replace('lib/features/home_screen.dart', "          Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [blue, violet])), child: const Text('JP', style: TextStyle(color: Color(0xFF08101F), fontSize: 14, fontWeight: FontWeight.w800))),", "          const PilotLogo(size: 32),")
replace('lib/features/home_screen.dart', "Icon(Icons.upload_file_rounded, color: violet, size: 42)", "PilotLogo(size: 72)")
replace('lib/features/home_screen.dart', 'data.jobs', 'data.visibleJobs')
replace('lib/features/home_screen.dart', "'Ranked by your local match score. All ${data.visibleJobs.length} listings are samples.'", "data.hideSampleJobs ? 'Sample jobs are hidden. Live jobs are not included in Phase 1.' : 'Fictional demo jobs, not real vacancies. Ranked by your resume match score.'")
replace('lib/features/home_screen.dart', "'No sample jobs match this search or filter'", "'No visible jobs. Samples may be hidden in Settings or excluded by your filter.'")
replace('lib/features/home_screen.dart', "sectionHeading('Top matches'), PilotCard(child: Column(children: top.take(3).map((j) => _mini(j, score: true)).toList()))", "if (data.hideSampleJobs) const PilotCard(child: Text('Sample jobs are hidden. Phase 1 has no live vacancies. Show samples again in Settings.', style: TextStyle(color: muted))), sectionHeading('Top matches'), PilotCard(child: top.isEmpty ? const Text('No visible matches', style: TextStyle(color: muted)) : Column(children: top.take(3).map((j) => _mini(j, score: true)).toList()))")

replace('lib/features/settings_screen.dart', '      final body = ListView', '      final data = ref.watch(appProvider).value;\n      final body = ListView')
replace('lib/features/settings_screen.dart', "        PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [", "        PilotCard(child: SwitchListTile(contentPadding: EdgeInsets.zero, value: data?.hideSampleJobs ?? false, title: const Text('Hide sample jobs'), subtitle: const Text('Demo listings only, not real vacancies. This hides them from Home, Jobs and Tracker without deleting records. Live jobs come in Phase 2.'), onChanged: data == null ? null : (value) async {\n          try { await ref.read(appProvider.notifier).setHideSampleJobs(value); }\n          catch (e) { if (mounted) setState(() => message = 'Could not save sample visibility: $e'); }\n        })),\n        PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [")

replace('lib/features/profile_screen.dart', "        ExpansionTile(title:", "        if (widget.profile.rawText.isNotEmpty) TextButton(onPressed: () {\n          final current = ResumeProfile(fields: {for (final entry in controllers.entries) entry.key: entry.value.text}, rawText: widget.profile.rawText);\n          final filled = ResumeParser().prefillMissing(current);\n          setState(() { for (final key in profileFields) { controllers[key]!.text = filled.get(key); } });\n        }, child: const Text('Fill empty fields from saved resume')),\n        ExpansionTile(title:")

write('test/resume_prefill_test.dart', r'''import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
import 'package:jobpilot_ai/data/models.dart';

const sampleResumeText = 'MIRA DESAI\nFlutter Developer\nmira@example.test | +91 98765 43210 | Pune, Maharashtra\nTechnical Skills: Flutter, Dart, Firebase\nEducation\nB.Tech Computer Science\nExperience\nFlutter Developer at Fictional Studio';
void main() {
  final parser = ResumeParser();
  test('unlabelled resume header prefills copied identity and skills', () {
    final p = parser.parse(sampleResumeText);
    expect(p.get('name'), 'MIRA DESAI');
    expect(p.get('email'), 'mira@example.test');
    expect(p.get('phone'), '+91 98765 43210');
    expect(p.get('location'), 'Pune, Maharashtra');
    expect(p.get('skills'), 'Flutter, Dart, Firebase');
    expect(p.get('education'), 'B.Tech Computer Science');
    expect(p.get('projects'), '');
    expect(p.get('certifications'), '');
    expect(p.get('roles'), '');
  });
  test('CR-only and nonbreaking-space extraction preserves fields', () {
    final p = parser.parse('Name: Mira Desai\rEmail: mira@example.test\rPhone: +91\u00a098765\u00a043210\rCity: Pune\rSkills: Dart');
    expect(p.get('name'), 'Mira Desai');
    expect(p.get('phone'), '+91 98765 43210');
    expect(p.get('location'), 'Pune');
  });
  test('missing identity is not inferred from email or resume file name', () {
    final p = parser.parse('mira@example.test\nSkills: Dart', resumeName: 'Mira_Desai.pdf');
    expect(p.get('name'), ''); expect(p.get('location'), ''); expect(p.get('phone'), '');
  });
  test('job titles and ambiguous two names are not a person candidate', () {
    expect(parser.parse('Flutter Developer\nmira@example.test\nSkills: Dart').get('name'), '');
    expect(parser.parse('MIRA DESAI\nANOTHER PERSON\nmira@example.test\nSkills: Dart').get('name'), '');
  });
  test('years on adjacent lines cannot become a phone number', () {
    expect(parser.parse('Education\n2020\n2024\n2025').get('phone'), '');
  });
  test('upgrading stored resume fills blanks and preserves edits and metadata', () {
    final p = parser.prefillMissing(ResumeProfile(fields: {'email': 'edited@example.test', 'location': 'Edited city'}, rawText: sampleResumeText, resumePath: '/local/resume.pdf', resumeName: 'resume.pdf'));
    expect(p.get('name'), 'MIRA DESAI'); expect(p.get('email'), 'edited@example.test');
    expect(p.get('location'), 'Edited city'); expect(p.resumePath, '/local/resume.pdf');
    expect(p.resumeName, 'resume.pdf'); expect(p.rawText, sampleResumeText);
  });
}
''')
write('test/sample_visibility_test.dart', '''import 'package:flutter_test/flutter_test.dart';
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
''')
write('test/profile_prefill_widget_test.dart', '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
import 'package:jobpilot_ai/features/profile_screen.dart';
import 'package:jobpilot_ai/features/pilot_logo.dart';
import 'resume_prefill_test.dart' show sampleResumeText;
void main() {
  testWidgets('profile editor displays extracted identity before saving', (tester) async {
    final profile = ResumeParser().parse(sampleResumeText);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: ProfileScreen(profile: profile))));
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, 'MIRA DESAI');
    expect(fields[1].controller!.text, 'mira@example.test');
    expect(fields[2].controller!.text, '+91 98765 43210');
    expect(fields[3].controller!.text, 'Pune, Maharashtra');
    expect(tester.takeException(), isNull);
  });
  testWidgets('original vector logo renders with accessible label', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PilotLogo())));
    expect(find.byType(PilotLogo), findsOneWidget);
    expect(find.bySemanticsLabel('JobPilot AI logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
''')
write('test/docx_header_test.dart', '''import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/document_extractor.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
void main() {
  test('DOCX identity in a header reaches the parser before body skills', () async {
    final zip = Archive()
      ..addFile(ArchiveFile.string('word/header1.xml', '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>MIRA DESAI</w:t></w:r></w:p><w:p><w:r><w:t>mira@example.test</w:t></w:r></w:p></w:hdr>'))
      ..addFile(ArchiveFile.string('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Skills: Dart</w:t></w:r></w:p></w:body></w:document>'));
    final text = await DocumentExtractor().extract('fictional.docx', Uint8List.fromList(ZipEncoder().encode(zip)));
    final profile = ResumeParser().parse(text);
    expect(profile.get('name'), 'MIRA DESAI');
    expect(profile.get('email'), 'mira@example.test');
    expect(profile.get('skills'), 'Dart');
  });
}
''')

vector = '''<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  {background}
  <path android:pathData="M24,48 L84,26 L62,84 L50,61 Z" android:fillColor="#5B8CFF">
    <aapt:attr name="android:fillColor"><gradient android:type="linear" android:startX="24" android:startY="26" android:endX="84" android:endY="84" android:startColor="#5B8CFF" android:endColor="#A78BFA" /></aapt:attr>
  </path>
  <path android:pathData="M50,61 L84,26 L40,54 Z" android:fillColor="#263863" />
  <path android:pathData="M24,48 L84,26 L40,54 Z" android:fillColor="#93B4FF" />
</vector>
'''
write('android/app/src/main/res/drawable/jobpilot_foreground.xml', vector.format(background=''))
write('android/app/src/main/res/mipmap-anydpi/jobpilot_logo.xml', vector.format(background='<path android:pathData="M0,0 H108 V108 H0 Z" android:fillColor="#0A0F1F" />'))
write('android/app/src/main/res/mipmap-anydpi-v26/jobpilot_logo.xml', '''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/pilot_navy" />
  <foreground android:drawable="@drawable/jobpilot_foreground" />
</adaptive-icon>
''')
write('android/app/src/main/res/values/pilot_colors.xml', '<resources><color name="pilot_navy">#0A0F1F</color></resources>\n')
replace('android/app/src/main/AndroidManifest.xml', 'android:icon="@mipmap/ic_launcher"', 'android:icon="@mipmap/jobpilot_logo"')
replace('pubspec.yaml', 'version: 0.1.0+1', 'version: 0.1.0+2')

replace('README.md', 'Unlabelled names/addresses deliberately require manual entry.', 'Names in contact headers are copied as review candidates when a nearby email or phone supports the header. Explicit labels and comma-separated header locations are supported; ambiguous fields stay empty. Stored resume text fills previously empty fields without overwriting edits.')
replace('README.md', 'flutter build apk --release\n', 'flutter build apk --release --target-platform android-arm64 --split-debug-info=build/symbols\n')
replace('README.md', 'Names and addresses without labels remain blank.', 'Ambiguous names and locations stay blank. Header name candidates are heuristic and must be reviewed.')
replace('README.md', 'DOCX extraction reads body paragraphs, not headers/footers/images.', 'DOCX extraction includes body and header/footer paragraphs, not images.')
replace('README.md', 'No network requests are made by the MVP app; HTTP is reserved for later phases.', 'No network requests are made by the MVP app. The unused direct HTTP dependency was removed; dependencies may still use it transitively.')
replace('README.md', '- Search/filter sample jobs,', '- A persistent Hide sample jobs switch hides fictional jobs from dashboard, recommendations and tracker without deleting practice records. Live jobs remain out of scope.\n- Original navy/blue/violet vector launcher logo is also shown on upload and in the app bar. No paid generation or external login.\n- Search/filter sample jobs,')
print('Phase 1 maintenance sources prepared; CI must analyze, test and build before publishing.')

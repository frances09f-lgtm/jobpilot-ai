import 'package:flutter_test/flutter_test.dart';
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

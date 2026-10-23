import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
import 'package:jobpilot_ai/data/models.dart';

void main() {
  final parser = ResumeParser();
  test('copies explicit identity and section text without fabricating fields', () {
    final profile = parser.parse('Name: Example Person\nEmail: example@example.com\nPhone: +91 9876543210\nLocation: Pune\nEducation\nB.Tech CSE 2025\nExperience\nFlutter Developer at Example Studio\nSkills: Flutter, Dart, Git\nProjects\nOffline app\nCertifications\nExample certificate');
    expect(profile.get('name'), 'Example Person');
    expect(profile.get('email'), 'example@example.com');
    expect(profile.get('phone').replaceAll(' ', ''), '+919876543210');
    expect(profile.get('location'), 'Pune');
    expect(profile.get('education'), 'B.Tech CSE 2025');
    expect(profile.get('experience'), 'Flutter Developer at Example Studio');
    expect(profile.get('skills'), 'Flutter, Dart, Git');
    expect(profile.get('projects'), 'Offline app');
    expect(profile.get('certifications'), 'Example certificate');
    expect(profile.get('roles'), '');
  });
  test('missing and ambiguous details stay empty', () {
    final profile = parser.parse('EXAMPLE PERSON\nI enjoy writing mobile applications');
    expect(profile.get('name'), '');
    expect(profile.get('phone'), '');
    expect(profile.get('education'), '');
    expect(profile.get('location'), '');
    expect(profile.get('skills'), '');
  });
  test('skill boundaries distinguish Java and JavaScript and SQL from SQLite', () {
    final profile = parser.parse('Used JavaScript and SQLite for a project');
    expect(profile.get('skills'), 'JavaScript, SQLite');
    expect(ResumeParser.containsTerm('Dartmouth', 'Dart'), false);
  });
  test('suggested roles are separate from verified profile fields', () {
    final profile = parser.parse('Skills: Flutter, Dart');
    expect(parser.suggestedRoles(profile), ['Flutter Developer']);
    expect(profile.get('roles'), '');
  });
  test('empty profile round trips and keeps all missing fields', () {
    final profile = ResumeProfile.fromJson(ResumeProfile().toJson());
    expect(profile.fields.length, profileFields.length);
    expect(profile.isEmpty, true);
  });
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jobpilot_ai/core/groq_matching_service.dart';
import 'package:jobpilot_ai/core/matching_service.dart';
import 'package:jobpilot_ai/data/models.dart';

void main() {
  final profile = ResumeProfile(fields: {'name': 'Test identity', 'email': 'test@example.test', 'skills': 'Flutter, Dart', 'location': 'Pune'});
  const job = Job(id: 'test', title: 'Flutter Developer', company: 'Fixture', location: 'Pune', description: 'Use Flutter and Dart', skills: ['Flutter', 'Dart'], status: ApplicationStatus.applied);
  String content({Object score = 87, String evidence = 'Flutter'}) => jsonEncode({'matches': [{'id': 'test', 'score': score, 'profile_evidence': evidence, 'job_evidence': 'Flutter'}]});
  http.Response ok(String data) => http.Response(jsonEncode({'choices': [{'finish_reason': 'stop', 'message': {'content': data}}]}), 200);
  test('documented request validates copied evidence and preserves facts and manual status', () async {
    final service = GroqMatchingService(client: MockClient((request) async {
      expect(request.url, GroqMatchingService.endpoint);
      expect(request.headers['Authorization'], 'Bearer test-only-placeholder');
      final body = jsonDecode(request.body) as Map;
      expect(body['model'], 'openai/gpt-oss-20b');
      expect(request.body, isNot(contains('Test identity')));
      expect(request.body, isNot(contains('test@example.test')));
      return ok(content());
    }));
    final result = await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
    expect(result.jobs.single.score, 87);
    expect(result.jobs.single.status, ApplicationStatus.applied);
    expect(result.jobs.single.matchedSkills, ['Flutter', 'Dart']);
    expect(result.jobs.single.explanation, contains('Profile evidence'));
    expect(profile.get('name'), 'Test identity');
    service.close();
  });
  test('missing key and disabled switch make no network call', () async {
    final service = GroqMatchingService(client: MockClient((_) async => throw StateError('must not call')));
    for (final args in [(true, ''), (false, 'test-only-placeholder')]) {
      final result = await service.rank([job], profile, enabled: args.$1, apiKey: args.$2);
      expect(result.jobs.single.score, MatchingService().match(job, profile).score);
      expect(result.message, contains('Offline'));
    }
    service.close();
  });
  for (final status in [401, 403, 400, 500]) {
    test('HTTP $status falls back and key rejection is clear', () async {
      final service = GroqMatchingService(client: MockClient((_) async => http.Response('redacted error', status)));
      final result = await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
      expect(result.jobs.single.score, MatchingService().match(job, profile).score);
      expect(result.rejectedKey, status == 401 || status == 403);
      expect(result.message, contains('Offline'));
      if (result.rejectedKey) expect(result.message, contains('Replace the key'));
      service.close();
    });
  }
  test('429 observes Retry-After without repeated requests', () async {
    var calls = 0;
    var now = DateTime.utc(2026);
    final service = GroqMatchingService(clock: () => now, client: MockClient((_) async { calls++; return http.Response('', 429, headers: {'retry-after': '30'}); }));
    await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
    final result = await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
    expect(calls, 1);
    expect(result.message, contains('rate limit'));
    now = now.add(const Duration(seconds: 31));
    await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
    expect(calls, 2);
    service.close();
  });
  for (final invalid in ['not json', content(score: 101), content(score: 3.5), content(evidence: 'Invented skill'), '{"matches":[]}']) {
    test('invalid response safely falls back: $invalid', () async {
      final service = GroqMatchingService(client: MockClient((_) async => ok(invalid)));
      final result = await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
      expect(result.jobs.single.score, MatchingService().match(job, profile).score);
      expect(result.message, contains('invalid data'));
      service.close();
    });
  }
  test('transport failure falls back', () async {
    final service = GroqMatchingService(client: MockClient((_) async => throw http.ClientException('offline')));
    final result = await service.rank([job], profile, enabled: true, apiKey: 'test-only-placeholder');
    expect(result.jobs.single.score, MatchingService().match(job, profile).score);
    service.close();
  });
}

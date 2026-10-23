import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jobpilot_ai/core/app_update_service.dart';
import 'package:jobpilot_ai/features/app_update_card.dart';
void main() {
  for (final values in [('0.1.2+5', '0.1.1+4', 1), ('0.1.2+5', '0.1.2+5', 0), ('0.1.2+6', '0.1.2+5', 1), ('0.1.2+4', '0.1.2+5', -1), ('0.10.0', '0.9.9', 1), ('v1.0.0', '0.99.99+999', 1)]) {
    test('version ${values.$1} compared to ${values.$2}', () => expect(AppVersion.parse(values.$1).compareTo(AppVersion.parse(values.$2)).sign, values.$3));
  }
  test('malformed and prerelease versions are rejected', () {
    for (final value in ['unknown', '1', '0.1.x', '1.0.0-beta']) { expect(() => AppVersion.parse(value), throwsFormatException); }
  });
  const apk = 'https://github.com/frances09f-lgtm/jobpilot-ai/releases/download/v0.1.0/JobPilot-AI.apk';
  const manifest = 'https://github.com/frances09f-lgtm/jobpilot-ai/releases/download/v0.1.0/jobpilot-release.json';
  test('reused release tag compares uploaded APK metadata, not the old tag', () async {
    final service = AppUpdateService(client: MockClient((request) async {
      if (request.url == AppUpdateService.latest) return http.Response(jsonEncode({'draft': false, 'prerelease': false, 'tag_name': 'v0.1.0', 'assets': [{'name': 'JobPilot-AI.apk', 'browser_download_url': apk}, {'name': 'jobpilot-release.json', 'browser_download_url': manifest}]}), 200);
      expect(request.url.toString(), manifest);
      return http.Response(jsonEncode({'version': '0.1.2+5', 'apk_url': apk}), 200);
    }));
    expect((await service.check('0.1.1+4')).newer, isTrue);
    expect((await service.check('0.1.2+5')).newer, isFalse);
    service.close();
  });
  test('network/API failure remains an error instead of a false up-to-date result', () async {
    final service = AppUpdateService(client: MockClient((_) async => http.Response('', 403)));
    await expectLater(service.check('0.1.2+5'), throwsFormatException);
    service.close();
  });
  test('foreign download links are rejected', () {
    expect(() => AppUpdateService.trustedAsset('https://example.test/JobPilot-AI.apk', name: 'JobPilot-AI.apk'), throwsFormatException);
  });
  testWidgets('update button shows version and opens exact APK link', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppUpdateCard(check: () async => AppUpdateResult(newer: true, version: '0.1.2+5', apkUrl: Uri.parse(apk)), open: (url) async { opened = url; return true; }))));
    await tester.tap(find.text('Update app')); await tester.pumpAndSettle();
    expect(find.text('Version 0.1.2+5 is available.'), findsOneWidget);
    await tester.tap(find.text('Download APK 0.1.2+5')); await tester.pumpAndSettle();
    expect(opened.toString(), apk);
  });
  testWidgets('up-to-date and failed checks preserve the screen', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppUpdateCard(check: () async => AppUpdateResult(newer: false, version: '0.1.2+5', apkUrl: Uri.parse(apk))))));
    await tester.tap(find.text('Update app')); await tester.pumpAndSettle();
    expect(find.textContaining('up to date'), findsOneWidget);
    expect(find.textContaining('Download APK'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppUpdateCard(check: () async => throw const FormatException('offline')))));
    await tester.tap(find.text('Update app')); await tester.pumpAndSettle();
    expect(find.textContaining('Could not check for updates'), findsOneWidget);
    expect(find.text('Update app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

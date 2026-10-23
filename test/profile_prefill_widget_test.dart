import 'package:flutter/material.dart';
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

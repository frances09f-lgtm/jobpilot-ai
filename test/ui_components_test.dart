import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/features/ui_components.dart';

void main() {
  testWidgets('sample badge and score ring remain honest', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [SampleBadge(), ScoreRing(score: 0)]))));
    expect(find.text('• SAMPLE'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('disabled sample application button cannot trigger a submission', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GradientButton(label: 'Open official application page', onPressed: null))));
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

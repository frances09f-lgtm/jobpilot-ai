import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/features/ui_components.dart';
void main() {
  testWidgets('empty state shows no fake listings and score zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [JobsEmptyState(), ScoreRing(score: 0)]))));
    expect(find.text('No jobs yet, live jobs come in the next phase'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing application link keeps button disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GradientButton(label: 'Open official application page', onPressed: null))));
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

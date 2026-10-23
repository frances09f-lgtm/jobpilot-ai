import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/app/app_controller.dart';
import 'package:jobpilot_ai/data/models.dart';
import 'package:jobpilot_ai/features/home_screen.dart';
import 'package:jobpilot_ai/features/add_job_screen.dart';

class EmptyController extends AppController {
  @override
  Future<AppData> build() async => AppData(ResumeProfile(), const []);
}
void main() {
  testWidgets('empty dashboard and Jobs/Tracker contain no fake data', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [appProvider.overrideWith(EmptyController.new)], child: const MaterialApp(home: HomeScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('No jobs yet, live jobs come in the next phase'), findsWidgets);
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended jobs'), findsOneWidget);
    expect(find.text('No jobs yet, live jobs come in the next phase'), findsOneWidget);
    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();
    expect(find.text('No jobs yet, live jobs come in the next phase'), findsOneWidget);
    expect(find.textContaining('SAMPLE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('manual form starts with empty fields and blocks missing requirements', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: AddJobScreen())));
    expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).every((f) => f.controller!.text.isEmpty), isTrue);
    await tester.scrollUntilVisible(find.text('Save job and calculate match'), 200);
    await tester.tap(find.text('Save job and calculate match'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

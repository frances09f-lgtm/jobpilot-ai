import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/app/ai_settings_controller.dart';
import 'package:jobpilot_ai/app/app_controller.dart';
import 'package:jobpilot_ai/data/models.dart';
import 'package:jobpilot_ai/features/settings_screen.dart';
class MemoryStore implements DeviceKeyStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key] = value; }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}
class EmptyController extends AppController {
  @override
  Future<AppData> build() async => AppData(ResumeProfile(), const []);
  @override
  Future<void> refreshMatching() async {}
}
void main() {
  test('key enables toggle eligibility; opt-in persists; removal disables it', () async {
    final store = MemoryStore();
    final container = ProviderContainer(overrides: [deviceKeyStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    expect((await container.read(aiSettingsProvider.future)).hasKey, isFalse);
    final controller = container.read(aiSettingsProvider.notifier);
    await controller.setEnabled(true);
    expect(container.read(aiSettingsProvider).requireValue.enabled, isFalse);
    await controller.saveKey('test-only-placeholder');
    expect(container.read(aiSettingsProvider).requireValue.hasKey, isTrue);
    expect(container.read(aiSettingsProvider).requireValue.enabled, isFalse);
    await controller.setEnabled(true);
    expect(container.read(aiSettingsProvider).requireValue.enabled, isTrue);
    container.invalidate(aiSettingsProvider);
    expect((await container.read(aiSettingsProvider.future)).enabled, isTrue);
    await container.read(aiSettingsProvider.notifier).saveKey('');
    expect(container.read(aiSettingsProvider).requireValue.enabled, isFalse);
    expect(store.values.containsKey('groq_api_key'), isFalse);
  });
  testWidgets('actual Settings toggle becomes enabled after saving a device key', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MemoryStore();
    await tester.pumpWidget(ProviderScope(overrides: [deviceKeyStoreProvider.overrideWithValue(store), appProvider.overrideWith(EmptyController.new)], child: const MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('groq-toggle'))).onChanged, isNull);
    await tester.enterText(find.byKey(const ValueKey('groq-key')), 'test-only-placeholder');
    await tester.tap(find.text('Save key on this device'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('groq-toggle'))).onChanged, isNotNull);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('groq-toggle'))).value, isTrue);
    expect(find.textContaining('Coming in Phase 3'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

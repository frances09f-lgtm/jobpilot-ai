import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_controller.dart';
import '../app/ai_settings_controller.dart';
import 'app_update_card.dart';
import 'ui_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final keyController = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() { keyController.dispose(); super.dispose(); }
  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    try { await action(); }
    catch (_) { if (mounted) message = 'Could not complete this action. Your local data is still available.'; }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final asyncConfig = ref.watch(aiSettingsProvider);
    final config = asyncConfig.value ?? const AiSettings();
    final disabled = busy || asyncConfig.isLoading || asyncConfig.hasError;
    final groqMessage = ref.watch(appProvider).value?.groqMessage ?? '';
    final body = ListView(padding: const EdgeInsets.all(18), children: [
      const ScreenTitle(title: 'Settings', subtitle: 'Offline matching always works. AI is optional and uses your own key.'),
      PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(key: const ValueKey('groq-toggle'), contentPadding: EdgeInsets.zero, value: config.enabled, onChanged: disabled || !config.hasKey ? null : (value) => _run(() async {
          await ref.read(aiSettingsProvider.notifier).setEnabled(value);
          await ref.read(appProvider.notifier).refreshMatching();
          if (mounted) message = value ? 'AI setting saved. See the ranking result below.' : 'AI disabled. Offline matches restored.';
        }), title: const Text('Use Groq AI ranking'), subtitle: Text(config.hasKey ? 'Sends only skills, target roles, location and saved job text to Groq when enabled. No name, email, phone or resume file is sent.' : 'Save a key to enable AI ranking. Offline matching remains available.')),
        const SizedBox(height: 12), TextField(key: const ValueKey('groq-key'), controller: keyController, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: InputDecoration(labelText: 'Groq API key (optional)', hintText: config.hasKey ? 'Key saved securely. Enter a replacement.' : 'Enter your own Groq key')),
        GradientButton(label: busy ? 'Please wait...' : 'Save key on this device', onPressed: disabled ? null : () => _run(() async {
          if (keyController.text.trim().isEmpty) { if (mounted) message = 'Enter a key, or use Remove key.'; return; }
          await ref.read(aiSettingsProvider.notifier).saveKey(keyController.text);
          keyController.clear();
          if (mounted) message = 'Key saved on this device. Turn on AI ranking to use it.';
        })),
        if (config.hasKey) TextButton(onPressed: disabled ? null : () => _run(() async {
          await ref.read(aiSettingsProvider.notifier).saveKey('');
          keyController.clear();
          await ref.read(appProvider.notifier).refreshMatching();
          if (mounted) message = 'Key removed. Offline matching is active.';
        }), child: const Text('Remove key')),
        if (config.enabled) OutlinedButton(onPressed: disabled ? null : () => _run(() async { await ref.read(appProvider.notifier).refreshMatching(); }), child: const Text('Refresh AI matches')),
        if (asyncConfig.hasError) TextButton(onPressed: () => ref.invalidate(aiSettingsProvider), child: const Text('Could not read secure storage. Retry')),
        if (groqMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(groqMessage, key: const ValueKey('groq-result'))),
      ])),
      const PilotCard(child: Text('Keys embedded in an APK can be extracted. Secure device storage reduces exposure but cannot protect a key on a compromised device. Never ship a shared key. Use your own key or a secure backend for public AI releases.', style: TextStyle(color: Color(0xFFF3DCB4), height: 1.5))),
      const AppUpdateCard(),
      sectionHeading('Theme'), const PilotCard(child: Text('Dark navy • blue and violet accents\nThe approved dark theme is unchanged.')),
      sectionHeading('Local data'), const Text('Delete the saved resume, profile, jobs, tracker and optional key. The app stays empty after clearing.', style: TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 12), OutlinedButton(onPressed: disabled ? null : () async {
        final yes = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Clear local data?'), content: const Text('This removes your original resume, profile, status history and Groq key from this app. This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))]));
        if (yes != true || !mounted) return;
        await _run(() async {
          await ref.read(appProvider.notifier).clearAll();
          await ref.read(aiSettingsProvider.notifier).saveKey('');
          keyController.clear();
          if (mounted) message = 'Local data cleared';
        });
      }, child: const Text('Clear local data', style: TextStyle(color: Color(0xFFFFB3A8)))),
      if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
      const SizedBox(height: 20), const Text('No live job discovery, cover letters, automation or background refresh. No signup. No analytics. Optional Groq ranking requires internet and a valid key.', style: TextStyle(color: muted, height: 1.5)),
    ]);
    return widget.embedded ? body : Scaffold(appBar: AppBar(title: const Text('Settings')), body: body);
  }
}

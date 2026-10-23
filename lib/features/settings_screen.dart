import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app/app_controller.dart';
import 'ui_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final keyController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool busy = true;
  String? message;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final key = await storage.read(key: 'groq_api_key'); if (mounted) keyController.text = key ?? ''; }
    catch (e) { if (mounted) message = 'Could not read secure storage: $e'; }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { keyController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
          
      final body = ListView(padding: const EdgeInsets.all(18), children: [
      const ScreenTitle(title: 'Settings', subtitle: 'Matching works without AI. Your data stays on this device.'),
              PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SwitchListTile(contentPadding: EdgeInsets.zero, value: false, onChanged: null, title: Text('Use Groq AI ranking'), subtitle: Text('Coming in Phase 3. No Groq requests are made in this MVP.')),
        const SizedBox(height: 12), TextField(controller: keyController, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: const InputDecoration(labelText: 'Groq API key (optional)', hintText: 'Stored locally, not used in Phase 1')),
        GradientButton(label: busy ? 'Please wait...' : 'Save key on this device', onPressed: busy ? null : () async {
          setState(() => busy = true);
          try {
            final key = keyController.text.trim();
            if (key.isEmpty) { await storage.delete(key: 'groq_api_key'); } else { await storage.write(key: 'groq_api_key', value: key); }
            if (mounted) message = key.isEmpty ? 'Key removed' : 'Saved locally. No AI calls enabled.';
          } catch (e) { if (mounted) message = 'Could not save key: $e'; }
          finally { if (mounted) setState(() => busy = false); }
        }),
      ])),
      const PilotCard(child: Text('Keys embedded in an APK can be extracted. Secure device storage reduces exposure but cannot protect a key on a compromised device. Never ship a shared key. Use your own key or a secure backend for public AI releases.', style: TextStyle(color: Color(0xFFF3DCB4), height: 1.5))),
      sectionHeading('Theme'), const PilotCard(child: Text('Dark navy • blue and violet accents\nThis MVP uses the approved dark theme only.')),
      sectionHeading('Local data'), const Text('Delete the saved resume, profile, jobs, tracker and optional key. The app stays empty after clearing.', style: TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 12), OutlinedButton(onPressed: busy ? null : () async {
        final yes = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Clear local data?'), content: const Text('This removes your original resume, profile, status history and Groq key from this app. This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))]));
        if (yes != true) return;
        setState(() => busy = true);
        try { await ref.read(appProvider.notifier).clearAll(); await storage.delete(key: 'groq_api_key'); keyController.clear(); if (mounted) message = 'Local data cleared'; }
        catch (e) { if (mounted) message = 'Could not clear all data: $e'; }
        finally { if (mounted) setState(() => busy = false); }
      }, child: const Text('Clear local data', style: TextStyle(color: Color(0xFFFFB3A8)))),
      if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
      const SizedBox(height: 20), const Text('Phase 1 • no live job API, AI calls, cover letters, automation or background refresh. No signup. No analytics.', style: TextStyle(color: muted, height: 1.5)),
    ]);
    return widget.embedded ? body : Scaffold(appBar: AppBar(title: const Text('Settings')), body: body);
  }
}

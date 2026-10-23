import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_update_service.dart';
import 'ui_components.dart';

class AppUpdateCard extends StatefulWidget {
  const AppUpdateCard({super.key, this.check, this.open});
  final Future<AppUpdateResult> Function()? check;
  final Future<bool> Function(Uri)? open;
  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}
class _AppUpdateCardState extends State<AppUpdateCard> {
  bool busy = false;
  String message = 'Check for a newer Android APK on GitHub.';
  AppUpdateResult? result;
  Future<AppUpdateResult> _check() async {
    final info = await PackageInfo.fromPlatform();
    final service = AppUpdateService();
    try { return await service.check('${info.version}+${info.buildNumber}'); }
    finally { service.close(); }
  }
  Future<void> _runCheck() async {
    setState(() { busy = true; result = null; message = 'Checking latest release...'; });
    try {
      final update = await (widget.check ?? _check)();
      if (mounted) setState(() { result = update; message = update.newer ? 'Version ${update.version} is available.' : 'Your app is up to date (${update.version}).'; });
    } catch (_) {
      if (mounted) setState(() => message = 'Could not check for updates. Check your connection and try again. Your app and saved data still work.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> _download() async {
    final update = result;
    if (update == null || !update.newer) return;
    try {
      final opened = await (widget.open?.call(update.apkUrl) ?? launchUrl(update.apkUrl, mode: LaunchMode.externalApplication));
      if (!opened && mounted) setState(() => message = 'Could not open the APK download. Try again.');
    } catch (_) { if (mounted) setState(() => message = 'Could not open the APK download. Try again.'); }
  }
  @override
  Widget build(BuildContext context) => PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('App updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    const SizedBox(height: 10), Text(message, key: const ValueKey('update-message')),
    GradientButton(label: busy ? 'Checking...' : 'Update app', onPressed: busy ? null : _runCheck),
    if (result?.newer ?? false) OutlinedButton(onPressed: _download, child: Text('Download APK ${result!.version}')),
    const Text('Opens the official release download. Android asks you to install it; this does not install silently.', style: TextStyle(color: muted, fontSize: 12)),
  ]));
}

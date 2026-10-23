import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_controller.dart';
import '../data/models.dart';
import '../core/resume_parser.dart';
import 'ui_components.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.profile, this.imported = false});
  final ResumeProfile profile;
  final bool imported;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final Map<String, TextEditingController> controllers;
  bool saving = false, saved = false;
  @override
  void initState() {
    super.initState();
    controllers = {for (final key in profileFields) key: TextEditingController(text: widget.profile.get(key))};
  }
  @override
  void dispose() {
    for (final controller in controllers.values) { controller.dispose(); }
    if (widget.imported && !saved && widget.profile.resumePath.isNotEmpty) {
      final file = File(widget.profile.resumePath);
      file.exists().then((exists) async { if (exists) await file.delete(); }).catchError((Object _) {});
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.imported ? 'Review extracted profile' : 'Edit profile')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const ScreenTitle(title: 'Your details, your control', subtitle: 'Check every candidate. Leave missing details empty. Nothing is sent to an employer.'),
      if (widget.profile.resumeName.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('Saved resume: ${widget.profile.resumeName}', style: const TextStyle(color: muted))),
      for (final key in profileFields) Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(
        controller: controllers[key], minLines: 1, maxLines: ['education', 'experience', 'skills', 'projects', 'certifications'].contains(key) ? 5 : 2,
        decoration: InputDecoration(labelText: key == 'roles' ? 'Target roles (your choice)' : '${key[0].toUpperCase()}${key.substring(1)}', hintText: 'Not found in resume'),
      )),
      PilotCard(child: Text('Possible roles from skills: ${ResumeParser().suggestedRoles(widget.profile).join(', ')}. These are suggestions, not verified employment.')),
      GradientButton(label: saving ? 'Saving...' : 'Save profile and update matches', onPressed: saving ? null : () async {
        setState(() => saving = true);
        try {
          final profile = ResumeProfile(fields: {for (final entry in controllers.entries) entry.key: entry.value.text.trim()},
            rawText: widget.profile.rawText, resumePath: widget.profile.resumePath, resumeName: widget.profile.resumeName);
          await ref.read(appProvider.notifier).saveProfile(profile);
          saved = true;
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
        } finally { if (mounted) setState(() => saving = false); }
      }),
              if (widget.profile.rawText.isNotEmpty) TextButton(onPressed: () {
          final current = ResumeProfile(fields: {for (final entry in controllers.entries) entry.key: entry.value.text}, rawText: widget.profile.rawText);
          final filled = ResumeParser().prefillMissing(current);
          setState(() { for (final key in profileFields) { controllers[key]!.text = filled.get(key); } });
        }, child: const Text('Fill empty fields from saved resume')),
        ExpansionTile(title: const Text('Original extracted text'), children: [SelectableText(widget.profile.rawText.isEmpty ? 'No resume uploaded' : widget.profile.rawText)]),
    ]),
  );
}

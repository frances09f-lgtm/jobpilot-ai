import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_controller.dart';
import '../data/models.dart';
import 'ui_components.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider).value;
    final jobs = data?.jobs.where((j) => j.id == jobId).toList() ?? [];
    if (jobs.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Job no longer available')));
    final job = jobs.first;
    return Scaffold(appBar: AppBar(title: const Text('Back to jobs')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Row(children: [ScoreRing(score: job.score, size: 88), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (job.isSample) const SampleBadge(), const SizedBox(height: 8), Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('${job.company} · ${job.location}', style: const TextStyle(color: muted)),
      ]))]),
      sectionHeading('Why it matches'), PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.explanation, style: const TextStyle(height: 1.5)), const SizedBox(height: 12), Text('Matched skills: ${job.matchedSkills.isEmpty ? 'None recorded' : job.matchedSkills.join(', ')}')])),
      sectionHeading('Skill gaps'), Wrap(spacing: 8, children: job.gaps.map((s) => Chip(label: Text(s), backgroundColor: const Color(0xFF302738))).toList()),
      if (job.gaps.isEmpty) const Text('No listed gaps'),
      sectionHeading('Description'), Text(job.description, style: const TextStyle(height: 1.6, color: Color(0xFFCFD8EC))),
      const SizedBox(height: 20), const PilotCard(child: Text('Unsupported sites apply manually. Never bypass logins, CAPTCHAs or anti-bot checks. Phase 1 does not submit applications.')),
      if (job.isSample) const Text('This is a fictional sample. There is no official employer application page. Tracker updates are practice only.', style: TextStyle(color: muted)),
      GradientButton(label: 'Open official application page', onPressed: job.isSample || job.applicationUrl.isEmpty ? null : () async {
        final uri = Uri.tryParse(job.applicationUrl);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The official application URL is missing or invalid.'))); return;
        }
        try {
          final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open page. No submission was made.')));
        } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open page: $e'))); }
      }),
      OutlinedButton(onPressed: () => _changeStatus(context, ref, job), child: const Text('Save / update tracker status')),
      const SizedBox(height: 12), Text('Source: ${job.source}\nStatus: ${job.status.label} (manual)\nUpdated: ${job.updatedAt}', style: const TextStyle(color: muted, height: 1.6)),
      if (job.error.isNotEmpty) Text('Note / error: ${job.error}'),
      const SizedBox(height: 12), const Text('Applied is your own record, not a verified submission. Never guess screening, eligibility or legal answers.', style: TextStyle(color: muted)),
    ]));
  }
  Future<void> _changeStatus(BuildContext context, WidgetRef ref, Job job) async {
    var status = job.status;
    final note = TextEditingController(text: job.error);
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Manually recorded status'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Your record only. Sample Applied entries are not real applications.'), const SizedBox(height: 16),
        DropdownButtonFormField<ApplicationStatus>(initialValue: status, isExpanded: true, items: ApplicationStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(), onChanged: (s) { if (s != null) setDialogState(() => status = s); }),
        const SizedBox(height: 16), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Note / error (optional)')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
    )));
    if (result == true) {
      try { await ref.read(appProvider.notifier).setStatus(job, status, note.text.trim()); }
      catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'))); }
    }
    note.dispose();
  }
}

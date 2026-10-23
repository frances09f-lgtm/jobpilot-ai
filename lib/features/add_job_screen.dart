import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_controller.dart';
import '../core/manual_job_service.dart';
import 'ui_components.dart';

class AddJobScreen extends ConsumerStatefulWidget {
  const AddJobScreen({super.key});
  @override
  ConsumerState<AddJobScreen> createState() => _AddJobScreenState();
}
class _AddJobScreenState extends ConsumerState<AddJobScreen> {
  final formKey = GlobalKey<FormState>();
  final fields = {for (final key in ['title', 'company', 'location', 'description', 'url']) key: TextEditingController()};
  bool saving = false;
  @override
  void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add a job')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      const ScreenTitle(title: 'Add a job by hand', subtitle: 'Copy a real listing you found. Saved locally, then matched to your resume. No application is submitted.'),
      for (final key in fields.keys) Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
        key: ValueKey('job-$key'), controller: fields[key],
        minLines: key == 'description' ? 4 : 1, maxLines: key == 'description' ? 8 : 2,
        keyboardType: key == 'url' ? TextInputType.url : TextInputType.multiline,
        decoration: InputDecoration(labelText: {'title': 'Job title', 'company': 'Company', 'location': 'Location (optional)', 'description': 'Description', 'url': 'Application URL (optional, HTTPS)'}[key]),
        validator: (value) {
          if (['title', 'company', 'description'].contains(key) && (value ?? '').trim().isEmpty) return 'Required';
          return key == 'url' ? ManualJobService.urlError(value ?? '') : null;
        },
      )),
      const PilotCard(child: Text('Only skills actually mentioned in the description count as listed requirements. Missing location or URL stays empty. You can open the application page and record status manually.')),
      GradientButton(label: saving ? 'Saving...' : 'Save job and calculate match', onPressed: saving ? null : () async {
        if (!formKey.currentState!.validate()) return;
        setState(() => saving = true);
        try {
          await ref.read(appProvider.notifier).addManualJob(title: fields['title']!.text, company: fields['company']!.text, location: fields['location']!.text, description: fields['description']!.text, applicationUrl: fields['url']!.text);
          if (context.mounted) Navigator.pop(context, true);
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save job: $e')));
        } finally { if (mounted) setState(() => saving = false); }
      }),
    ])),
  );
}

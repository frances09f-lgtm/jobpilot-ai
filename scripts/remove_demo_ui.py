from pathlib import Path

def edit(path, old, new):
    p = Path(path)
    s = p.read_text()
    if old not in s:
        raise RuntimeError(f'Missing expected source anchor in {path}: {old[:100]}')
    p.write_text(s.replace(old, new))

home = 'lib/features/home_screen.dart'
edit(home, "import 'pilot_logo.dart';", "import 'pilot_logo.dart';\nimport 'add_job_screen.dart';")
edit(home, "actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: SampleBadge(text: 'SAMPLE DATA')))]", "actions: [IconButton(tooltip: 'Add a job', onPressed: processing ? null : _addJob, icon: const Icon(Icons.add))]")
edit(home, 'data.visibleJobs', 'data.jobs')
edit(home, "if (showUpload || (data.profile.isEmpty && data.profile.resumePath.isEmpty))", "if (showUpload)")
edit(home, "Explore sample jobs", "View jobs")
edit(home, "Your local job search at a glance. All jobs are fictional samples; scores come from your profile.", "Your local job search at a glance. Counts use saved listings and your own tracker records.")
edit(home, "'Sample jobs found'", "'Jobs saved'")
edit(home, "_stat('Real submissions', 0, constraints.maxWidth)", "_stat('Applied (manual)', data.jobs.where((j) => j.status == ApplicationStatus.applied).length, constraints.maxWidth)")
edit(home, "if (data.hideSampleJobs) const PilotCard(child: Text('Sample jobs are hidden. Phase 1 has no live vacancies. Show samples again in Settings.', style: TextStyle(color: muted))),", "if (data.jobs.isEmpty) const JobsEmptyState(),")
edit(home, "'No visible matches'", "'No jobs yet, live jobs come in the next phase'")
edit(home, "'No sample items need attention'", "'No items need attention'")
edit(home, "TextButton(onPressed: () => setState(() => showUpload = true), child: const Text('Replace resume'))", "GradientButton(label: 'Add a job by hand', onPressed: _addJob), TextButton(onPressed: _import, child: Text(data.profile.resumePath.isEmpty ? 'Upload resume' : 'Replace resume'))")
edit(home, "jobFilter == 'All' || jobFilter == 'Sample' ||", "jobFilter == 'All' ||")
edit(home, "tracker ? 'Manual practice records only. Sample Applied statuses do not mean real submissions.' : data.hideSampleJobs ? 'Sample jobs are hidden. Live jobs are not included in Phase 1.' : 'Fictional demo jobs, not real vacancies. Ranked by your resume match score.'", "tracker ? 'Your manual status records, not verified submissions.' : 'Listings you saved by hand, ranked by your resume match score. Live discovery comes in Phase 2.'")
edit(home, "['All', '80+', 'Remote', 'Pune', 'Kolhapur', 'Sample']", "['All', '80+', 'Remote', 'Pune', 'Kolhapur']")
edit(home, "if (jobs.isEmpty) const Text('No visible jobs. Samples may be hidden in Settings or excluded by your filter.', style: TextStyle(color: muted)),", "GradientButton(label: 'Add a job by hand', onPressed: _addJob), if (jobs.isEmpty) data.jobs.isEmpty ? const JobsEmptyState() : const PilotCard(child: Text('No jobs match this filter', style: TextStyle(color: muted))),")
edit(home, "SampleBadge(text: j.status.label)", "StatusBadge(text: j.status.label)")
edit(home, "const SampleBadge()", "Text('Source: ${j.source}', style: const TextStyle(color: muted, fontSize: 11))")
edit(home, "void _details(Job job)", "Future<void> _addJob() async {\n    final added = await Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => const AddJobScreen()));\n    if (added == true && mounted) setState(() { index = 1; showUpload = false; query = ''; jobFilter = 'All'; });\n  }\n  void _details(Job job)")

ui = 'lib/features/ui_components.dart'
edit(ui, "class SampleBadge", "class StatusBadge")
edit(ui, "const SampleBadge({super.key, this.text = 'SAMPLE'});", "const StatusBadge({super.key, required this.text});")
p = Path(ui)
p.write_text(p.read_text() + "\nclass JobsEmptyState extends StatelessWidget {\n  const JobsEmptyState({super.key});\n  @override\n  Widget build(BuildContext context) => const PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [\n    Icon(Icons.work_outline, color: violet, size: 32), SizedBox(height: 12),\n    Text('No jobs yet, live jobs come in the next phase', style: TextStyle(fontWeight: FontWeight.w600, height: 1.5)),\n    SizedBox(height: 8), Text('Add a job by hand to use matching and the tracker now.', style: TextStyle(color: muted, height: 1.5)),\n  ]));\n}\n")

details = 'lib/features/job_details_screen.dart'
edit(details, "if (job.isSample) const SampleBadge(),", "")
edit(details, "if (job.isSample) const Text('This is a fictional sample. There is no official employer application page. Tracker updates are practice only.', style: TextStyle(color: muted)),", "")
edit(details, "job.isSample || job.applicationUrl.isEmpty", "job.applicationUrl.isEmpty")
edit(details, "Your record only. Sample Applied entries are not real applications.", "Your record only. This does not submit or verify an application.")

settings = 'lib/features/settings_screen.dart'
p = Path(settings)
s = p.read_text()
a = s.index('PilotCard(child: SwitchListTile(contentPadding: EdgeInsets.zero, value: data?.hideSampleJobs')
b = s.index('PilotCard(child: Column(', a)
s = s[:a] + s[b:]
s = s.replace('final data = ref.watch(appProvider).value;', '')
s = s.replace('Delete the saved resume, profile, tracker and optional key. Sample jobs are restored with empty statuses.', 'Delete the saved resume, profile, jobs, tracker and optional key. The app stays empty after clearing.')
p.write_text(s)

# Reject remaining demo imports/UI rather than silently publishing an incomplete change.
for p in Path('lib').rglob('*.dart'):
    s = p.read_text()
    if any(x in s for x in ['SampleBadge', 'sample_jobs.dart', 'hideSampleJobs', 'isSample', 'sampleJobs']):
        raise RuntimeError(f'Remaining demo reference in {p}')

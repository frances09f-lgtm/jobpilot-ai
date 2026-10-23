import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_controller.dart';
import '../data/models.dart';
import 'job_details_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'ui_components.dart';
import 'pilot_logo.dart';
import 'add_job_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  int index = 0, stage = -1;
  String query = '', jobFilter = 'All';
  ApplicationStatus? statusFilter;
  bool showUpload = false, processing = false;
  String? processingError;
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(titleSpacing: 18, title: Row(children: [
                  const PilotLogo(size: 32),
        const SizedBox(width: 10), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JobPilot AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text('Offline-first • Phase 1', style: TextStyle(fontSize: 11, color: muted))]),
      ]), actions: [IconButton(tooltip: 'Add a job', onPressed: processing ? null : _addJob, icon: const Icon(Icons.add))]),
      body: SafeArea(child: asyncData.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, st) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Could not load local data: $e'), TextButton(onPressed: () => ref.invalidate(appProvider), child: const Text('Retry'))])), data: (data) => processing ? _processing() : _body(data))),
      bottomNavigationBar: NavigationBar(height: 70, backgroundColor: const Color(0xFF080D1A), selectedIndex: index, indicatorColor: blue.withValues(alpha: 0.18), onDestinationSelected: processing ? null : (v) => setState(() { index = v; showUpload = false; statusFilter = null; query = ''; jobFilter = 'All'; }), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'), NavigationDestination(icon: Icon(Icons.checklist), label: 'Tracker'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ]),
    );
  }
  Widget _body(AppData data) {
    if (index == 4) return const SettingsScreen(embedded: true);
    if (index == 1 || index == 3) return _jobs(data, tracker: index == 3);
    if (index == 2) return _profile(data.profile);
    if (showUpload) return _upload(data.profile);
    return _dashboard(data);
  }
  Widget _upload(ResumeProfile profile) => ListView(padding: const EdgeInsets.all(18), children: [
    const ScreenTitle(title: 'Start with your resume', subtitle: 'JobPilot reads the file on your phone, pulls out skills, and builds a profile you can edit.', eyebrow: 'STEP 1 OF 3'),
    Semantics(button: true, label: 'Upload PDF or DOCX resume', child: InkWell(onTap: _import, borderRadius: BorderRadius.circular(22), child: Container(padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20), decoration: BoxDecoration(border: Border.all(color: blue.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF192949), Color(0xFF101728)])), child: const Column(children: [
      PilotLogo(size: 72), SizedBox(height: 14), Text('Upload PDF or DOCX resume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 8), Text('Tap to pick a file • up to 10 MB', style: TextStyle(color: muted, fontSize: 12)),
    ])))), const SizedBox(height: 22),
    _fact('Stays on your phone. Parsing happens locally; no file is sent to a server.'), _fact('Scanned PDFs need OCR elsewhere. Missing fields remain empty.'), _fact('No account, no sign-in. Basic matching needs no AI key.'),
    const SizedBox(height: 16), const PilotCard(child: Text('Review extracted details before saving. Your original resume is kept in app-local storage.', style: TextStyle(color: muted, height: 1.5))),
    if (processingError != null) PilotCard(child: Text(processingError!, style: const TextStyle(color: Color(0xFFFF9B8F)))),
    GradientButton(label: 'Enter profile manually', onPressed: () => _editProfile(profile)), TextButton(onPressed: () => setState(() => index = 1), child: const Text('View jobs')),
  ]);
  Widget _fact(String text) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•', style: TextStyle(color: violet)), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFCBD5EA), fontSize: 14, height: 1.5)))]));
  Widget _processing() => ListView(padding: const EdgeInsets.all(18), children: [
    const ScreenTitle(title: 'Building your profile', subtitle: 'Reading your resume on this device. You will review the extracted details next.', eyebrow: 'STEP 2 OF 3'),
    PilotCard(child: Column(children: [for (var i = 0; i < 4; i++) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(i < stage ? Icons.check_circle : i == stage ? Icons.pending : Icons.radio_button_unchecked, color: i <= stage ? violet : muted), title: Text(['Reading file', 'Extracting text', 'Finding skills', 'Building profile'][i])), const SizedBox(height: 12), LinearProgressIndicator(value: stage < 0 ? null : (stage + 1) / 4), const SizedBox(height: 12), Text(stage < 0 ? 'Choose a resume in the file picker' : ['Reading bytes', 'Extracting local text', 'Finding candidate fields', 'Saving original resume'][stage], style: const TextStyle(color: muted))])),
  ]);
  Widget _dashboard(AppData data) {
    final attention = data.jobs.where((j) => [ApplicationStatus.failed, ApplicationStatus.needsAction, ApplicationStatus.submissionUnconfirmed].contains(j.status)).toList();
    final top = [...data.jobs]..sort((a, b) => b.score.compareTo(a.score));
    return ListView(padding: const EdgeInsets.all(18), children: [
      const ScreenTitle(title: 'Dashboard', subtitle: 'Your local job search at a glance. Counts use saved listings and your own tracker records.'),
      LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 0, children: [
        _stat('Jobs saved', data.jobs.length, constraints.maxWidth), _stat('Matches 70+', data.jobs.where((j) => j.score >= 70).length, constraints.maxWidth),
        _stat('Applied (manual)', data.jobs.where((j) => j.status == ApplicationStatus.applied).length, constraints.maxWidth), _stat('Needs attention', attention.length, constraints.maxWidth),
      ])), if (data.jobs.isEmpty) const JobsEmptyState(), sectionHeading('Top matches'), PilotCard(child: top.isEmpty ? const Text('No jobs yet, live jobs come in the next phase', style: TextStyle(color: muted)) : Column(children: top.take(3).map((j) => _mini(j, score: true)).toList())),
      sectionHeading('Needs attention'), PilotCard(child: attention.isEmpty ? const Text('No items need attention', style: TextStyle(color: muted)) : Column(children: attention.map((j) => _mini(j)).toList())),
      GradientButton(label: 'Review recommended jobs', onPressed: () => setState(() => index = 1)),
      GradientButton(label: 'Add a job by hand', onPressed: _addJob), TextButton(onPressed: _import, child: Text(data.profile.resumePath.isEmpty ? 'Upload resume' : 'Replace resume')),
    ]);
  }
  Widget _stat(String label, int count, double width) => SizedBox(width: (width - 12) / 2, child: PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 36, height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [blue, violet]))), const SizedBox(height: 13), Text('$count', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(label, style: const TextStyle(color: muted, fontSize: 12))])));
  Widget _mini(Job j, {bool score = false}) => InkWell(onTap: () => _details(j), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(j.title, style: const TextStyle(fontWeight: FontWeight.w600)), Text('${j.company} · ${score ? j.location : j.status.label}', style: const TextStyle(color: muted, fontSize: 12))])), if (score) Text('${j.score}', style: const TextStyle(color: Color(0xFFBCD0FF), fontWeight: FontWeight.w800))])));
  Widget _jobs(AppData data, {required bool tracker}) {
    final jobs = data.jobs.where((j) => '${j.title} ${j.company} ${j.location} ${j.skills.join(' ')}'.toLowerCase().contains(query.toLowerCase()) &&
      (tracker ? statusFilter == null || j.status == statusFilter : jobFilter == 'All' || (jobFilter == '80+' ? j.score >= 80 : j.location.toLowerCase().contains(jobFilter.toLowerCase())))).toList()..sort((a, b) => b.score.compareTo(a.score));
    return ListView(padding: const EdgeInsets.all(18), children: [
      ScreenTitle(title: tracker ? 'Application tracker' : 'Recommended jobs', subtitle: tracker ? 'Your manual status records, not verified submissions.' : 'Listings you saved by hand, ranked by your resume match score. Live discovery comes in Phase 2.'),
      TextField(key: ValueKey(index), onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(labelText: 'Search jobs', hintText: 'Title, company, location or skills', prefixIcon: Icon(Icons.search))), const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tracker ? [
        _chip('All', statusFilter == null, () => setState(() => statusFilter = null)), ...ApplicationStatus.values.map((s) => _chip(s.label, statusFilter == s, () => setState(() => statusFilter = s))),
      ] : ['All', '80+', 'Remote', 'Pune', 'Kolhapur'].map((s) => _chip(s, jobFilter == s, () => setState(() => jobFilter = s))).toList())), const SizedBox(height: 16),
      GradientButton(label: 'Add a job by hand', onPressed: _addJob), if (jobs.isEmpty) data.jobs.isEmpty ? const JobsEmptyState() : const PilotCard(child: Text('No jobs match this filter', style: TextStyle(color: muted))),
      if (tracker) PilotCard(child: Column(children: jobs.map((j) => InkWell(onTap: () => _details(j), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(j.title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text('${j.company} · ${j.updatedAt.isEmpty ? 'No date' : j.updatedAt.split('T').first}', style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 8), StatusBadge(text: j.status.label), if (j.error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(j.error, style: const TextStyle(color: Color(0xFFFFB3A8), fontSize: 12)))])))).toList()))
      else ...jobs.map((j) => PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(j.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('${j.company} · ${j.location}', style: const TextStyle(color: muted, fontSize: 13)), const SizedBox(height: 10), Text('Source: ${j.source}', style: const TextStyle(color: muted, fontSize: 11))])), const SizedBox(width: 14), ScoreRing(score: j.score)]), TextButton(onPressed: () => _details(j), child: const Text('View details ›'))]))),
    ]);
  }
  Widget _chip(String text, bool selected, VoidCallback action) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(text), selected: selected, onSelected: (_) => action()));
  Widget _profile(ResumeProfile profile) => ListView(padding: const EdgeInsets.all(18), children: [
    const ScreenTitle(title: 'Profile', subtitle: 'Fields come from your resume and edits. Anything missing stays empty.'),
    PilotCard(child: Column(children: ['name', 'email', 'phone', 'location', 'education', 'experience'].map((key) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 92, child: Text('${key[0].toUpperCase()}${key.substring(1)}', style: const TextStyle(color: muted, fontSize: 12))), Expanded(child: Text(profile.get(key).isEmpty ? 'Not found in resume' : profile.get(key), style: TextStyle(color: profile.get(key).isEmpty ? muted : null, fontStyle: profile.get(key).isEmpty ? FontStyle.italic : FontStyle.normal)))]))).toList())),
    for (final key in ['skills', 'projects', 'certifications', 'roles']) ...[sectionHeading(key == 'roles' ? 'Target roles' : '${key[0].toUpperCase()}${key.substring(1)}'), PilotCard(child: Text(profile.get(key).isEmpty ? 'Not found in resume' : profile.get(key)))],
    GradientButton(label: 'Edit profile', onPressed: () => _editProfile(profile)), OutlinedButton(onPressed: _import, child: const Text('Replace resume')),
    Text(profile.resumeName.isEmpty ? 'No original resume saved' : 'Saved resume: ${profile.resumeName}', style: const TextStyle(color: muted)),
  ]);
  Future<void> _addJob() async {
    final added = await Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => const AddJobScreen()));
    if (added == true && mounted) setState(() { index = 1; showUpload = false; query = ''; jobFilter = 'All'; });
  }
  void _details(Job job) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => JobDetailsScreen(jobId: job.id)));
  Future<void> _editProfile(ResumeProfile profile) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProfileScreen(profile: profile)));
    if (mounted) setState(() => showUpload = false);
  }
  Future<void> _import() async {
    setState(() { processing = true; processingError = null; stage = -1; });
    try {
      final profile = await ref.read(appProvider.notifier).importResume(onStage: (value) { if (mounted) setState(() => stage = value); });
      if (!mounted) return;
      setState(() => processing = false);
      if (profile != null) {
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProfileScreen(profile: profile, imported: true)));
        if (mounted) setState(() { showUpload = false; index = 0; });
      }
    } catch (e) { if (mounted) setState(() { processing = false; processingError = 'Could not read resume: $e'; showUpload = true; index = 0; }); }
  }
}

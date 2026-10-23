import 'package:flutter/material.dart';

const muted = Color(0xFF9AA4BD);
const violet = Color(0xFFA78BFA);
const blue = Color(0xFF5B8CFF);

class PilotCard extends StatelessWidget {
  const PilotCard({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF29344C)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF151F37), Color(0xFF101728)])), child: child);
}
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, required this.subtitle, this.eyebrow});
  final String title, subtitle;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (eyebrow != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(eyebrow!, style: const TextStyle(color: Color(0xFF93B4FF), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 11))),
    Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.7)), const SizedBox(height: 7),
    Text(subtitle, style: const TextStyle(color: muted, height: 1.5, fontSize: 14)),
  ]));
}
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: violet.withValues(alpha: 0.14), border: Border.all(color: violet.withValues(alpha: 0.45)), borderRadius: BorderRadius.circular(30)),
    child: Text('• $text', style: const TextStyle(color: Color(0xFFE0D6FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)));
}
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 56});
  final int score;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(label: 'Match score $score out of 100', child: SizedBox(width: size, height: size, child: Stack(alignment: Alignment.center, children: [
    SizedBox(width: size, height: size, child: CircularProgressIndicator(value: score / 100, strokeWidth: size > 70 ? 7 : 4, backgroundColor: const Color(0xFF2C3851), color: violet)),
    Text('$score', style: TextStyle(fontSize: size > 70 ? 27 : 15, fontWeight: FontWeight.w800)),
  ])));
}
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: DecoratedBox(
    decoration: BoxDecoration(gradient: onPressed == null ? null : const LinearGradient(colors: [Color(0xFF3B6BF5), Color(0xFF7A4FF0)]), color: onPressed == null ? const Color(0xFF273147) : null, borderRadius: BorderRadius.circular(30)),
    child: SizedBox(width: double.infinity, child: TextButton(onPressed: onPressed, style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(0, 48)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)))),
  ));
}
Widget sectionHeading(String text) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 12), child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)));

class JobsEmptyState extends StatelessWidget {
  const JobsEmptyState({super.key});
  @override
  Widget build(BuildContext context) => const PilotCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(Icons.work_outline, color: violet, size: 32), SizedBox(height: 12),
    Text('No jobs yet, live jobs come in the next phase', style: TextStyle(fontWeight: FontWeight.w600, height: 1.5)),
    SizedBox(height: 8), Text('Add a job by hand to use matching and the tracker now.', style: TextStyle(color: muted, height: 1.5)),
  ]));
}

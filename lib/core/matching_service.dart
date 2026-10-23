import '../data/models.dart';
import 'resume_parser.dart';

class MatchingService {
  Job match(Job job, ResumeProfile profile) {
    final matched = job.skills.where((s) => ResumeParser.containsTerm(profile.get('skills'), s)).toList();
    final gaps = job.skills.where((s) => !matched.contains(s)).toList();
    if (profile.isEmpty) return job.copyWith(score: 0, matchedSkills: [], gaps: gaps, explanation: 'Upload or edit your resume profile to calculate a match.');
    final skillScore = job.skills.isEmpty ? 0.0 : matched.length / job.skills.length * 70;
    final roleText = '${profile.get('roles')} ${ResumeParser().suggestedRoles(profile).join(' ')}';
    final titleWords = job.title.toLowerCase().split(RegExp(r'\W+')).where((s) => s.length > 2 && !['junior', 'senior', 'intern', 'developer', 'engineer'].contains(s)).toList();
    final roleMatch = titleWords.any((s) => ResumeParser.containsTerm(roleText, s));
    final location = profile.get('location').trim().toLowerCase();
    final locationMatch = location.isNotEmpty && job.location.toLowerCase().split(',').any((s) => location.contains(s.trim()) && s.trim().isNotEmpty);
    final score = (skillScore + (roleMatch ? 20 : 0) + (locationMatch ? 10 : 0)).round().clamp(0, 100);
    final automatic = job.status == ApplicationStatus.discovered || job.status == ApplicationStatus.matched;
    return job.copyWith(score: score, matchedSkills: matched, gaps: gaps,
      status: automatic ? (score >= 40 ? ApplicationStatus.matched : ApplicationStatus.discovered) : job.status,
      explanation: 'Skills: ${skillScore.round()}/70. Role: ${roleMatch ? 20 : 0}/20. Location: ${locationMatch ? 10 : 0}/10. Missing information earns no points. Role suggestions are inferred from skills, not verified experience. This is a relevance score, not a hiring probability.');
  }
}

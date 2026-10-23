import 'dart:convert';

const profileFields = <String>[
  'name', 'email', 'phone', 'location', 'education', 'experience',
  'skills', 'projects', 'certifications', 'roles',
];

class ResumeProfile {
  ResumeProfile({Map<String, String>? fields, this.rawText = '', this.resumePath = '', this.resumeName = ''})
      : fields = Map.unmodifiable({for (final key in profileFields) key: fields?[key] ?? ''});
  final Map<String, String> fields;
  final String rawText, resumePath, resumeName;
  String get(String key) => fields[key] ?? '';
  bool get isEmpty => fields.values.every((v) => v.trim().isEmpty);
  Map<String, dynamic> toJson() => {'fields': fields, 'rawText': rawText, 'resumePath': resumePath, 'resumeName': resumeName};
  factory ResumeProfile.fromJson(Map<String, dynamic> json) => ResumeProfile(
    fields: Map<String, String>.from(json['fields'] as Map? ?? {}),
    rawText: json['rawText'] as String? ?? '', resumePath: json['resumePath'] as String? ?? '', resumeName: json['resumeName'] as String? ?? '',
  );
}

enum ApplicationStatus {
  discovered('Discovered'), matched('Matched'), ready('Ready'), applying('Applying'),
  applied('Applied'), failed('Failed'), needsAction('Needs Action'),
  submissionUnconfirmed('Submission Unconfirmed');
  const ApplicationStatus(this.label);
  final String label;
  static ApplicationStatus parse(String value) => ApplicationStatus.values.firstWhere((s) => s.name == value, orElse: () => ApplicationStatus.discovered);
}

class Job {
  const Job({required this.id, required this.title, required this.company, required this.location, required this.description, required this.skills,
    this.source = 'Manual', this.applicationUrl = '', this.score = 0, this.matchedSkills = const [], this.gaps = const [], this.explanation = '',
    this.status = ApplicationStatus.discovered, this.updatedAt = '', this.error = ''});
  final String id, title, company, location, description, source, applicationUrl, explanation, updatedAt, error;
  final List<String> skills, matchedSkills, gaps;
  final int score;
  final ApplicationStatus status;
  Job copyWith({int? score, List<String>? matchedSkills, List<String>? gaps, String? explanation, ApplicationStatus? status, String? updatedAt, String? error}) => Job(
    id: id, title: title, company: company, location: location, description: description, skills: skills, source: source, applicationUrl: applicationUrl,
    score: score ?? this.score, matchedSkills: matchedSkills ?? this.matchedSkills, gaps: gaps ?? this.gaps, explanation: explanation ?? this.explanation,
    status: status ?? this.status, updatedAt: updatedAt ?? this.updatedAt, error: error ?? this.error,
  );
  Map<String, Object?> toRow() => {'id': id, 'title': title, 'company': company, 'location': location, 'description': description, 'skills': jsonEncode(skills),
    'source': source, 'application_url': applicationUrl, 'score': score, 'matched_skills': jsonEncode(matchedSkills), 'gaps': jsonEncode(gaps), 'explanation': explanation,
    'status': status.name, 'updated_at': updatedAt, 'error': error};
  factory Job.fromRow(Map<String, Object?> row) => Job(
    id: row['id'] as String, title: row['title'] as String, company: row['company'] as String, location: row['location'] as String,
    description: row['description'] as String, skills: List<String>.from(jsonDecode(row['skills'] as String) as List),
    source: row['source'] as String, applicationUrl: row['application_url'] as String, score: row['score'] as int,
    matchedSkills: List<String>.from(jsonDecode(row['matched_skills'] as String) as List), gaps: List<String>.from(jsonDecode(row['gaps'] as String) as List),
    explanation: row['explanation'] as String, status: ApplicationStatus.parse(row['status'] as String), updatedAt: row['updated_at'] as String,
    error: row['error'] as String,
  );
}

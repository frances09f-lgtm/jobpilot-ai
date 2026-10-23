from pathlib import Path
p=Path('lib/core/resume_parser.dart')
s=p.read_text()
s=s.replace("import '../data/models.dart';", "import '../data/models.dart';\nimport 'resume_location_parser.dart';")
s=s.replace("for (final field in ['name', 'location', 'roles'])", "for (final field in ['name', 'roles'])")
s=s.replace(".where(_nameLike).toList()", ".where((v) => _nameLike(v) && !ResumeLocationParser.locationShape(v)).toList()")
a=s.index("      if (result['location']!.isEmpty && contactHeader") if "      if (result['location']!.isEmpty && contactHeader" in s else s.index("    if (result['location']!.isEmpty && contactHeader")
b=s.index("for (final field in ['education'",a)
s=s[:a]+"    result['location'] = ResumeLocationParser().parse(lines, header);\n    "+s[b:]
p.write_text(s)

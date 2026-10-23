/// Copies address text, never resolves a PIN code to a guessed city.
class ResumeLocationParser {
  static final label = RegExp(r'^(?:location|(?:permanent |current |postal |residential )?address|city|based in)\s*[:|]\s*(.*)$', caseSensitive: false);
  static final pin = RegExp(r'^(?:pin(?:\s*code)?|postal\s*code|zip(?:\s*code)?)\s*[:\-]?\s*([1-9]\d{5})$', caseSensitive: false);
  static final state = RegExp(r'\b(?:Maharashtra|Karnataka|Gujarat|Goa|Kerala|Tamil Nadu|Telangana|Andhra Pradesh|Madhya Pradesh|Uttar Pradesh|West Bengal|Rajasthan|Punjab|Haryana|Bihar|Odisha|Assam|Delhi|Jharkhand|Chhattisgarh|Uttarakhand|Himachal Pradesh|Sikkim|Tripura|Meghalaya|Manipur|Mizoram|Nagaland|Arunachal Pradesh|Jammu and Kashmir|Ladakh)\b', caseSensitive: false);
  static bool placeLine(String value) {
    if (value.isEmpty || value.length > 180 || value.contains('@') || value.contains('://') || pin.hasMatch(value)) return false;
    if (RegExp(r'\b(?:skills?|education|experience|projects?|certifications?|developer|engineer|college|university|school|bachelor|technology|computer|science|company|employment|Flutter|Dart|Kotlin|Java|Python|JavaScript|TypeScript|React|SQL|SQLite|Firebase|Git|HTML|CSS|Excel|Docker|AWS)\b', caseSensitive: false).hasMatch(value)) return false;
    if (RegExp(r'\+?\d(?:[ \t().\-]*\d){9,}').hasMatch(value)) return false;
    return RegExp(r"^[\p{L}\p{M}\d ,.'’/#()\-:]+$", unicode: true).hasMatch(value) && RegExp(r'\p{L}', unicode: true).hasMatch(value);
  }
  static bool locationShape(String value) => placeLine(value) &&
    (value.contains(',') || state.hasMatch(value) || RegExp(r'\b[1-9]\d{5}\b').hasMatch(value));
  String parse(List<String> lines, List<String> header) {
    final explicit = <String>{};
    for (var i = 0; i < lines.length; i++) {
      final match = label.firstMatch(lines[i]);
      if (match == null) continue;
      final parts = <String>[];
      final inline = match.group(1)!.trim();
      if (inline.isNotEmpty) parts.add(inline);
      for (var n = i + 1; n < lines.length && n <= i + 4; n++) {
        final next = lines[n];
        if (pin.hasMatch(next) || RegExp(r'^[1-9]\d{5}$').hasMatch(next)) { if (parts.isNotEmpty) parts.add(next); break; }
        if (!placeLine(next) || label.hasMatch(next)) break;
        if (locationShape(next) || (parts.isEmpty && placeLine(next))) { parts.add(next); } else { break; }
      }
      if (parts.isNotEmpty) explicit.add(parts.join('\n'));
    }
    if (explicit.isNotEmpty) return explicit.length == 1 ? explicit.single : '';
    final candidates = <String>{};
    for (var i = 0; i < header.length; i++) {
      for (final segment in header[i].split(RegExp(r'[|•]'))) {
        final value = segment.trim();
        if (!locationShape(value)) continue;
        final parts = <String>[value];
        for (var n = i + 1; n < header.length && n <= i + 2; n++) {
          final next = header[n];
          if (pin.hasMatch(next) || RegExp(r'^[1-9]\d{5}$').hasMatch(next)) { parts.add(next); break; }
          if (placeLine(next) && state.hasMatch(next) && !next.contains(',')) { parts.add(next); } else { break; }
        }
        final joined = parts.join('\n');
        if (!candidates.any((c) => c.split('\n').contains(value))) candidates.add(joined);
      }
    }
    // City/state split across adjacent contact-header lines, never a PIN lookup.
    if (candidates.length == 1) {
      final c = candidates.single;
      final start = header.indexOf(c.split('\n').first);
      if (start > 1 && state.hasMatch(c.split('\n').first) && !c.split('\n').first.contains(',')) {
        final city = header[start - 1];
        if (placeLine(city) && city.split(RegExp(r'\s+')).length <= 3 && !city.contains(':')) return '$city\n$c';
      }
      return c;
    }
    return '';
  }
}

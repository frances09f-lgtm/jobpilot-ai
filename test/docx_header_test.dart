import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/document_extractor.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
void main() {
  test('DOCX identity in a header reaches the parser before body skills', () async {
    final zip = Archive()
      ..addFile(ArchiveFile.string('word/header1.xml', '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>MIRA DESAI</w:t></w:r></w:p><w:p><w:r><w:t>mira@example.test</w:t></w:r></w:p></w:hdr>'))
      ..addFile(ArchiveFile.string('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Skills: Dart</w:t></w:r></w:p></w:body></w:document>'));
    final text = await DocumentExtractor().extract('fictional.docx', Uint8List.fromList(ZipEncoder().encode(zip)));
    final profile = ResumeParser().parse(text);
    expect(profile.get('name'), 'MIRA DESAI');
    expect(profile.get('email'), 'mira@example.test');
    expect(profile.get('skills'), 'Dart');
  });
}

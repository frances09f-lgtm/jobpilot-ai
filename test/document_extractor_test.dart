import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/document_extractor.dart';

void main() {
  final extractor = DocumentExtractor();
  Uint8List docx(String body) {
    final archive = Archive()..addFile(ArchiveFile.string('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$body</w:body></w:document>'));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
  test('DOCX preserves paragraph boundaries, split runs and tabs', () async {
    final bytes = docx('<w:p><w:r><w:t>Name: Example</w:t></w:r><w:r><w:t> Person</w:t></w:r></w:p><w:p><w:r><w:t>Skills: Flutter</w:t><w:tab/><w:t>Dart</w:t></w:r></w:p>');
    expect(await extractor.extract('resume.docx', bytes), 'Name: Example Person\nSkills: Flutter Dart');
  });
  test('empty or scanned-like DOCX yields actionable error, not invented text', () async {
    await expectLater(extractor.extract('scan.docx', docx('<w:p/>')), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('No readable text'))));
  });
  test('unsupported old DOC is rejected', () async {
    await expectLater(extractor.extract('resume.doc', Uint8List.fromList([1, 2, 3])), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Only text-based PDF and DOCX'))));
  });
  test('empty file is rejected', () async {
    await expectLater(extractor.extract('resume.docx', Uint8List(0)), throwsFormatException);
  });
  test('oversized file is rejected before parsing', () async {
    await expectLater(extractor.extract('resume.docx', Uint8List(DocumentExtractor.maxBytes + 1)), throwsFormatException);
  });
  test('ZIP without main Word document is rejected', () {
    final archive = Archive()..addFile(ArchiveFile.string('other.txt', 'text'));
    expect(() => extractor.extractDocx(Uint8List.fromList(ZipEncoder().encode(archive))), throwsFormatException);
  });
}

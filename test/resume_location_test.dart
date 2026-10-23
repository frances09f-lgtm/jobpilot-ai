import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobpilot_ai/core/document_extractor.dart';
import 'package:jobpilot_ai/core/resume_parser.dart';
import 'package:jobpilot_ai/data/models.dart';

void main() {
  final parser = ResumeParser();
  const contact = 'MIRA DESAI\nmira@example.test\n';
  test('three-part village district state is copied without a required name', () {
    expect(parser.parse('mira@example.test\nRukadi, Kolhapur, Maharashtra\nSkills: Dart').get('location'), 'Rukadi, Kolhapur, Maharashtra');
  });
  test('header address does not create a second name candidate', () {
    final p = parser.parse('${contact}Rukadi, Kolhapur, Maharashtra\nSkills: Dart');
    expect(p.get('name'), 'MIRA DESAI');
    expect(p.get('location'), 'Rukadi, Kolhapur, Maharashtra');
  });
  test('inline address including house number and PIN is copied', () {
    expect(parser.parse('${contact}Address: 12, Main Road, Rukadi, Kolhapur, Maharashtra - 416118\nSkills: Dart').get('location'), '12, Main Road, Rukadi, Kolhapur, Maharashtra - 416118');
  });
  test('multi-line address and separate PIN survive extraction boundaries', () {
    expect(parser.parse('${contact}Address:\n12 Main Road\nRukadi, Kolhapur, Maharashtra\nPIN: 416118\nSkills: Dart').get('location'), '12 Main Road\nRukadi, Kolhapur, Maharashtra\nPIN: 416118');
  });
  test('city/state header lines and bare PIN are copied', () {
    expect(parser.parse('${contact}Kolhapur\nMaharashtra\n416001\nSkills: Dart').get('location'), 'Kolhapur\nMaharashtra\n416001');
  });
  test('PIN beside state is copied, no lookup or inferred city', () {
    expect(parser.parse('${contact}Maharashtra - 416118\nSkills: Dart').get('location'), 'Maharashtra - 416118');
    expect(parser.parse('${contact}PIN: 416118\nSkills: Dart').get('location'), '');
  });
  test('missing or competing locations stay empty', () {
    expect(parser.parse('${contact}Skills: Dart\nExperience\nDeveloper in Pune, Maharashtra').get('location'), '');
    expect(parser.parse('${contact}Pune, Maharashtra\nKolhapur, Maharashtra\nSkills: Dart').get('location'), '');
  });
  test('old empty location is filled from saved text without replacing edits', () {
    final raw = '${contact}Rukadi, Kolhapur, Maharashtra\nSkills: Dart';
    expect(parser.prefillMissing(ResumeProfile(rawText: raw)).get('location'), 'Rukadi, Kolhapur, Maharashtra');
    expect(parser.prefillMissing(ResumeProfile(fields: {'location': 'Edited'}, rawText: raw)).get('location'), 'Edited');
  });
  test('DOCX header with split XML runs passes address to profile', () async {
    final zip = Archive()
      ..addFile(ArchiveFile.string('word/header1.xml', '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>MIRA DESAI</w:t></w:r></w:p><w:p><w:r><w:t>mira@example.test</w:t></w:r></w:p><w:p><w:r><w:t>Rukadi, Kolhapur, </w:t></w:r><w:r><w:t>Maharashtra - 416118</w:t></w:r></w:p></w:hdr>'))
      ..addFile(ArchiveFile.string('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Skills: Dart</w:t></w:r></w:p></w:body></w:document>'));
    final text = await DocumentExtractor().extract('fictional.docx', Uint8List.fromList(ZipEncoder().encode(zip)));
    expect(parser.parse(text).get('location'), 'Rukadi, Kolhapur, Maharashtra - 416118');
  });
}

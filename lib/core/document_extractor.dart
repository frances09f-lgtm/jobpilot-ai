import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

class DocumentExtractor {
  static const maxBytes = 10 * 1024 * 1024;
  Future<String> extract(String name, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) throw const FormatException('Choose a non-empty resume under 10 MB.');
    final extension = name.split('.').last.toLowerCase();
    String text;
    if (extension == 'pdf') {
      final document = await PdfDocument.openData(bytes, sourceName: name);
      try {
        if (document.pages.length > 50) throw const FormatException('Please use a resume with 50 pages or fewer.');
        final buffer = StringBuffer();
        for (final page in document.pages) {
          buffer.writeln((await page.loadText())?.fullText ?? '');
        }
        text = buffer.toString();
      } finally {
        await document.dispose();
      }
    } else if (extension == 'docx') {
      text = extractDocx(bytes);
    } else {
      throw const FormatException('Only text-based PDF and DOCX files are supported. Convert old DOC files first.');
    }
    if (text.trim().isEmpty) throw const FormatException('No readable text found. Scanned resumes need OCR outside this app. Upload a text-based PDF or DOCX, or edit your profile manually.');
    if (text.length > 200000) throw const FormatException('This document contains too much text. Please use a shorter resume.');
    return text;
  }

  String extractDocx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final document = archive.findFile('word/document.xml');
    if (document == null) throw const FormatException('This is not a valid DOCX document.');
    if (document.size > 2 * 1024 * 1024) throw const FormatException('DOCX text exceeds the 2 MB extraction limit.');
    final extras = archive.files.where((f) => RegExp(r'^word/(?:header|footer)\d+\.xml$').hasMatch(f.name)).toList()..sort((a, b) => a.name.compareTo(b.name));
    final parts = [...extras.where((f) => f.name.contains('/header')), document, ...extras.where((f) => f.name.contains('/footer'))];
    if (parts.fold<int>(0, (sum, f) => sum + f.size) > 2 * 1024 * 1024) throw const FormatException('DOCX text exceeds the 2 MB extraction limit.');
    return parts.map((part) => _paragraphs(utf8.decode(part.content))).join('\n');
  }

  String _paragraphs(String source) {
    final xml = XmlDocument.parse(source);
    return xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'p').map((paragraph) {
      final buffer = StringBuffer();
      for (final node in paragraph.descendants.whereType<XmlElement>()) {
        if (node.name.local == 't') buffer.write(node.innerText);
        if (node.name.local == 'tab') buffer.write(' ');
        if (node.name.local == 'br') buffer.write('\n');
      }
      return buffer.toString();
    }).join('\n');
  }
}

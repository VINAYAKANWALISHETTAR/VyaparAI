// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

Future<String?> downloadFile(
  String content,
  String fileName, {
  String? mimeType,
  String? subject,
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType ?? 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  return null;
}

Future<String?> downloadBytesFile(
  List<int> bytes,
  String fileName, {
  String? mimeType,
  String? subject,
}) async {
  final type = mimeType ?? (fileName.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream');
  final blob = html.Blob([bytes], type);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
  return null;
}

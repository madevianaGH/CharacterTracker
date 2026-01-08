// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadTextFile(
  String filename,
  String contents, {
  String mimeType = 'application/json',
}) {
  final bytes = utf8.encode(contents);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final a = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body!.children.add(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}

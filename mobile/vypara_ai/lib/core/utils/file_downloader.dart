import 'file_downloader_io.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static Future<String?> download(
    String content,
    String fileName, {
    String? mimeType,
    String? subject,
  }) async {
    return downloadFile(content, fileName, mimeType: mimeType, subject: subject);
  }

  static Future<String?> downloadBytes(
    List<int> bytes,
    String fileName, {
    String? mimeType,
    String? subject,
  }) async {
    return downloadBytesFile(bytes, fileName, mimeType: mimeType, subject: subject);
  }
}

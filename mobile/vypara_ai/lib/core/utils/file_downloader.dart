import 'file_downloader_io.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static Future<String?> download(String content, String fileName) async {
    return downloadFile(content, fileName);
  }

  static Future<String?> downloadBytes(List<int> bytes, String fileName) async {
    return downloadBytesFile(bytes, fileName);
  }
}

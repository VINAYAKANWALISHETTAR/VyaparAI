import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static void download(String content, String fileName) {
    downloadFile(content, fileName);
  }
}

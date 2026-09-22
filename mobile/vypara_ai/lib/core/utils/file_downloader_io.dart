import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> downloadFile(
  String content,
  String fileName, {
  String? mimeType,
  String? subject,
}) async {
  final targetMime = mimeType ?? 'text/csv';
  try {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);

    try {
      final res = await OpenFilex.open(file.path, type: targetMime);
      if (res.type != ResultType.done) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: targetMime, name: fileName)],
            subject: subject ?? fileName,
          ),
        );
      }
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: targetMime, name: fileName)],
          subject: subject ?? fileName,
        ),
      );
    }
    return file.path;
  } catch (e) {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: targetMime, name: fileName)],
          subject: subject ?? fileName,
        ),
      );
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

Future<String?> downloadBytesFile(
  List<int> bytes,
  String fileName, {
  String? mimeType,
  String? subject,
}) async {
  final targetMime = mimeType ?? 'application/pdf';
  try {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    try {
      final res = await OpenFilex.open(file.path, type: targetMime);
      if (res.type != ResultType.done) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: targetMime, name: fileName)],
            subject: subject ?? fileName,
          ),
        );
      }
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: targetMime, name: fileName)],
          subject: subject ?? fileName,
        ),
      );
    }
    return file.path;
  } catch (e) {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: targetMime, name: fileName)],
          subject: subject ?? fileName,
        ),
      );
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

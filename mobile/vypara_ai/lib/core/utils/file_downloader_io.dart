import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<String?> downloadFile(String content, String fileName) async {
  try {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await OpenFilex.open(file.path);
    return file.path;
  } catch (e) {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);
      await OpenFilex.open(file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

Future<String?> downloadBytesFile(List<int> bytes, String fileName) async {
  try {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
    return file.path;
  } catch (e) {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

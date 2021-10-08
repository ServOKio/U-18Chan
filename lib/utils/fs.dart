import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FS {
  static const MethodChannel _channel = const MethodChannel('downloads_path_provider');

  static Future<String> get downloadsDirectory async {
    return await _channel.invokeMethod('getDownloadsDirectory');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/counter.txt');
  }

  Future<int> readCounter() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  Future<File> writeCounter(String text) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(text);
  }
}
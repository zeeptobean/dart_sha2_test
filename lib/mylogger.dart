import 'dart:io';

import 'package:ansicolor/ansicolor.dart';

class MyLogger {
  static AnsiPen get _errorPen => AnsiPen()..red(bold: true);
  static AnsiPen get _successPen => AnsiPen()..green(bold: true);
  static AnsiPen get _warningPen => AnsiPen()..yellow(bold: true);
  static AnsiPen get _infoPen => AnsiPen()..blue(bold: true);

  final File _file;
  late IOSink _sink;

  static String _defaultFilename() {
    final now = DateTime.now();
    return 'log_${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.txt';
  }

  MyLogger({String? path}) : _file = File(path ?? _defaultFilename()) {
    _sink = _file.openWrite(mode: FileMode.append);
    print('Logger: File opened at $path');
  }

  void logError(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print(_errorPen(message));
    _sink.writeln('$timestamp: [ERR] $message');
  }

  void logSuccess(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print(_successPen(message));
    _sink.writeln('$timestamp: [OK] $message');
  }

  void logWarning(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print(_warningPen(message));
    _sink.writeln('$timestamp: [WARN] $message');
  }

  void logInfo(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print(_infoPen(message));
    _sink.writeln('$timestamp: [INFO] $message');
  }

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print(message);
    _sink.writeln('$timestamp: $message');
  }
  
  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
    print('Logger: File closed.');
  }
  
}
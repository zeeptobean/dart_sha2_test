import 'package:ansicolor/ansicolor.dart';

class ColorText {
  static AnsiPen get error => AnsiPen()..red(bold: true);
  static AnsiPen get success => AnsiPen()..green(bold: true);
  static AnsiPen get warning => AnsiPen()..yellow(bold: true);
  static AnsiPen get info => AnsiPen()..blue(bold: true);
}
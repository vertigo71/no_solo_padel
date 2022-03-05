///
/// apply after pulling from repository
///
/// copy pubspec_prod.yaml into pubspec.yaml
///
/// execute like: dart run production.dart
///
import 'dart:io';

const String filePubSpecName = '../pubspec.yaml';
const String fileProdName = '../pubspec_prod.yaml';

// ignore: avoid_print
void myPrint( var v) => print(v);

void main() async {
  final fileIn = File(fileProdName);
  try {
    fileIn.copy(filePubSpecName);
  } catch (e) {
    myPrint(e);
  }
}

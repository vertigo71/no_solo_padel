///
/// apply before pushing to repository
///
/// copy pubspec.yaml into dev and prod files
///
/// execute like: dart run development.dart
///
import 'dart:io';

const String filePubSpecName = '../pubspec.yaml';
const String fileProdName = '../pubspec_prod.yaml';

// ignore: avoid_print
void myPrint( var v) => print(v);

void main() async {
  final fileIn = File(filePubSpecName);
  try {
    fileIn.copy(filePubSpecName);
  } catch (e) {
    myPrint(e);
  }
}

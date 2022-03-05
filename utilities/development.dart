///
/// apply before pushing to repository
///
/// copy pubspec.yaml into dev and prod files
///
/// execute like: dart run development.dart
///
import 'dart:io';
import 'dart:convert';
import 'dart:async';

const String relativePath = '../';
String filePubSpecName = 'pubspec.yaml';
String fileProdName = 'pubspec_prod.yaml';
String fileDevName = 'pubspec_dev.yaml';
const String devString = 'name: no_solo_padel_dev';
const String prodString = 'name: no_solo_padel';

// ignore: avoid_print
void myPrint(var v) => print(v);

void main() async {
  File fileIn = File(filePubSpecName);
  if (!await fileIn.exists()) {
    myPrint('$fileIn doesn\'t exist');
    filePubSpecName = relativePath + filePubSpecName;
    fileProdName = relativePath + fileProdName;
    fileDevName = relativePath + fileDevName;
    fileIn = File(filePubSpecName);
  }
  final fileProd = File(fileProdName);
  final fileDev = File(fileDevName);
  RegExp exp = RegExp(r"^name:");
  try {
    if (await fileIn.exists()) {
      Stream<String> linesIn = fileIn
          .openRead()
          .transform(utf8.decoder) // Decode bytes to UTF-8
          .transform(const LineSplitter()); // Convert stream to individual lines
      IOSink sinkProd = fileProd.openWrite();
      IOSink sinkDev = fileDev.openWrite();
      myPrint('Copying $fileIn to $fileProd and $fileDev');
      await for (var line in linesIn) {
        if (exp.stringMatch(line) != null) {
          sinkProd.writeln(prodString);
          sinkDev.writeln(devString);
        } else {
          sinkProd.writeln(line);
          sinkDev.writeln(line);
        }
      }
      sinkProd.close();
      sinkDev.close();
      myPrint('Done!');
    } else {
      myPrint('$fileIn doesn\'t exist');
    }
  } catch (e) {
    myPrint('Error: $e');
  }
}

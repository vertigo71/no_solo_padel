///
/// apply after pulling from repository
///
/// copy pubspec_prod.yaml into pubspec.yaml
///
/// execute like: dart run production.dart
///
import 'dart:io';

const String relativePath = '../';
 String filePubSpecName = 'pubspec.yaml';
 String fileProdName = 'pubspec_prod.yaml';

// ignore: avoid_print
void myPrint(var v) => print(v);

void main() async {
  File fileIn = File(fileProdName);
  if (!await fileIn.exists()) {
    myPrint('$fileIn doesn\'t exist');
    filePubSpecName = relativePath + filePubSpecName;
    fileProdName = relativePath + fileProdName;
    fileIn = File(filePubSpecName);
  }
  try {
    if (await fileIn.exists()) {
      myPrint('Copying $fileIn to $filePubSpecName');
      fileIn.copy(filePubSpecName);
      myPrint('Done!');
    } else {
      myPrint('$fileIn doesn\'t exist');
    }
  } catch (e) {
    myPrint(e);
  }
}

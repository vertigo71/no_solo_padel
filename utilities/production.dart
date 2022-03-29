///
/// apply after pulling from repository
///
/// copy pubspec_prod.yaml into pubspec.yaml
///
/// execute like: dart run production.dart
///
import 'dart:io';
import 'dart:convert';

const String fileIndexWeb = 'web/index.html';
const String filePubSpecName = 'pubspec.yaml';
const String fileProdName = 'pubspec_prod.yaml';

// ignore: avoid_print
void myPrint(var v) => print(v);

void errorPrint( dynamic error ){
  if ( error.toString().isNotEmpty) {
    stderr.write('ERROR!!!');
    stderr.write(error);
  }
}

Future<void> copyPubspecProdToPubspec() async {
  File fileIn = File(fileProdName);
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

Future<bool> checkBugFender() async {
  final File fileIn = File(fileIndexWeb);
  RegExp exp = RegExp(r"bugfender");
  try {
    if (await fileIn.exists()) {
      Stream<String> linesIn = fileIn
          .openRead()
          .transform(utf8.decoder) // Decode bytes to UTF-8
          .transform(const LineSplitter()); // Convert stream to individual lines
      await for (var line in linesIn) {
        if (exp.stringMatch(line) != null) {
          return true;
        }
      }
    } else {
      myPrint('$fileIn doesn\'t exist');
    }
  } catch (e) {
    myPrint('Error: $e');
  }
  return false;
}

void main() async {
  String curFullDir = Directory.current.path;
  const String curDir = '\\no_solo_padel';
  if (curDir != curFullDir.substring(curFullDir.length - curDir.length)) {
    myPrint('Wrong environment!!!');
    return;
  }

  String answer = '';

  // pull
  stdout.write('git pull from repository (s/N)?: ');
  answer = stdin.readLineSync() ?? '';
  if (answer.toLowerCase() == 's') {
    ProcessResult result = await Process.run('git', ['pull', 'origin', 'master']);
    stdout.write(result.stdout);
    errorPrint(result.stderr);
  }


  // check bugfender
  myPrint('Checking BugFender');
  bool exists = await checkBugFender();
  if ( exists) {
    myPrint('BugFender line in index.html exists');
  } else {
    errorPrint('Add BugFender line in index.html');
    return;
  }

  // copyPubspecProdToPubspec
  stdout.write('Copy pubspec_prod to pubspec (s/N)?: ');
  answer = stdin.readLineSync() ?? '';
  if (answer.toLowerCase() == 's') {
    await copyPubspecProdToPubspec();
  }

  // build
  stdout.write('flutter build web (s/N)?: ');
  answer = stdin.readLineSync() ?? '';
  if (answer.toLowerCase() == 's') {
    myPrint('flutter build web running ....');
    ProcessResult result = await Process.run('flutter', ['build', 'web'], runInShell: true);
    stdout.write(result.stdout);
    errorPrint(result.stderr);

    if (result.exitCode == 0) {
      // firebase
      stdout.write('firebase deploy (s/N)?: ');
      answer = stdin.readLineSync() ?? '';
      if (answer.toLowerCase() == 's') {
        myPrint('firebase deploy running ....');
        ProcessResult result = await Process.run('firebase', ['deploy'], runInShell: true);
        stdout.write(result.stdout);
        errorPrint(result.stderr);
      }
    }
  }
}

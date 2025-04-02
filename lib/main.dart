// ignore_for_file: unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options_dev.dart';
import 'firebase_options_stage.dart';
import 'firebase_options_prod.dart';

import 'interface/director.dart';
import 'models/debug.dart';
import 'routes/routes.dart';
import 'interface/app_state.dart';
import 'secret.dart';
import 'utilities/environment.dart';
import 'utilities/theme.dart';

final String _classString = 'main'.toUpperCase();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // use flavors to choose between dev, stage and prod
  String flavor = const String.fromEnvironment('FLAVOR');
  FirebaseOptions firebaseOptions;
  if (flavor == devEnvironment) {
    firebaseOptions = firebaseOptionsDev;
  } else if (flavor == stageEnvironment) {
    firebaseOptions = firebaseOptionsStage;
  } else if (flavor == prodEnvironment) {
    firebaseOptions = firebaseOptionsProd;
  } else {
    runApp(MaterialApp(
      // Display an error message
      home: Scaffold(
        body: Center(
          child: Text('Error: Entorno $flavor no reconocido. Póngase en contacto con el administrador. \n'
              'Hay que definir la variable FLAVOR como dev o prod. Mirar el archivo deploy.sh'),
        ),
      ),
    ));
    return;
  }

  await Firebase.initializeApp(options: firebaseOptions);
  // The user remains signed in even after closing and reopening the app.
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  await initializeDateFormatting('es_ES', null); // Spanish
  MyLog.initialize();
  await Environment().initialize(flavor: flavor);

  await FlutterBugfender.init(
    getBugFenderAppId(),
    enableCrashReporting: true,
    enableUIEventLogging: true,
    enableAndroidLogcatLogging: false,
    printToConsole: false,
    version: "1",
    build: "1",
  );
  FlutterBugfender.log("Executing: ${DateTime.now()}");
  MyLog.log(_classString, 'Environment = $flavor');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building MyApp', level:Level.FINE);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(), // application state
        ),
        Provider<Director>(
          create: (context) => Director(appState: context.read<AppState>()), // knows it all
        ),
      ],
      child: MaterialApp.router(
        // Use MaterialApp.router
        debugShowCheckedModeBanner: false,
        theme: generateThemeData(context),
        routerConfig: AppRouter.router, // Assign the router
      ),
    );
  }
}

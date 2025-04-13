// ignore_for_file: unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options_dev.dart';
import 'firebase_options_stage.dart';
import 'firebase_options_prod.dart';

import 'interface/if_director.dart';
import 'models/md_debug.dart';
import 'routes/routes.dart';
import 'interface/if_app_state.dart';
import 'secret.dart';
import 'utilities/ut_environment.dart';
import 'utilities/ut_theme.dart';

final String _classString = 'main'.toUpperCase();

Future<void> main() async {
  // use flavors to choose between dev, stage and prod
  String flavor = const String.fromEnvironment('FLAVOR');
  FirebaseOptions firebaseOptions;
  if (flavor == kDevEnvironment) {
    firebaseOptions = firebaseOptionsDev;
  } else if (flavor == kStageEnvironment) {
    firebaseOptions = firebaseOptionsStage;
  } else if (flavor == kProdEnvironment) {
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

  await initializeDateFormatting('es_ES', null); // Spanish
  MyLog.initialize();
  await Environment().initialize(flavor: flavor);
  MyLog.log(_classString, 'Environment = $flavor');

  await SentryFlutter.init(
    (options) {
      options.dsn = getSentryDsn();
      // Adds request headers and IP for users,
      // visit: https://docs.sentry.io/platforms/dart/data-management/data-collected/ for more info
      options.sendDefaultPii = true;
      options.environment = flavor;
      options.maxBreadcrumbs = 1000;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(options: firebaseOptions);
      // The user remains signed in even after closing and reopening the app.
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      runApp(SentryWidget(child: MyApp()));
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building MyApp', level: Level.FINE);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(), // application state
        ),
        Provider<Director>(
          create: (context) => Director(appState: context.read<AppState>()), // knows it all
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kAltMedium,
              kPrimaryMedium,
              kPrimaryMedium,
            ],
          ),
        ),
        child: MaterialApp.router(
          // Use MaterialApp.router
          debugShowCheckedModeBanner: false,
          theme: generateThemeData(context),
          routerConfig: AppRouter.router, // Assign the router
        ),
      ),
    );
  }
}

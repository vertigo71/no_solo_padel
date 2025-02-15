import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null); // Spanish
  await Environment().initialize();
  await FlutterBugfender.init(getBugFenderAppId(),
      enableAndroidLogcatLogging: false, version: "1", build: "1", printToConsole: false);
  MyLog.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building MyApp');

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

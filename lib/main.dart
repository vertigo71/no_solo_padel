import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'interface/director.dart';
import 'interface/match_notifier.dart';
import 'models/debug.dart';
import 'models/match_model.dart';
import 'routes/routes.dart';
import 'interface/app_state.dart';
import 'secret.dart';
import 'utilities/date.dart';
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
        ChangeNotifierProvider<MatchNotifier>(
          // this notifier will be used in home page to pass the match as argument
          // cannot be done directly using arguments in GoRoute because the back browser button kept
          // giving errors as MyMatch is too complex
          // a possible solution would be to pass a String with the date of the match as an argument (not tested)
          create: (context) => MatchNotifier(MyMatch(id:Date.now()), context.read<Director>()),
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

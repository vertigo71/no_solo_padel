import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'InformationPage'.toUpperCase();

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<MyMatch>? _allMatches;
  late MyUser _loggedUser;
  late AppState appState;
  late FsHelpers fsHelpers;

  Future<void> _getAllMatches() async {
    List<MyMatch> allMatches = await fsHelpers.getAllMatches(appState: appState);
    setState(() {
      _allMatches = allMatches;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Context Available: addPostFrameCallback ensures that the callback is executed
      // after the first frame is built,
      // so the BuildContext is available and providers are initialized.
      appState = context.read<AppState>();
      fsHelpers = context.read<Director>().fsHelpers;

      _loggedUser = appState.getLoggedUser();
      _getAllMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    int matchesPlayed = 0;
    int matchesSigned = 0;
    for (MyMatch match in _allMatches ?? []) {
      if (match.isInTheMatch(_loggedUser)) matchesSigned++;
      if (match.isPlaying(_loggedUser)) matchesPlayed++;
    }

    return Scaffold(
      body: ListView(
        children: [
          Card(
            elevation: 6,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                'En el último año\n'
                '  Has jugado ${singularOrPlural(matchesPlayed, 'partido')}\n'
                '  y apuntado a ${singularOrPlural(matchesSigned, 'partido')}',
              ),
            ),
          ),
          ...ListTile.divideTiles(
              context: context,
              tiles: appState.users.map(((user) {
                int numberOfMatchesTogether = 0;
                for (MyMatch match in _allMatches ?? []) {
                  if (match.arePlayingTogether(user, _loggedUser)) {
                    numberOfMatchesTogether++;
                  }
                }
                final String startTimes =
                    'Habéis empezado juntos: ${singularOrPlural(numberOfMatchesTogether, 'vez', 'veces')}';
                final String sosInfo = user.emergencyInfo.isNotEmpty ? '\nSOS: ${user.emergencyInfo}' : '';

                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: getUserColor(user), child: Text(user.userType.name[0].toUpperCase())),
                  title: Text(user.name + sosInfo),
                  subtitle: Text('$startTimes\n${user.email.split('@')[0]}'),
                );
              }))),
        ],
      ),
    );
  }
}

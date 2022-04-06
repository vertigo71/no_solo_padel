import 'package:flutter/material.dart';
import 'package:no_solo_padel_dev/utilities/misc.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/theme.dart';

final String _classString = 'InformationPage'.toUpperCase();

class InformationPage extends StatefulWidget {
  const InformationPage({Key? key}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<MyMatch>? _allMatches;
  late MyUser _loggedUser;
  late AppState appState;
  late FirebaseHelper firebaseHelper;

  Future<void> _getAllMatches() async {
    List<MyMatch> allMatches = await firebaseHelper.getAllMatches();
    setState(() {
      _allMatches = allMatches;
    });
  }

  @override
  void initState() {
    appState = context.read<AppState>();
    firebaseHelper = context.read<Director>().firebaseHelper;

    _loggedUser = appState.getLoggedUser();
    _getAllMatches();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    int matchesPlayed = 0;
    int matchesSigned = 0;
    for (MyMatch match in _allMatches ?? []) {
      if (match.isInTheMatch(_loggedUser.userId)) matchesSigned++;
      if (match.isPlaying(_loggedUser.userId)) matchesPlayed++;
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
              tiles: appState.allSortedUsers.map(((user) {
                int numberOfMatchesTogether = 0;
                for (MyMatch match in _allMatches ?? []) {
                  if (match.arePlayingTogether(user.userId, _loggedUser.userId)) {
                    numberOfMatchesTogether++;
                  }
                }

                return ListTile(
                  leading: CircleAvatar(
                      child: Text(user.userType.name[0].toUpperCase()),
                      backgroundColor: getUserColor(user)),
                  title: Text('${user.name}\n'
                          'Habéis empezado juntos: ' +
                      singularOrPlural(numberOfMatchesTogether, 'vez', 'veces')),
                  subtitle: Text(user.email.split('@')[0]),
                );
              }))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:no_solo_padel_dev/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../utilities/misc.dart';
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

  Future<void> _getAllMatches() async {
    FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;
    List<MyMatch> allMatches = await firebaseHelper.getAllMatches();
    setState(() {
      _allMatches = allMatches;
    });
  }

  @override
  void initState() {
    AppState appState = context.read<AppState>();
    _loggedUser = appState.getLoggedUser();

    _getAllMatches();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return ListView(
            children: [
              ...ListTile.divideTiles(
                  context: context,
                  tiles: appState.allSortedUsers.map(((user) {
                    int numberOfMatchesTogether = 0;
                    // get all matches that user and loggedUser have played together
                    for (MyMatch match in _allMatches ?? []) {
                      int positionUser = match.getPlayerPosition(user.userId);
                      int positionLoggedUser = match.getPlayerPosition(_loggedUser.userId);

                      if (positionUser != -1 &&
                          positionLoggedUser != -1 &&
                          match.getPlayingState(user.userId) == PlayingState.playing &&
                          match.getPlayingState(_loggedUser.userId) == PlayingState.playing) {
                        List<int> sortedList =
                            getRandomList(match.getNumberOfFilledCourts() * 4, match.date);
                        for (int pos = 0; pos < sortedList.length; pos += 2) {
                          if (sortedList[pos] == positionUser &&
                                  sortedList[pos + 1] == positionLoggedUser ||
                              sortedList[pos] == positionLoggedUser &&
                                  sortedList[pos + 1] == positionUser) {
                            MyLog().log(_classString, 'played with $user sorting=$sortedList',
                                myCustomObject: match.players);
                            numberOfMatchesTogether++;
                          }
                        }
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                          child: Text(user.userType.name[0].toUpperCase()),
                          backgroundColor: getUserColor(user)),
                      title: Text('${user.name}\n'
                              'Habéis empezado juntos: $numberOfMatchesTogether ' +
                          (numberOfMatchesTogether == 1 ? 'vez' : 'veces')),
                      subtitle: Text(user.email),
                    );
                  }))),
            ],
          );
        },
      ),
    );
  }
}

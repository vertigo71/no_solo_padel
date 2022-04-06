import 'package:flutter/material.dart';
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
                    for (MyMatch match in _allMatches ?? []) {
                      if ( match.arePlayingTogether(user.userId, _loggedUser.userId)){
                        numberOfMatchesTogether++;
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

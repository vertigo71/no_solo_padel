import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../utilities/http_helper.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../models/register_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/date.dart';
import '../../utilities/misc.dart';

final String _classString = 'PlayersPanel'.toUpperCase();

class PlayersPanel extends StatefulWidget {
  const PlayersPanel(this.date, {Key? key}) : super(key: key);

  final Date date;

  @override
  _PlayersPanelState createState() => _PlayersPanelState();
}

class _PlayersPanelState extends State<PlayersPanel> {
  late final AppState appState;

  late final MyUser loggedUser;
  bool loggedUserInTheMatch = false; // checkBox

  late MyUser selectedUser;
  bool isSelectedUserInTheMatch = false;
  final TextEditingController userPositionController = TextEditingController();

  @override
  void initState() {
    appState = context.read<AppState>();
    MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);

    loggedUser = appState.getLoggedUser();
    loggedUserInTheMatch = match.isInTheMatch(loggedUser.userId);
    selectedUser = appState.allSortedUsers[0];
    isSelectedUserInTheMatch = match.isInTheMatch(selectedUser.userId);

    MyLog().log(_classString, 'initState arguments = $match');
    MyLog().log(_classString, 'loggedUser in match= $loggedUserInTheMatch');

    super.initState();
  }

  @override
  void dispose() {
    userPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building for $loggedUser');

    return ListView(
      children: [
        signUpForm(),
        const Divider(thickness: 5),
        listOfPlayers(),
        const SizedBox(height: 20),
        if (appState.isLoggedUserAdmin) const Divider(thickness: 5),
        const SizedBox(height: 20),
        if (appState.isLoggedUserAdmin) signUpAdminForm(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget signUpForm() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('¿Te apuntas?'),
            const SizedBox(width: 20),
            Consumer<AppState>(
              builder: (context, appState, _) {

                MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);
                loggedUserInTheMatch = match.isInTheMatch(loggedUser.userId);

                return myCheckBox(
                context: context,
                value: loggedUserInTheMatch,
                onChanged: (bool? value) {
                  setState(() {
                    loggedUserInTheMatch = value!;
                  });
                  validate(
                    user: loggedUser,
                    toAdd: loggedUserInTheMatch,
                    adminManagingUser: false,
                  );
                },
              );
              },
            ),
          ],
        ),
      );

  Widget signUpAdminForm() {
    List<MyUser> users = appState.allSortedUsers;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: SizedBox(
              height: 260,
              child: ListWheelScrollView(
                itemExtent: 40,
                magnification: 1.3,
                useMagnifier: true,
                diameterRatio: 2,
                squeeze: 0.7,
                offAxisFraction: -0.3,
                perspective: 0.01,
                physics: const FixedExtentScrollPhysics(),
                scrollBehavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown
                  },
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedUser = users[index];
                    MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);
                    isSelectedUserInTheMatch = match.isInTheMatch(selectedUser.userId);
                  });
                },
                children: users
                    .map((u) => Container(
                          margin: const EdgeInsets.fromLTRB(50, 0, 20, 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Theme.of(context).backgroundColor),
                          child: Center(
                              child: Text(u.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ))),
                        ))
                    .toList(),
              ),
            ),
          ),
          const Spacer(),
          Flexible(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Consumer<AppState>(
                        builder: (context, appState, _) {
                          MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);
                          isSelectedUserInTheMatch = match.isInTheMatch(selectedUser.userId);
                          return Text(
                          (isSelectedUserInTheMatch ? 'Dar de baja a:\n\n' : 'Apuntar a:\n\n') +
                              selectedUser.name,
                          textAlign: TextAlign.center,
                        );
                        },
                      ),
                    ),
                    onPressed: () => validate(
                      user: selectedUser,
                      toAdd: !isSelectedUserInTheMatch,
                      adminManagingUser: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: isSelectedUserInTheMatch ? 0 : 1,
                    child: Form(
                        child: TextFormField(
                      enabled: !isSelectedUserInTheMatch,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                      onFieldSubmitted: (String str) async => validate(
                        user: selectedUser,
                        toAdd: true,
                        adminManagingUser: true,
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                      ],
                      controller: userPositionController,
                      // The validator receives the text that the user has entered.
                    )),
                  ),
                ],
              ))
        ],
      ),
    );
  }

  Widget listOfPlayers() => Consumer<AppState>(
        builder: (context, appState, _) {
          int playerNumber = 0;
          MyLog().log(_classString, 'Building listOfPlayers', debugType: DebugType.info);
          MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);

          List<MyUser> usersPlaying =
              appState.userIdsToUsers(match.getPlayers(state: PlayingState.playing));
          List<MyUser> usersSigned =
              appState.userIdsToUsers(match.getPlayers(state: PlayingState.signedNotPlaying));
          List<MyUser> usersReserve =
              appState.userIdsToUsers(match.getPlayers(state: PlayingState.reserve));
          List<MyUser> usersFillEmptySpaces = [];
          for (int i = usersPlaying.length + usersSigned.length;
              i < match.getNumberOfCourts() * 4;
              i++) {
            usersFillEmptySpaces.add(MyUser());
          }

          String numCourtsText = 'disponible ' +
              match.getNumberOfCourts().toString() +
              (match.getNumberOfCourts() == 1 ? ' pista' : ' pistas');

          return Column(
            children: [
              Card(
                elevation: 6,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  tileColor: Theme.of(context).appBarTheme.backgroundColor,
                  title: Text('Apuntados ($numCourtsText)'),
                ),
              ),
              Card(
                elevation: 6,
                margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...usersPlaying.map((player) =>
                          Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ...usersSigned.map((player) => Text(
                          '${(++playerNumber).toString().padLeft(3)} - ${player.name}',
                          style: const TextStyle(color: Colors.red))),
                      ...usersFillEmptySpaces
                          .map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ')),
                    ],
                  ),
                ),
              ),
              if (usersReserve.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    tileColor: Theme.of(context).appBarTheme.backgroundColor,
                    title: const Text('Reservas'),
                  ),
                ),
              if (usersReserve.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...usersReserve.map((player) =>
                            Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Future<bool> validate(
      {required MyUser user,
      required bool toAdd, // add user to match
      required bool adminManagingUser}) async {
    MyLog().log(_classString, 'validate');

    // update match in case it has changed
    MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);

    // check
    bool userInTheMatch = match.isInTheMatch(user.userId);
    if (!toAdd ^ userInTheMatch) {
      // toAdd and user already in the match
      // !toAdd and user not in the match
      showMessage(context, 'Nada por hacer');
      return false;
    }

    // Add/delete player from the match
    String message = 'Los datos han sido actualizados';
    String registerText = '';

    int listPosition = -1;
    if (toAdd) {
      if (adminManagingUser) {
        // get position from the controller
        String positionStr = userPositionController.text;
        listPosition = int.tryParse(positionStr) ?? -1;
        if (listPosition > 0) listPosition--;
      }
      match.insertPlayer(user.userId, position: listPosition);
      registerText = 'apuntado';
      MyLog().log(_classString, 'addding to the match position $listPosition');
    } else {
      if (!adminManagingUser) {
        // ask for confirmation if you are loggedUser trying to abandon the match
        const String option1 = 'Confirmar';
        const String option2 = 'Anular';
        String response = await myReturnValueDialog(
            context, '¿Seguro que quieres darte de baja?', option1, option2);
        MyLog().log(_classString, 'confirm response = $response');

        if (response != option1) {
          setState(() {
            // loggedUser is still in the match
            loggedUserInTheMatch = true;
          });
          showMessage(context, 'Operación anulada');
          return false;
        }
      }
      MyLog().log(_classString, 'removed from the match');
      registerText = 'desapuntado';
      match.removePlayer(user.userId);
    }

    // message to the register
    if (adminManagingUser) {
      if (listPosition >= match.players.length || listPosition == -1) {
        listPosition = match.players.length - 1;
      }
      registerText = '${loggedUser.name} ha $registerText a ${user.name}' +
          (toAdd ? ' (${listPosition + 1})' : '');
    } else {
      registerText = '${user.name} se ha $registerText';
    }

    // add to FireBase
    try {
      await context
          .read<Director>()
          .firebaseHelper
          .updateMatch(match: match, updateCore: false, updatePlayers: true);
      context.read<Director>().firebaseHelper.updateRegister(RegisterModel(
            date: match.date,
            message: registerText,
          ));
      sendDatedMessageToTelegram(
          message: '$registerText\n'
              'APUNTADOS: ${match.players.length} de ${match.getNumberOfCourts() * 4}',
          matchDate: match.date,
          fromDaysAgoToTelegram:
              appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
    } catch (e) {
      message = 'ERROR en la actualización de los datos. \n\n $e';
      MyLog().log(_classString, 'ERROR en la actualización de los datos',
          exception: e, debugType: DebugType.error);
      return false;
    }

    myAlertDialog(context, 'Con fecha\n${DateTime.now()} \n\n $registerText');

    userInTheMatch = match.isInTheMatch(user.userId);
    if (loggedUser == user) {
      setState(() {
        loggedUserInTheMatch = userInTheMatch;
      });
    }
    if (selectedUser == user) {
      // update state
      setState(() {
        isSelectedUserInTheMatch = userInTheMatch;
      });
    }
    showMessage(context, message);

    return true;
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../interface/telegram.dart';
import '../../models/debug.dart';
import '../../models/register_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'PlayersPanel'.toUpperCase();

class PlayersPanel extends StatefulWidget {
  const PlayersPanel(this.date, {Key? key}) : super(key: key);

  final Date date;

  @override
  _PlayersPanelState createState() => _PlayersPanelState();
}

class _PlayersPanelState extends State<PlayersPanel> {
  late final MyMatch match;

  late MyUser loggedUser;
  bool loggedUserInTheMatch = false; // checkBox

  late MyUser selectedUser;
  bool isSelectedUserInTheMatch = false;
  TextEditingController userPositionController = TextEditingController();

  @override
  void initState() {
    match = context.read<AppState>().getMatch(widget.date) ?? MyMatch(date: widget.date);

    loggedUser = context.read<AppState>().getLoggedUser();
    PlayingState state = match.getPlayingState(loggedUser);
    loggedUserInTheMatch = state != PlayingState.unsigned;
    isSelectedUserInTheMatch = loggedUserInTheMatch;
    selectedUser = loggedUser;

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
    MyLog().log(_classString, 'Building');

    AppState appState = context.read<AppState>();
    return ListView(
      children: [
        signUpForm(),
        const Divider(thickness: 5),
        if (appState.isLoggedUserAdmin) signUpAdminForm(),
        if (appState.isLoggedUserAdmin) const Divider(thickness: 5),
        listOfPlayers(),
      ],
    );
  }

  Widget signUpForm() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: loggedUserInTheMatch,
              onChanged: (bool? value) {
                setState(() {
                  loggedUserInTheMatch = value!;
                });
              },
            ),
            const SizedBox(width: 10),
            const Text('Me apunto!!!'),
            const SizedBox(width: 10),
            ElevatedButton(
              child: const Text('Confirmar'),
              onPressed: () => validate(
                user: loggedUser,
                toAdd: loggedUserInTheMatch,
                getPositionFromController: false,
                adminManagingUser: false,
              ),
            ),
          ],
        ),
      );

  Widget signUpAdminForm() {
    AppState appState = context.read<AppState>();
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
                magnification: 1.5,
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
                    isSelectedUserInTheMatch = match.isInTheMatch(selectedUser);
                  });
                },
                children: users
                    .map((u) => Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Theme.of(context).colorScheme.background),
                          child: Center(child: Text(u.name, style: const TextStyle(fontSize: 11))),
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
                  const SizedBox(height: 20),
                  Card(
                      elevation: 6,
                      color: Theme.of(context).colorScheme.background,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(selectedUser.name),
                      )),
                  if (!isSelectedUserInTheMatch) const SizedBox(height: 20),
                  if (!isSelectedUserInTheMatch)
                    Form(
                        child: TextFormField(
                      onFieldSubmitted: (String str) async => validate(
                        user: selectedUser,
                        toAdd: true,
                        getPositionFromController: true,
                        adminManagingUser: true,
                      ),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                      ],
                      controller: userPositionController,
                      // The validator receives the text that the user has entered.
                    )),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        isSelectedUserInTheMatch ? 'Dar de baja' : 'Apuntar',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: () => validate(
                      user: selectedUser,
                      toAdd: !isSelectedUserInTheMatch,
                      getPositionFromController: true,
                      adminManagingUser: true,
                    ),
                  ),
                ],
              ))
        ],
      ),
    );
  }

  Widget listOfPlayers() => Consumer<AppState>(
        builder: (context, state, _) {
          int playerNumber = 0;

          Set<MyUser> usersPlaying = match.getPlayers(state: PlayingState.playing);
          Set<MyUser> usersSigned = match.getPlayers(state: PlayingState.signedNotPlaying);
          Set<MyUser> usersReserve = match.getPlayers(state: PlayingState.reserve);
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
                  tileColor: Theme.of(context).colorScheme.background,
                  title: Text('Apuntados ($numCourtsText)',
                      style: const TextStyle(color: Colors.black)),
                  enabled: false,
                ),
              ),
              Card(
                elevation: 6,
                margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                color: Theme.of(context).colorScheme.background,
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
                    tileColor: Theme.of(context).colorScheme.background,
                    title: const Text('Reservas', style: TextStyle(color: Colors.black)),
                    enabled: false,
                  ),
                ),
              if (usersReserve.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  color: Theme.of(context).colorScheme.background,
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
      required bool toAdd,
      bool getPositionFromController = false,
      required bool adminManagingUser}) async {
    MyLog().log(_classString, 'validate');

    // check
    bool userInTheMatch = match.isInTheMatch(user);
    if (!toAdd ^ userInTheMatch) {
      // toAdd and user already in the match
      // !toAdd and user not in the match
      showMessage(context, 'Nada por hacer');
      return false;
    }

    // Add/delete player from the match
    String message = 'Los datos han sido actualizados';
    String registerText = '';

    int position = -1;
    if (toAdd) {
      if (getPositionFromController) {
        String positionStr = userPositionController.text;
        position = int.tryParse(positionStr) ?? -1;
        if (position > 0) position--;
      }
      match.insertPlayer(user, position: position);
      registerText = 'apuntado';
      MyLog().log(_classString, 'addding to the match position $position');
    } else {
      if (!adminManagingUser) {
        // ask for confirmation
        const String option1 = 'Confirmar';
        const String option2 = 'Anular';
        String response = await myReturnValueDialog(
            context, '¿Seguro que quieres desapuntarte?', option1, option2);
        MyLog().log(_classString, 'confirm response = $response');

        if (response != option1) {
          showMessage(context, 'Operación anulada');
          return false;
        }
      }
      MyLog().log(_classString, 'removed from the match');
      registerText = 'desapuntado';
      match.removePlayer(user);
    }
    // message to the register
    if (adminManagingUser) {
      registerText =
          '${loggedUser.name} ha $registerText a ${user.name}' + (toAdd ? ' ($position)' : '');
    } else {
      registerText = '${user.name} se ha $registerText';
    }

    // add to FireBase
    try {
      await context
          .read<Director>()
          .firebaseHelper
          .uploadMatch(match: match, updateCore: false, updatePlayers: true);
      context.read<Director>().firebaseHelper.uploadRegister(
              register: RegisterModel(
            date: match.date,
            message: registerText,
          ));
      TelegramHelper.send('Mensaje automático: $registerText');
    } catch (e) {
      message = 'ERROR en la actualización de los datos. \n\n $e';
      MyLog().log(_classString, 'ERROR en la actualización de los datos',
          exception: e, debugType: DebugType.error);
      return false;
    }
    if (loggedUser == user || adminManagingUser) {
      // update state
      setState(() {
        isSelectedUserInTheMatch = toAdd;
        if (loggedUser == user) loggedUserInTheMatch = toAdd;
      });
    }
    showMessage(context, message);

    return true;
  }
}

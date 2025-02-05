import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
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
  const PlayersPanel(this.date, {super.key});

  final Date date;

  @override
  PlayersPanelState createState() => PlayersPanelState();
}

class PlayersPanelState extends State<PlayersPanel> {
  late final AppState appState;

  late final MyUser loggedUser;

  late MyUser selectedUser;
  final TextEditingController userPositionController = TextEditingController();

  @override
  void initState() {
    appState = context.read<AppState>();
    MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);

    loggedUser = appState.getLoggedUser();
    selectedUser = appState.sortUsers[0];

    MyLog().log(_classString, 'initState arguments = $match');

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
        actualState(),
        const Divider(thickness: 5),
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

  Widget actualState() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);
            String returnText = '';
            if (match.isInTheMatch(loggedUser.userId)) {
              if (match.isPlaying(loggedUser.userId)) {
                returnText = 'Juegas!!!';
              } else {
                returnText = 'Apuntado\n(pendiente de completar pista)';
              }
            } else {
              returnText = 'No apuntado';
            }
            return Text(
              returnText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            );
          },
        ),
      );

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
                bool loggedUserInTheMatch = match.isInTheMatch(loggedUser.userId);

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
    List<MyUser> users = appState.sortUsers;

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
                  });
                },
                children: users
                    .map((u) => Container(
                          margin: const EdgeInsets.fromLTRB(50, 0, 20, 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25), color: Theme.of(context).colorScheme.surface),
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
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  MyMatch match = appState.getMatch(widget.date) ?? MyMatch(date: widget.date);
                  bool isSelectedUserInTheMatch = match.isInTheMatch(selectedUser.userId);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (isSelectedUserInTheMatch ? 'Dar de baja a:\n\n' : 'Apuntar a:\n\n') + selectedUser.name,
                            textAlign: TextAlign.center,
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
                  );
                },
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

          List<MyUser> usersPlaying = appState.userIdsToUsers(match.getPlayers(state: PlayingState.playing));
          List<MyUser> usersSigned = appState.userIdsToUsers(match.getPlayers(state: PlayingState.signedNotPlaying));
          List<MyUser> usersReserve = appState.userIdsToUsers(match.getPlayers(state: PlayingState.reserve));
          List<MyUser> usersFillEmptySpaces = [];
          for (int i = usersPlaying.length + usersSigned.length; i < match.getNumberOfCourts() * 4; i++) {
            usersFillEmptySpaces.add(MyUser());
          }

          String numCourtsText = 'disponible ${singularOrPlural(match.getNumberOfCourts(), 'pista')}';

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
                      ...usersPlaying
                          .map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ...usersSigned.map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}',
                          style: const TextStyle(color: Colors.red))),
                      ...usersFillEmptySpaces.map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ')),
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
                        ...usersReserve
                            .map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Future<bool> validate({
    required MyUser user,
    required bool toAdd, // add user to match
    required bool adminManagingUser,
  }) async {
    MyLog().log(_classString, 'validate');
    FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;

    MyMatch? myMatch; // match != null if added or deleted
    String registerText = ''; // text to be added to the register
    // add/remove from Firebase
    try {
      if (toAdd) {
        int listPosition = -1;
        if (adminManagingUser) {
          // get position from the controller (position = controllerText -1)
          listPosition = int.tryParse(userPositionController.text) ?? -1;
          if (listPosition > 0) listPosition--;
        }
        myMatch = await firebaseHelper.addPlayerToMatch(date: widget.date, userId: user.userId, position: listPosition);
        if (myMatch != null) {
          listPosition = myMatch.getPlayerPosition(user.userId);
          if (listPosition == -1) {
            MyLog().log(_classString, 'validate player $user not in match $myMatch', debugType: DebugType.error);
          }
          if (adminManagingUser) {
            registerText = '${loggedUser.name} ha apuntado a ${user.name} (${listPosition + 1})';
          } else {
            registerText = '${user.name} se ha apuntado  (${listPosition + 1})';
          }
        }
      } else {
        if (adminManagingUser) {
          registerText = '${loggedUser.name} ha desapuntado a ${user.name}';
        } else {
          // if not admin mode, certify loggedUser wants to signOff from the match
          bool delete = await _confirmLoggedUserOutOfMatch();
          if (!delete) {
            // abort deletion
            setState(() {
              // loggedUser is still in the match
              // refresh
            });
            if (mounted) showMessage(context, 'Operación anulada');
            return false;
          }
          registerText = '${user.name} se ha desapuntado';
        }
        myMatch = await firebaseHelper.deletePlayerFromMatch(date: widget.date, userId: user.userId);
      }
    } on FirebaseException catch (e) {
      if (mounted) myAlertDialog(context, 'Error!!! Comprueba que estás apuntado/desapuntado\n $e');
      return false;
    } catch (e) {
      if (mounted) {
        myAlertDialog(
            context,
            'Ha habido una incidencia! \n'
            'Comprobar que la operación se ha realizado correctamente\n $e');
      }
    }

    MyLog().log(_classString, 'validate firebase done: Match=$myMatch Register=$registerText',
        debugType: DebugType.warning);

    if (myMatch == null) {
      // no action has been taken
      if (toAdd) {
        if (mounted) showMessage(context, 'El jugador ya estaba en el partido');
      } else {
        if (mounted) showMessage(context, 'El jugador no estaba en el partido');
      }
      return false;
    }

    //  state updated via consumers
    // telegram and register
    try {
      MyLog().log(_classString, 'validate $user update register', debugType: DebugType.warning);
      await firebaseHelper.updateRegister(RegisterModel(
        date: widget.date,
        message: registerText,
      ));
      MyLog().log(_classString, 'validate $user send telegram', debugType: DebugType.warning);
      sendDatedMessageToTelegram(
          message: '$registerText\n'
              'APUNTADOS: ${myMatch.players.length} de ${myMatch.getNumberOfCourts() * 4}',
          matchDate: widget.date,
          fromDaysAgoToTelegram: appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
    } catch (e) {
      MyLog()
          .log(_classString, 'ERROR sending message to telegram or register', exception: e, debugType: DebugType.error);
      if (mounted) {
        myAlertDialog(
            context,
            'Ha habido una incidencia al enviar el mensaje de confirmación\n'
            'Comprueba que se ha enviado el mensaje al registro y al telegram\n'
            'Error = $e');
      }

      return false;
    }

    return true;
  }

  Future<bool> _confirmLoggedUserOutOfMatch() async {
    const String option1 = 'Confirmar';
    const String option2 = 'Anular';
    String response = await myReturnValueDialog(context, '¿Seguro que quieres darte de baja?', option1, option2);
    MyLog().log(_classString, '_confirmLoggedUserOutOfMatch sign off the match = $response');
    return response == option1;
  }
}

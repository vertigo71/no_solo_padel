import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../utilities/http_helper.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../models/register_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'PlayersPanel'.toUpperCase();

class PlayersPanel extends StatefulWidget {
  const PlayersPanel({super.key});

  @override
  PlayersPanelState createState() => PlayersPanelState();
}

class PlayersPanelState extends State<PlayersPanel> {
  late MyUser _selectedUser;
  late MyUser _loggedUser;
  final TextEditingController _userPositionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    MyLog.log(_classString, 'initState initializing variables ONLY ONCE');
    _selectedUser = context.read<AppState>().users[0];
    _loggedUser = context.read<AppState>().getLoggedUser();
  }

  @override
  void dispose() {
    _userPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building for $_loggedUser');

    return ListView(
      children: [
        actualState(),
        const Divider(thickness: 5),
        signUpForm(),
        const Divider(thickness: 5),
        listOfPlayers(),
        const SizedBox(height: 20),
        if (context.read<AppState>().isLoggedUserAdmin) const Divider(thickness: 5),
        const SizedBox(height: 20),
        if (context.read<AppState>().isLoggedUserAdmin) signUpAdminForm(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget actualState() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Builder(
          builder: (context) {
            String returnText = '';
            MyMatch initialMatch = context.read<MatchNotifier>().match;

            if (initialMatch.isInTheMatch(_loggedUser)) {
              if (initialMatch.isPlaying(_loggedUser)) {
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
            Builder(
              builder: (context) {
                bool isLoggedUserInMatch = context.read<MatchNotifier>().match.isInTheMatch(_loggedUser);

                return myCheckBox(
                  context: context,
                  value: isLoggedUserInMatch,
                  onChanged: (bool? newValue) async {
                    setState(() {
                      isLoggedUserInMatch = newValue!;
                    });
                    bool ok = await validate(
                      user: _loggedUser,
                      toAdd: isLoggedUserInMatch, // isLoggedUserInMatch? add Player : delete Player
                      adminManagingUser: false,
                    );
                    if (!ok) setState(() {}); // user was not deleted or added
                  },
                );
              },
            ),
          ],
        ),
      );

  Widget listOfPlayers() => Builder(
        builder: (context) {
          int playerNumber = 0;
          MyLog.log(_classString, 'Building listOfPlayers');
          MyMatch match = context.read<MatchNotifier>().match;

          List<MyUser> usersPlaying = match.getPlayers(state: PlayingState.playing);
          List<MyUser> usersSigned = match.getPlayers(state: PlayingState.signedNotPlaying);
          List<MyUser> usersReserve = match.getPlayers(state: PlayingState.reserve);
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
                  titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
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
                    titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
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

  /// Validates the form and updates the match in Firestore.
  ///
  /// Parameters:
  ///   - [user]: The user to add or remove from the match.
  ///   - [toAdd]: `true` to add the user, `false` to remove.
  ///   - [adminManagingUser]: `true` if an administrator is performing the action, `false` otherwise.
  ///
  /// Returns:
  ///   `true` if the operation was successful, `false` otherwise.
  Future<bool> validate({
    /// add/remove user from Match in Firestore
    required MyUser user,
    required bool toAdd, // add/remove user to match
    required bool adminManagingUser,
  }) async {
    MyLog.log(_classString, 'validate');
    FsHelpers fsHelpers = context.read<Director>().fsHelpers;
    AppState appState = context.read<AppState>();
    MatchNotifier matchNotifier = context.read<MatchNotifier>();

    MyMatch? newMatchFromFirestore;
    String registerText = ''; // text to be added to the register
    // add/remove from Firestore
    try {
      if (toAdd) {
        // add user to match
        if (matchNotifier.match.isInTheMatch(user)) {
          MyLog.log(_classString, 'validate1 adding: player $user was already in match', level: Level.SEVERE, indent: true);
          return false;
        }
        int listPosition = -1;
        if (adminManagingUser) {
          // get position from the controller (position = controllerText -1)
          listPosition = int.tryParse(_userPositionController.text) ?? -1;
          if (listPosition > 0) listPosition--;
        }

        newMatchFromFirestore = await fsHelpers.addPlayerToMatch(
            appState: appState, matchId: matchNotifier.match.id, player: user, position: listPosition);

        if (newMatchFromFirestore == null) {
          MyLog.log(_classString, 'validate2 player $user already was in match', level: Level.SEVERE, indent: true);
          if (mounted) showMessage(context, 'El jugador ya estaba en el partido');
          return false;
        } else {
          listPosition = newMatchFromFirestore.getPlayerPosition(user);
          if (listPosition == -1) {
            MyLog.log(_classString, 'validate3 player $user not in match $newMatchFromFirestore', level: Level.SEVERE, indent: true);
          }
          if (adminManagingUser) {
            registerText = '${_loggedUser.name} ha apuntado a ${user.name} (${listPosition + 1})';
          } else {
            registerText = '${user.name} se ha apuntado  (${listPosition + 1})';
          }
        }
      } else {
        // removing user
        if (!matchNotifier.match.isInTheMatch(user)) {
          MyLog.log(_classString, 'validate4 removing: player $user is not in match', level: Level.SEVERE, indent: true);
          return false;
        }
        if (adminManagingUser) {
          registerText = '${_loggedUser.name} ha desapuntado a ${user.name}';
        } else {
          // if not admin mode, certify loggedUser wants to signOff from the match
          bool delete = await _confirmLoggedUserOutOfMatch();
          if (!delete) {
            // abort deletion
            // setState(() { // will be done after the call of validate
            //   // loggedUser is still in the match
            //   // refresh
            // });
            if (mounted) showMessage(context, 'Operación anulada');
            return false;
          }
          registerText = '${user.name} se ha desapuntado';
        }

        newMatchFromFirestore =
            await fsHelpers.deletePlayerFromMatch(appState: appState, matchId: matchNotifier.match.id, user: user);
        if (newMatchFromFirestore == null) {
          MyLog.log(_classString, 'validate5 player $user not in the match ${matchNotifier.match}',
              level: Level.SEVERE, indent: true);
          if (mounted) showMessage(context, 'El jugador no estaba en el partido');
          return false;
        }
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

    MyLog.log(_classString, 'validate firebase done: Match=$newMatchFromFirestore Register=$registerText',
        level: Level.INFO, indent: true);

    if (newMatchFromFirestore == null) {
      MyLog.log(_classString, 'validate6 ERROR newMatchFromFirestore=null', level: Level.SEVERE, indent: true);
      return false;
    } else {
      //  state updated via consumers
      // telegram and register
      try {
        MyLog.log(_classString, 'validate $user update register', level: Level.INFO, indent: true);

        await fsHelpers.updateRegister(RegisterModel(
          date: matchNotifier.match.id,
          message: registerText,
        ));

        MyLog.log(_classString, 'validate $user send telegram', level: Level.INFO, indent: true);

        sendDatedMessageToTelegram(
            message: '$registerText\n'
                'APUNTADOS: ${newMatchFromFirestore.players.length} de ${newMatchFromFirestore.getNumberOfCourts() * 4}',
            matchDate: matchNotifier.match.id,
            fromDaysAgoToTelegram: appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
      } catch (e) {
        MyLog.log(_classString, 'ERROR sending message to telegram or register', exception: e, level: Level.SEVERE, indent: true);
        if (mounted) {
          myAlertDialog(
              context,
              'Ha habido una incidencia al enviar el mensaje de confirmación\n'
              'Comprueba que se ha enviado el mensaje al registro y al telegram\n'
              'Error = $e');
        }

        return false;
      }
    }

    return true;
  }

  Future<bool> _confirmLoggedUserOutOfMatch() async {
    const String option1 = 'Confirmar';
    const String option2 = 'Anular';
    String response = await myReturnValueDialog(context, '¿Seguro que quieres darte de baja?', option1, option2);
    MyLog.log(_classString, '_confirmLoggedUserOutOfMatch sign off the match = $response');
    return response == option1;
  }

  Widget signUpAdminForm() {
    List<MyUser> users = context.read<AppState>().users;

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
                    _selectedUser = users[index];
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
              child: Builder(
                builder: (context) {
                  bool isSelectedUserInTheMatch = context.read<MatchNotifier>().match.isInTheMatch(_selectedUser);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (isSelectedUserInTheMatch ? 'Dar de baja a:\n\n' : 'Apuntar a:\n\n') + _selectedUser.name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        onPressed: () => validate(
                          user: _selectedUser,
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
                            user: _selectedUser,
                            toAdd: true,
                            adminManagingUser: true,
                          ),
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                          ],
                          controller: _userPositionController,
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
}

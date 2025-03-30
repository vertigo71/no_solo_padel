import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
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
import '../../utilities/ui_helpers.dart';

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
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Form for user=$_loggedUser and match=$match');

    return ListView(
      children: [
        heading(),
        const Divider(thickness: 5),
        joinMatchToggle(),
        const Divider(thickness: 5),
        listOfPlayers(),
        const SizedBox(height: 20),
        if (context.read<AppState>().isLoggedUserAdmin) const Divider(thickness: 5),
        const SizedBox(height: 20),
        if (context.read<AppState>().isLoggedUserAdmin) roulette(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget heading() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Builder(
          builder: (context) {
            String returnText = '';
            MyMatch initialMatch = context.read<MatchNotifier>().match;

            PlayingState playingState = initialMatch.getPlayingState(_loggedUser);
            switch (playingState) {
              case PlayingState.playing:
                returnText = 'Juegas!!!';
                break;
              case PlayingState.signedNotPlaying:
                returnText = 'Apuntado\n(pendiente de completar pista)';
                break;
              case PlayingState.reserve:
                returnText = 'Apuntado\n(en reserva)';
                break;
              case PlayingState.unsigned:
                returnText = 'No apuntado';
                break;
            }

            return Text(
              returnText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            );
          },
        ),
      );

  Widget joinMatchToggle() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('¿Te apuntas?'),
            const SizedBox(width: 20),
            Builder(
              builder: (context) {
                bool isLoggedUserInMatch = context.read<MatchNotifier>().match.isInTheMatch(_loggedUser);

                return UiHelper.myCheckBox(
                  context: context,
                  value: isLoggedUserInMatch,
                  onChanged: (bool? newValue) async {
                    setState(() {
                      isLoggedUserInMatch = newValue!;
                    });
                    await _validate(
                      user: _loggedUser,
                      toAdd: isLoggedUserInMatch, // isLoggedUserInMatch? add Player : delete Player
                      adminManagingUser: false,
                    );
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
          List<MyUser> rankingSortedUsers = context.read<AppState>().getUsersSortedByRanking();
          MyLog.log(_classString, 'listOfPlayers rankingSortedUsers=$rankingSortedUsers');

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
                      ...usersPlaying.map((player) => Text(_playerText(++playerNumber, player, rankingSortedUsers))),
                      ...usersSigned.map((player) => Text(_playerText(++playerNumber, player, rankingSortedUsers),
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
                        ...usersReserve.map((player) => Text(_playerText(++playerNumber, player, rankingSortedUsers))),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  String _playerText(int playerNumber, MyUser player, List<MyUser> rankingSortedUsers) {
    return '${playerNumber.toString().padLeft(3)} - ${player.name} '
        '<${rankingSortedUsers.indexOf(player) + 1}>';
  }

  Widget roulette() {
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
                        onPressed: () => _validate(
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
                          onFieldSubmitted: (String str) async => _validate(
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

  /// Validates the form and updates the match in Firestore.
  ///
  /// Parameters:
  ///   - [user]: The user to add or remove from the match.
  ///   - [toAdd]: `true` to add the user, `false` to remove.
  ///   - [adminManagingUser]: `true` if an administrator is performing the action, `false` otherwise.
  Future<void> _validate({
    /// add/remove user from Match in Firestore
    required MyUser user,
    required bool toAdd, // add/remove user to match
    required bool adminManagingUser,
  }) async {
    MyLog.log(_classString, '_validate');

    // add or delete a player from the match
    late Map<MyMatch, String>? result;
    try {
      if (toAdd) {
        result = await _addUserToMatch(user: user, adminManagingUser: adminManagingUser);
      } else {
        result = await _removeUserFromMatch(user: user, adminManagingUser: adminManagingUser);
      }

      if (result == null) {
        // only possible for cancelling deleting a user
        if (mounted) UiHelper.showMessage(context, 'Operación anulada');
        _refresh();
        return;
      }
    } catch (e) {
      if (mounted) {
        UiHelper.myAlertDialog(
            context,
            'Ha habido una incidencia! \n'
            'Comprobar que la operación se ha realizado correctamente\n ${e.toString()}');
      }
      _refresh();
      return;
    }

    // notify to telegram and register
    try {
      _sendToRegister(result.keys.first, result.values.first);
    } catch (e) {
      MyLog.log(_classString, 'ERROR sending message to telegram or register',
          exception: e, level: Level.SEVERE, indent: true);
      if (mounted) {
        UiHelper.myAlertDialog(
            context,
            'Ha habido una incidencia al enviar el mensaje de confirmación\n'
            'Es posible que no se haya enviado el mensaje al registro y al telegram\n'
            'Error = ${e.toString()}');
      }
    }
  }

  // add user to match
  Future<Map<MyMatch, String>> _addUserToMatch({required MyUser user, required bool adminManagingUser}) async {
    MyLog.log(_classString, '_addUserToMatch');
    FbHelpers fbHelpers = context.read<Director>().fbHelpers;
    AppState appState = context.read<AppState>();
    MyMatch match = context.read<MatchNotifier>().match;

    // check if user is already in the match. If so abort
    if (match.isInTheMatch(user)) {
      MyLog.log(_classString, 'validate1 adding: player $user was already in match', level: Level.SEVERE, indent: true);
      throw Exception('El jugador ya estaba en el partido');
    }

    // if administrator, get position in which the player will be be added from the controller text
    int playerPosition = -1;
    if (adminManagingUser) {
      // get position from the controller (position = controllerText -1)
      // if there is nothing in the controller text, the player will be added at the end
      playerPosition = int.tryParse(_userPositionController.text) ?? -1;
      if (playerPosition > 0) playerPosition--;
    }

    // add player to match and upload the match to firestore database
    // newMatchFromFirestore is the match with the new player
    // null otherwise
    Map<MyMatch, int> result =
        await fbHelpers.addPlayerToMatch(appState: appState, matchId: match.id, player: user, position: playerPosition);
    MyMatch updatedMatch = result.keys.first; // Get the MyMatch object (key)
    playerPosition = result.values.first; // Get the updated player position (value)

    // text to be added to the register
    late String registerText;
    if (adminManagingUser) {
      registerText = '${_loggedUser.name} ha apuntado a ${user.name} (${playerPosition + 1})';
    } else {
      registerText = '${user.name} se ha apuntado  (${playerPosition + 1})';
    }

    return {updatedMatch: registerText};
  }

  // delete user from match
  // return null if no action was done
  Future<Map<MyMatch, String>?> _removeUserFromMatch({required MyUser user, required bool adminManagingUser}) async {
    // removing user
    MyLog.log(_classString, '_removeUserFromMatch');
    FbHelpers fbHelpers = context.read<Director>().fbHelpers;
    AppState appState = context.read<AppState>();
    MyMatch match = context.read<MatchNotifier>().match;

    // check if user is not in the match. If so abort
    if (!match.isInTheMatch(user)) {
      MyLog.log(_classString, 'removing: player $user is not in match', level: Level.SEVERE, indent: true);
      throw Exception('El jugador no estaba en el partido');
    }

    // confirm that user wants to remove himself from the match
    if (!adminManagingUser) {
      // if not admin mode, certify loggedUser wants to signOff from the match
      bool delete = await _confirmQuitMatch();
      if (!delete) {
        // abort deletion
        return null; // abort deletion
      }
    }

    // delete player from the match and upload the match to firestore database
    // newMatchFromFirestore is the match with the new player
    // null otherwise
    MyMatch updatedMatch = await fbHelpers.deletePlayerFromMatch(appState: appState, matchId: match.id, user: user);

    // text to be added to the register
    late String registerText;
    if (adminManagingUser) {
      registerText = '${_loggedUser.name} ha desapuntado a ${user.name}';
    } else {
      registerText = '${user.name} se ha desapuntado';
    }

    return {updatedMatch: registerText};
  }

  // send to register and telegram
  Future<void> _sendToRegister(MyMatch updatedMatch, String registerText) async {
    FbHelpers fbHelpers = context.read<Director>().fbHelpers;
    AppState appState = context.read<AppState>();
    MyMatch match = context.read<MatchNotifier>().match;

    MyLog.log(_classString, '_sendToRegister send to register');
    await fbHelpers.updateRegister(RegisterModel(date: match.id, message: registerText));

    MyLog.log(_classString, '_sendToRegister send to telegram');
    sendDatedMessageToTelegram(
        message: '$registerText\n'
            'APUNTADOS: ${match.playersReference.length} de ${match.getNumberOfCourts() * 4}',
        matchDate: match.id,
        fromDaysAgoToTelegram: appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
  }

  Future<bool> _confirmQuitMatch() async {
    const String option1 = 'Confirmar';
    const String option2 = 'Anular';
    String response = await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres darte de baja?', option1, option2);
    MyLog.log(_classString, '_confirmLoggedUserOutOfMatch sign off the match = $response');
    return response == option1;
  }

  void _refresh() => setState(() {});
}

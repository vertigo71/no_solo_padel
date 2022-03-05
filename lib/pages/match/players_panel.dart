import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
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
  // checkBox
  bool isLoggedUserInTheMatch = false;

  @override
  void initState() {
    MyMatch match = context.read<AppState>().getMatch(widget.date) ?? MyMatch(date: widget.date);

    MyUser loggedUser = context.read<AppState>().getLoggedUser();
    PlayingState state = match.getPlayingState(loggedUser);
    isLoggedUserInTheMatch = state != PlayingState.unsigned;

    MyLog().log(_classString, 'initState arguments = $match');
    MyLog().log(_classString, 'loggedUser in match= $isLoggedUserInTheMatch');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: isLoggedUserInTheMatch,
                onChanged: (bool? value) {
                  setState(() {
                    isLoggedUserInTheMatch = value!;
                  });
                },
              ),
              const SizedBox(width: 10),
              const Text('Me apunto!!!'),
              const Spacer(flex: 1),
              ElevatedButton(
                child: const Text('Aceptar'),
                onPressed: () async {
                  // Add/delete player from the match
                  MyMatch? match = context.read<AppState>().getMatch(widget.date);
                  MyUser loggedUser = context.read<AppState>().getLoggedUser();
                  String message = 'Los datos han sido actualizados';
                  if (match == null) {
                    message = 'ERROR: Partido no encontrado. No se ha podido apuntar al jugador';
                  } else {
                    String registerText = '';

                    if (isLoggedUserInTheMatch) {
                      match.addPlayer(loggedUser);
                      registerText = 'apuntado';
                    } else {
                      registerText = 'desapuntado';
                      match.removePlayer(loggedUser);
                    }
                    // message
                    registerText = '${loggedUser.name} se ha ' + registerText;

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
                    } catch (e) {
                      message = 'ERROR en la actualización de los datos. \n\n $e';
                      MyLog().log(_classString, 'ERROR en la actualización de los datos',
                          exception: e, debugType: DebugType.error);
                    }
                  }
                  showMessage(context, message);
                },
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar')),
            ],
          ),
        ),
        const Divider(
          thickness: 5,
        ),
        Consumer<AppState>(
          builder: (context, state, _) {
            int playerNumber = 0;
            MyMatch? match = context.read<AppState>().getMatch(widget.date);
            if (match == null) {
              return Text('ERROR!: partido no encontrado para la fecha ${widget.date} \n'
                  'No se pueden mostrar los jugadores');
            } else {
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
              return Expanded(
                child: ListView(
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
                      margin: const EdgeInsets.all(10),
                      color: Theme.of(context).colorScheme.background,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...usersPlaying.map((player) =>
                                Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                            ...usersSigned.map((player) => Text(
                                '${(++playerNumber).toString().padLeft(3)} - ${player.name}',
                                style: const TextStyle(color: Colors.red))),
                            ...usersFillEmptySpaces.map(
                                (player) => Text('${(++playerNumber).toString().padLeft(3)} - ')),
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
                        margin: const EdgeInsets.all(10),
                        color: Theme.of(context).colorScheme.background,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...usersReserve.map((player) =>
                                  Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
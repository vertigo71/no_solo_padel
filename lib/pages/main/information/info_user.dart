import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../interface/if_director.dart';
import '../../../models/md_date.dart';
import '../../../models/md_match.dart';
import '../../../models/md_user.dart';
import '../../../models/md_debug.dart';

final String _classString = 'InfoUserPanel'.toUpperCase();

class InfoUserPanel extends StatefulWidget {
  final List<String> args;

  const InfoUserPanel({super.key, required this.args});

  @override
  State<InfoUserPanel> createState() => InfoUserPanelState();
}

class InfoUserPanelState extends State<InfoUserPanel> {
  late final MyUser? _user;
  late final int _index;
  late final Director _director;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);
    _index = int.parse(widget.args[0]);
    _user = context.read<AppState>().getUserById(widget.args[1]);
    _director = context.read<Director>();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return Scaffold(body: Center(child: Text('Usuario no encontrado')));
    ImageProvider? imageProvider = _user!.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(_user!.name)),
      body: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                backgroundImage: imageProvider,
                child: imageProvider == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
              ),
              Text(
                'Ranking: ${_user!.rankingPos}\n\n'
                'Posición: $_index',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          FutureBuilder(
              future: _numberOfMatches(),
              builder: (context, snapshot) => Text(
                    'Partidos: ${snapshot.hasData ? snapshot.data : 'Cargando...'}',
                    style: TextStyle(fontSize: 14),
                  )),
        ],
      ),
    );
  }

  Future<int> _numberOfMatches() async {
    if (_user == null) return 0;
    int numberOfMatches = 0;
    for (var matchId in _user!.matchIds) {

      if ( matchId.compareTo(Date.now().toYyyyMmDd() ) <= 0 ){
        MyMatch? match = await FbHelpers().getMatch(matchId, _director.appState);
        if (match != null && match.isOpen && match.isPlaying(_user!)) numberOfMatches++;
      }
    }
    return numberOfMatches;
  }
}

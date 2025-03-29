import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';

final String _classString = 'AddResultPage'.toUpperCase();
const int numPlayers = 4;
const int numSets = 3;
const int maxGamesPerSet = 15;

class AddResultPage extends StatefulWidget {
  const AddResultPage({super.key, required this.matchJson});

  // argument matchJson vs matchId
  // matchJson: initialValue for FormBuilder will hold the correct initial values
  //   If another user changes any field, the form will not update
  //   A new matchJson will be received. But Form fields won't be updated.
  //   Good for configuration panel
  // matchId: _formKey.currentState?.fields[commentId]?.didChange(match.comment); should be implemented
  //   If any user changes any field, the form will update. Or if any rebuild is made, changes would be lost.
  final Map<String, dynamic> matchJson;

  @override
  State<AddResultPage> createState() => _AddResultPageState();
}

class _AddResultPageState extends State<AddResultPage> {
  late final MyMatch _match;
  bool _initStateError = false;
  List<MyUser?> selectedPlayer = List.filled(numPlayers, null);
  List<List<int>> results = List.generate(numSets, (_) => [0, 0]);

  @override
  void initState() {
    super.initState();
    try {
      _match = MyMatch.fromJson(widget.matchJson, context.read<AppState>());
      MyLog.log(_classString, 'match = $_match', indent: true);
    } catch (e) {
      _initStateError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    if (_initStateError) return Center(child: Text('No se ha podido acceder al partido'));

    return Scaffold(
      appBar: AppBar(
        title: Text(_match.id.longFormat()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8.0,
          children: [
            // add Team A
            _addPlayer(0),
            _addPlayer(1),
            // add score
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12.0,
                children: [_setResult(0), _setResult(1), _setResult(2)],
              ),
            ),
            // add Team B
            _addPlayer(2),
            _addPlayer(3),
            Divider(
              height: 8.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement save functionality
                    print('Save button pressed');
                  },
                  child: Text('Guardar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addPlayer(int numValue) {
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: DropdownMenu<MyUser>(
        width: double.infinity,
        initialSelection: selectedPlayer[numValue],
        onSelected: (MyUser? value) {
          setState(() {
            selectedPlayer[numValue] = value;
          });
        },
        dropdownMenuEntries:
            _match.getPlayers(state: PlayingState.playing).map<DropdownMenuEntry<MyUser>>((MyUser user) {
          return DropdownMenuEntry<MyUser>(
            value: user,
            label: user.name,
            leadingIcon: CircleAvatar(
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            ),
          );
        }).toList(),
        leadingIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            backgroundImage:
                selectedPlayer[numValue]?.avatarUrl != null ? NetworkImage(selectedPlayer[numValue]!.avatarUrl!) : null,
          ),
        ),
      ),
    );
  }

  Widget _setResult(int set) {
    return Column(
      spacing: 8.0,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _setPartialResult(set, 0),
        Text('Set ${set + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
        _setPartialResult(set, 1),
      ],
    );
  }

  Widget _setPartialResult(int set, int part) {
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(8.0),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: DropdownMenu<int>(
        width: 80.0,
        initialSelection: results[set][part],
        onSelected: (int? value) {
          if (value != null) {
            setState(() {
              results[set][part] = value;
            });
          }
        },
        dropdownMenuEntries: List.generate(maxGamesPerSet, (result) {
          return DropdownMenuEntry<int>(
            value: result,
            label: result.toString(), // Convert int to String
            style: ButtonStyle(
              padding:
                  WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

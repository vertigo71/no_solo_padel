import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/db_firebase_helpers.dart';
import '../../interface/if_director.dart';
import '../../models/md_match.dart';
import '../../models/md_result.dart';
import '../../models/md_user.dart';

final String _classString = 'CheckPanel'.toUpperCase();

class CheckPanel extends StatefulWidget {
  const CheckPanel({super.key});

  @override
  CheckPanelState createState() => CheckPanelState();
}

class CheckPanelState extends State<CheckPanel> {
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();
  late final Director _director;

  @override
  void initState() {
    super.initState();
    _director = context.read<Director>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _migrateResults,
              child: const Text('Migrate results to new format'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _output.clear()),
              child: const Text('Clear all'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceDim,
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _output.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _output[index],
                      style: const TextStyle(fontSize: 14),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to rebuild matches in users
  Future<void> _migrateResults() async {
    _addOutput("Migrate results to new collection...");
    _addOutput("Create user match results to new collection...");
    try {
      List<MyMatch> matches = await FbHelpers().getAllMatches(appState: _director.appState);
      _addOutput("Found ${matches.length} matches.");

      // erase all past userMatchResults
      await FbHelpers().deleteUserMatchResultTillDateBatch();
      _addOutput("All user match results deleted.");

      // erase all past results
      await FbHelpers().deleteGameResultsTillDateBatch();
      _addOutput("All results deleted.");

      for (MyMatch match in matches) {
        _addOutput("------- Match: ${match.id}");

        // add new user-Match to new collection for every player
        for (MyUser user in match.players) {
          await FbHelpers().addUserMatchResult(userId: user.id, matchId: match.id.toYyyyMmDd());
          _addOutput("UserMatch added: ${user.id}");
        }

        // get results
        List<GameResult> results =
            await FbHelpers().getResultsOfAMatchOldFormat(matchId: match.id.toYyyyMmDd(), appState: _director.appState);
        _addOutput("Found ${results.length} results.");

        for (GameResult result in results) {
          _addOutput("Result: ${result.id}");

          // add result
          await FbHelpers().createGameResult(result: result);
          _addOutput("Game Result created and also added all UserMatchResults.");
        }
      }

      _addOutput("\nMigrated completed.");
    } catch (e) {
      _addOutput("\nError migrating results: $e");
    }
  }

  // Helper function to add output and scroll to the bottom
  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });

    // Use a Future to ensure the ListView has been updated before scrolling.
    Future.delayed(Duration.zero, () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

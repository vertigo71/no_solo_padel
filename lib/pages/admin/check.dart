import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/md_debug.dart';

final String _classString = 'CheckPanel'.toUpperCase();

class CheckPanel extends StatefulWidget {
  const CheckPanel({super.key});

  @override
  CheckPanelState createState() => CheckPanelState();
}

class CheckPanelState extends State<CheckPanel> {
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();
  // late final Director _director;

  @override
  void initState() {
    super.initState();
    // _director = context.read<Director>();
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
    MyLog.log(_classString, 'migrateResults', level: Level.FINE);
    _addOutput("Migrate results to new collection...");
    _addOutput("Already migrated!!!!");

    // TODO: erase all subcollections

    // _addOutput("Create user match results to new collection...");
    // try {
    //   List<MyMatch> matches = await FbHelpers().getAllMatches(appState: _director.appState);
    //   _addOutput("Found ${matches.length} matches.");
    //
    //   // erase all past results
    //   await FbHelpers().deleteSetResultsTillDateBatch();
    //   _addOutput("All results deleted.");
    //
    //   for (MyMatch match in matches) {
    //     _addOutput("------- Match: ${match.id}");
    //
    //     // add new user-Match to new collection for every player
    //     for (MyUser user in match.players) {
    //       _addOutput("UserMatch added: ${user.id}");
    //     }
    //
    //     // get results
    //     List<SetResult> results =
    //         await FbHelpers().getResultsOfAMatchOldFormat(matchId: match.id.toYyyyMmDd(), appState: _director.appState);
    //     _addOutput("Found ${results.length} results.");
    //
    //     for (SetResult result in results) {
    //       _addOutput("Result: ${result.id}");
    //
    //       // add result
    //       await FbHelpers().createSetResult(result: result);
    //     }
    //   }
    //
    //   _addOutput("\nMigrated completed.");
    // } catch (e) {
    //   _addOutput("\nError migrating results: $e");
    // }
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

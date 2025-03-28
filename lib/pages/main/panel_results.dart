import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/result_model.dart';
import '../../models/match_model.dart';
import '../../utilities/date.dart';

final String _classString = 'ResultsPanel'.toUpperCase();

class ResultsPanel extends StatelessWidget {
  const ResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return Consumer<AppState>(
      builder: (context, appState, _) {
        FbHelpers fbHelpers = context.read<Director>().fbHelpers;

        Date maxDate = Date.now();
        MyLog.log(_classString, 'StreamBuilder  to:$maxDate', indent: true);

        return StreamBuilder<List<MyMatch>>(
          stream: fbHelpers.getMatchesStream(appState: appState, maxDate: maxDate, onlyOpenMatches: true),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final matches = snapshot.data!;
              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return _buildMatchItem(match, context);
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error al obtener los partidos: \nError: ${snapshot.error}'));
            } else {
              return CircularProgressIndicator(); // Loading indicator
            }
          },
        );
      },
    );
  }

  Widget _buildMatchItem(MyMatch match, BuildContext context) {
    AppState appState = context.read<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, match.id.longFormat(), () {
          // Implement logic to add a new result for this match
          _addNewResult(context, match);
        }),
        // Display subcollection results
        FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance.collection('matches').doc(match.id.toYyyyMMdd()).collection('results').get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final results = snapshot.data!.docs
                  .map((doc) => GameResult.fromJson(doc.data() as Map<String, dynamic>, appState))
                  .toList(); // Assuming GameResult.fromJson
              return Column(
                children: results.map((result) => _buildResultCard(result)).toList(),
              );
            } else if (snapshot.hasError) {
              return Text('Error loading results: ${snapshot.error}');
            } else {
              return CircularProgressIndicator(); // Loading indicator
            }
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String headerText, VoidCallback onAddResult) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            headerText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: onAddResult,
          ),
        ],
      ),
    );
  }

  // Function to handle adding a new result
  void _addNewResult(BuildContext context, MyMatch match) {
    // Implement your logic to add a new result for the match
    // This could involve showing a dialog, navigating to a new screen, etc.
    // For example:
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Result'),
          content: Text('Implement your form here.'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                // Save the new result to Firestore
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultCard(GameResult result) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity, // Take up the full width of the Column
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GameResult: ${result.id}'),
              // ... other result properties
            ],
          ),
        ),
      ),
    );
  }
}

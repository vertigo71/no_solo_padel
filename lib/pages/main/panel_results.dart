import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/result_model.dart';
import '../../models/match_model.dart';
import '../../routes/routes.dart';
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
          stream:
              fbHelpers.getMatchesStream(appState: appState, maxDate: maxDate, onlyOpenMatches: true, descending: true),
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
        _buildHeader(context, match.id.longFormat(), () => _addNewResult(context, match)),
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

  Widget _buildHeader(BuildContext context, String headerText, VoidCallback onAddResult) => Card(
        elevation: 6,
        margin: const EdgeInsets.all(10),
        child: ListTile(
          tileColor: Theme.of(context).appBarTheme.backgroundColor,
          titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
          title: Text(headerText),
          leading: GestureDetector(
            onTap: onAddResult,
            child: Tooltip(
              message: 'Agregar nuevo resultado',
              child: CircleAvatar(
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

  // Function to handle adding a new result
  void _addNewResult(BuildContext context, MyMatch match) {
    context.pushNamed(AppRoutes.addResult, extra: match.toJson());
  }

  Widget _buildResultCard(GameResult result) {
    return Card(
      margin: const EdgeInsets.fromLTRB(30.0, 8.0, 8.0, 8.0),
      child: SizedBox(
        width: double.infinity, // Take up the full width of the Column
        child: Padding(
          padding: EdgeInsets.all(8.0),
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

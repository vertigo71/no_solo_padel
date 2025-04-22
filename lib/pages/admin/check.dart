import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../interface/if_director.dart';
import '../../models/md_user.dart';
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
      appBar: AppBar(
        title: const Text('Check Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkMatchesInUsers,
              child: const Text('Check Matches in Users'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _rebuildMatchesInUsers,
              child: const Text('Rebuild Matches in Users'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
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

  // Function to check matches in users
  Future<void> _checkMatchesInUsers() async {
    _addOutput("Checking Matches in Users...");
    try {
      Map<MyUser, List<String>> rightMatchesPerUser = <MyUser, List<String>>{};
      await _director.checkUserMatches(rightMatchesPerUser);
      MyLog.log(_classString, 'number of users = ${rightMatchesPerUser.length}');
      for (var user in rightMatchesPerUser.keys) {
        _addOutput("-----------------------------------------------");
        _addOutput("User: ${user.name}");
        _addOutput("   Wrong Matches: ${user.matchIds}");
        _addOutput("   Correct Matches: ${rightMatchesPerUser[user]}");
      }
      _addOutput("Check Matches in Users completed.");
    } catch (e) {
      _addOutput("\nError checking matches in users: $e");
    }
  }

// Function to check matches in users
  Future<void> _rebuildMatchesInUsers() async {
    _addOutput("Checking Matches in Users...");
    try {
      Map<MyUser, List<String>> rightMatchesPerUser = <MyUser, List<String>>{};
      await _director.checkUserMatches(rightMatchesPerUser);

      _addOutput("Building Matches in Users...");

      await _director.rebuildUserMatches(rightMatchesPerUser);
      _addOutput("Build Matches in Users completed.");
    } catch (e) {
      _addOutput("\nError checking matches in users: $e");
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

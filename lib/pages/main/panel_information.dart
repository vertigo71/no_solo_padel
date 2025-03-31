import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';

final String _classString = 'InformationPanel'.toUpperCase();

class InformationPanel extends StatelessWidget {
  const InformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return Scaffold(
      body: ListView(
        children: [
          ...ListTile.divideTiles(
              context: context,
              tiles: context.read<AppState>().users.map(((user) {
                final String sosInfo = user.emergencyInfo.isNotEmpty ? 'SOS: ${user.emergencyInfo}\n' : '';

                ImageProvider<Object>? imageProvider;
                try {
                  if (user.avatarUrl != null) {
                    imageProvider = NetworkImage(user.avatarUrl!);
                  }
                } catch (e) {
                  MyLog.log(_classString, 'Error building image for user $user', level: Level.WARNING, indent: true);
                  imageProvider = null;
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: imageProvider,
                    child:
                        imageProvider == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
                  ),
                  isThreeLine: true,
                  title: Text(user.name),
                  subtitle: Text('${sosInfo}Usuario: ${user.email.split('@')[0]}\n'
                      'Ranking: ${user.rankingPos}'),
                  trailing: Text(user.userType.displayName),
                );
              }))),
        ],
      ),
    );
  }
}

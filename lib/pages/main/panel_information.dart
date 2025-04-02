import 'package:flutter/material.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter/foundation.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../misc/panel_avatar_selector.dart';

final String _classString = 'InformationPanel'.toUpperCase();

class InformationPanel extends StatelessWidget {
  const InformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Scaffold(
      body: ListView(
        children: [
          ...ListTile.divideTiles(
              context: context,
              tiles: context.read<AppState>().users.map(((user) {
                return UiHelper.userInfoTile(user, () => _modifyUser(context, user));
              }))),
        ],
      ),
    );
  }

  Future _modifyUser(BuildContext context, MyUser user) {
    MyLog.log(_classString, '_modifyUser: $user', indent: true);

    Uint8List? selectedImageData; // Store the selected image data

    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to manage local state
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Overlapping Panel: user=${user.name}'),
                  AvatarSelector(
                    user: user,
                    onImageSelected: (Uint8List? imageData) {
                      setState(() {
                        selectedImageData = imageData;
                      });
                      // You can perform further actions with the image data here
                      MyLog.log(_classString, "Image Selected in modal selected image=${selectedImageData!=null}",
                          indent: true);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Access selectedImageData here to use it
                      MyLog.log(_classString, "Closing modal selected image=${selectedImageData!=null}", indent: true);
                      Navigator.pop(context);
                    },
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

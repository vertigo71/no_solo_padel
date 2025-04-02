import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/user_model.dart';
import '../../models/debug.dart';
import '../../utilities/ui_helpers.dart';

class AvatarSelector extends StatefulWidget {
  const AvatarSelector({super.key, required this.user, this.onImageSelected});

  final MyUser user;
  final Function(Uint8List?)? onImageSelected; // Callback function

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  Uint8List? _compressedImageData;
  late MyUser user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    try {
      if (_compressedImageData != null) {
        imageProvider = MemoryImage(_compressedImageData!);
      } else if (user.avatarUrl != null) {
        imageProvider = NetworkImage(user.avatarUrl!);
      }
    } catch (e) {
      MyLog.log('_AvatarSelectorState', 'Error loading user avatar', level: Level.SEVERE, indent: true);
      UiHelper.showMessage(context, 'Error obteniendo la imagen de perfil');
      imageProvider = null;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black87,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                backgroundImage: imageProvider,
                child:
                    imageProvider == null ? const Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
              ),
              const SizedBox(width: 40),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Seleccionar Avatar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _shrinkAvatar(pickedFile, maxHeight: 256, maxWidth: 256).then((Uint8List? compressedBytes) {
        if (compressedBytes != null) {
          setState(() {
            _compressedImageData = compressedBytes;
          });
          if (widget.onImageSelected != null) {
            widget.onImageSelected!(compressedBytes); // Call the callback
          }
        } else {
          MyLog.log('_AvatarSelectorState', 'Error loading avatar', level: Level.SEVERE, indent: true);
          if (mounted) UiHelper.showMessage(context, 'Error al cargar la imagen');
        }
      }).catchError((e) {
        MyLog.log('_AvatarSelectorState', 'Error shrinking avatar: ${e.toString()}', level: Level.SEVERE, indent: true);
        if (mounted) UiHelper.showMessage(context, 'Error al comprimir la imagen\n${e.toString()}');
      });
    }
  }

  Future<Uint8List?> _shrinkAvatar(XFile imageFile, {required int maxWidth, required int maxHeight}) async {
    MyLog.log('_AvatarSelectorState', 'Shrinking avatar: ${imageFile.path}');

    Uint8List imageBytes = await imageFile.readAsBytes();

    Uint8List compressedImage = await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: 512,
      minWidth: 512,
      quality: 95,
    );

    MyLog.log('_AvatarSelectorState', 'Avatar original (kB): ${imageBytes.length / 1000}');
    MyLog.log('_AvatarSelectorState', 'Avatar compressed (kB): ${compressedImage.length / 1000}');

    return compressedImage;
  }
}

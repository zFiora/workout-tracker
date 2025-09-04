 import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    this.size = 96,
    this.initialUrl,
    this.placeholderAsset,
    this.onChanged,
  });

  final double size;
  final String? initialUrl;
  final String? placeholderAsset;
  final ValueChanged<File?>? onChanged;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _file;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 85);
    if (x == null) return;
    setState(() => _file = File(x.path));
    widget.onChanged?.call(_file);
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = size / 2;

    ImageProvider? image;
    if (_file != null) {
      image = FileImage(_file!);
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      image = NetworkImage(widget.initialUrl!);
    } else if (widget.placeholderAsset != null) {
      image = AssetImage(widget.placeholderAsset!);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _showSourceSheet,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: const Color(0xFFE9EEF6),

              backgroundImage: widget.placeholderAsset != null
                  ? AssetImage(widget.placeholderAsset!)
                  : null,

              foregroundImage: image,

              child: (image == null && widget.placeholderAsset == null)
                  ? Icon(
                      Icons.person_outline,
                      size: size * 0.5,
                      color: Colors.black38,
                    )
                  : null,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: _showSourceSheet,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

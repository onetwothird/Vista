import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/storage/cloudinary_service.dart';
import 'package:seelai_app/themes/palette.dart';

/// Your photo with a camera badge. Tap it to take a new photo, pick one from
/// the gallery, or remove it. The new photo is uploaded and saved to your
/// profile, then [onChanged] gets its address ('' when removed).
class ProfilePhotoEditor extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final ValueChanged<String> onChanged;
  final double size;

  const ProfilePhotoEditor({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.onChanged,
    this.size = 112,
  });

  @override
  State<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<ProfilePhotoEditor> {
  bool _busy = false;
  File? _preview;

  String get _uid => widget.userData['uid']?.toString() ?? '';

  /// Database role key: MSWD staff are stored under 'admin'.
  String get _role {
    final r = widget.userData['role']?.toString() ?? 'partially_sighted';
    return (r == 'mswd') ? 'admin' : r;
  }

  Future<void> _openSheet() async {
    final hasPhoto =
        (widget.userData['profileImageUrl']?.toString() ?? '').isNotEmpty;
    final dark = widget.isDarkMode;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Palette.card(dark),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  'Profile photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.text(dark),
                  ),
                ),
              ),
              _option(
                context,
                'camera',
                Icons.photo_camera_outlined,
                'Take a photo',
                dark,
              ),
              _option(
                context,
                'gallery',
                Icons.photo_library_outlined,
                'Choose from gallery',
                dark,
              ),
              if (hasPhoto)
                _option(
                  context,
                  'remove',
                  Icons.delete_outline_rounded,
                  'Remove photo',
                  dark,
                  danger: true,
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'remove') {
      await _save('');
    } else {
      await _pick(
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
    }
  }

  Widget _option(
    BuildContext context,
    String value,
    IconData icon,
    String label,
    bool dark, {
    bool danger = false,
  }) {
    final color = danger ? Palette.danger(dark) : Palette.text(dark);
    return ListTile(
      minTileHeight: 56,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null || !mounted) return;
      setState(() {
        _preview = File(file.path);
        _busy = true;
      });
      final url = await cloudinaryService.uploadProfileImage(
        File(file.path),
        _uid,
        _role == 'admin' ? 'mswd' : _role,
      );
      if (url == null) throw Exception('upload failed');
      await _save(url);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = null;
      });
      _toast(
        "Couldn't update your photo. Check your connection and try again.",
      );
    }
  }

  Future<void> _save(String url) async {
    setState(() => _busy = true);
    try {
      await databaseService.updateUserProfile(
        userId: _uid,
        role: _role,
        profileImageUrl: url,
      );
      widget.userData['profileImageUrl'] = url;
      widget.onChanged(url);
      _toast(url.isEmpty ? 'Photo removed' : 'Photo updated');
    } catch (_) {
      _toast("Couldn't save your photo. Try again.");
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _preview = null;
        });
      }
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final size = widget.size;
    final url = widget.userData['profileImageUrl']?.toString() ?? '';
    final name = widget.userData['name']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget photo;
    if (_preview != null) {
      photo = Image.file(_preview!, fit: BoxFit.cover);
    } else if (url.isNotEmpty) {
      photo = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(initial, dark),
      );
    } else {
      photo = _fallback(initial, dark);
    }

    return Semantics(
      button: true,
      label: 'Profile photo. Tap to change it.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _busy ? null : _openSheet,
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.card(dark),
                  border: Border.all(color: Palette.border(dark)),
                ),
              ),
              ClipOval(
                child: SizedBox(width: size, height: size, child: photo),
              ),
              if (_busy)
                ClipOval(
                  child: Container(
                    width: size,
                    height: size,
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.brand(dark),
                    border: Border.all(color: Palette.card(dark), width: 3),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 19,
                    color: dark ? Palette.violetDeep : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(String initial, bool dark) => Container(
    color: Palette.brand(dark),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        fontSize: size * 0.4,
        fontWeight: FontWeight.w700,
        color: dark ? Palette.violetDeep : Colors.white,
      ),
    ),
  );

  double get size => widget.size;
}

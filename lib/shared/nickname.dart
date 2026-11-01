import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/palette.dart';

/// The short name Vista greets you by on the home screen.
abstract final class Nickname {
  static const maxLength = 8;

  /// The saved nickname, or null when none is set yet.
  static String? of(Map<String, dynamic>? userData) {
    final value = (userData?['nickname'] as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// A starting suggestion: the first name, cut to fit.
  static String suggestion(Map<String, dynamic>? userData) {
    final name = (userData?['name'] as String? ?? '').trim();
    final first = name.split(RegExp(r'\s+')).first;
    return first.length > maxLength ? first.substring(0, maxLength) : first;
  }

  /// `user_info/<role>/<uid>`, from the role stored on the record.
  static String? _path(Map<String, dynamic> userData) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ??
        userData['uid'] as String? ??
        userData['userId'] as String?;
    if (uid == null || uid.isEmpty) return null;
    final node = switch (userData['role']) {
      'admin' || 'mswd' => 'mswd',
      'caretaker' => 'caretaker',
      _ => 'partially_sighted',
    };
    return 'user_info/$node/$uid';
  }

  /// Saves [nickname] to the user's own record and to [userData], so screens
  /// built from that map pick it up straight away.
  static Future<void> save(
    Map<String, dynamic> userData,
    String nickname,
  ) async {
    final value = nickname.trim();
    userData['nickname'] = value;
    final path = _path(userData);
    if (path == null) return;
    await FirebaseDatabase.instance.ref('$path/nickname').set(value);
  }

  /// Bottom sheet for changing the nickname. Returns the new one, or null.
  static Future<String?> edit(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: NicknameForm(
          initial: of(userData) ?? suggestion(userData),
          submitLabel: 'Save',
          onSubmit: (value) => Navigator.pop(sheet, value),
        ),
      ),
    );
    if (result == null || result.trim().isEmpty) return null;
    try {
      await save(userData, result);
    } catch (_) {
      // Kept locally even if the network write fails; it retries next time.
    }
    return result.trim();
  }
}

/// "What should Vista call you?" with a field that stops at 8 characters.
class NicknameForm extends StatefulWidget {
  const NicknameForm({
    super.key,
    required this.initial,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.onSkip,
  });

  final String initial;
  final ValueChanged<String> onSubmit;
  final String submitLabel;
  final VoidCallback? onSkip;

  @override
  State<NicknameForm> createState() => _NicknameFormState();
}

class _NicknameFormState extends State<NicknameForm> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    HapticFeedback.selectionClick();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What should Vista call you?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Palette.text(dark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A short name for your home screen, up to '
          '${Nickname.maxLength} letters.',
          style: TextStyle(fontSize: 16, color: Palette.muted(dark)),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => TextField(
            controller: _controller,
            autofocus: true,
            maxLength: Nickname.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Palette.text(dark),
            ),
            decoration: const InputDecoration(
              hintText: 'Nickname',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => ElevatedButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.submitLabel),
          ),
        ),
        if (widget.onSkip != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: widget.onSkip,
            child: const Text('Skip for now'),
          ),
        ],
      ],
    );
  }
}

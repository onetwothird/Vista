// File: lib/roles/caretaker/home/sections/patients_screen/message_patients.dart

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/shared/accessibility.dart';

Future<void> messagePatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460';
  final messenger = ScaffoldMessenger.of(context);
  final FlutterTts flutterTts = FlutterTts();

  try {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(a11y.speechRate);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    final bool canLaunch = await canLaunchUrl(smsUri);

    if (!canLaunch) throw 'Could not launch SMS app';

    await launchUrl(smsUri);

    final msg = patientName != null
        ? 'Opening SMS for $patientName...'
        : 'Opening SMS app...';

    await flutterTts.speak(msg);

    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Palette.success),
    );
  } catch (e) {
    await flutterTts.speak('Failed to open SMS app.');
    messenger.showSnackBar(
      SnackBar(content: Text('Failed: $e'), backgroundColor: Palette.alert),
    );
  }
}

Future<void> messagePatientWithBody(
  BuildContext context,
  String message,
) async {
  const String phoneNumber = '09385100460';
  final String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
  final Uri uri = Uri.parse(smsUrl);
  final messenger = ScaffoldMessenger.of(context);
  final FlutterTts flutterTts = FlutterTts();

  try {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(a11y.speechRate);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    final bool canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) throw 'Could not launch SMS app';

    await launchUrl(uri);
    await flutterTts.speak('Opening SMS app');
  } catch (e) {
    await flutterTts.speak('Failed to send SMS.');
    messenger.showSnackBar(
      SnackBar(content: Text('Failed: $e'), backgroundColor: Palette.alert),
    );
  }
}

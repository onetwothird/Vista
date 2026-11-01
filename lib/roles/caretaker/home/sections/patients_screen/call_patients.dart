// File: lib/roles/caretaker/home/sections/patients_screen/call_patients.dart

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/shared/accessibility.dart';

Future<void> callPatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460';
  final messenger = ScaffoldMessenger.of(context);
  final FlutterTts flutterTts = FlutterTts();

  try {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(a11y.speechRate);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    final bool canLaunch = await canLaunchUrl(phoneUri);

    if (!canLaunch) throw 'Could not launch phone dialer';

    await launchUrl(phoneUri);

    final msg = patientName != null
        ? 'Calling $patientName...'
        : 'Initiating phone call...';
    await flutterTts.speak(msg);

    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Palette.success),
    );
  } catch (e) {
    await flutterTts.speak('Failed to make call.');
    messenger.showSnackBar(
      SnackBar(content: Text('Failed: $e'), backgroundColor: Palette.alert),
    );
  }
}

Future<void> callPatientAlt(BuildContext context) async {
  const String phoneNumber = '09385100460';
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
  final messenger = ScaffoldMessenger.of(context);
  final FlutterTts flutterTts = FlutterTts();

  try {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(a11y.speechRate);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    final bool canLaunch = await canLaunchUrl(phoneUri);

    if (!canLaunch) throw 'Could not launch phone dialer';

    await launchUrl(phoneUri);
    await flutterTts.speak('Initiating phone call');
  } catch (e) {
    await flutterTts.speak('Failed to make call.');
    messenger.showSnackBar(
      SnackBar(content: Text('Failed: $e'), backgroundColor: Palette.alert),
    );
  }
}

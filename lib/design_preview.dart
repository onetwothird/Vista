// TEMPORARY: design preview entry point. Delete before committing.
// Starts at onboarding but initialises Firebase like main.dart, so signing in
// from the preview works.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:seelai_app/core/firebase_options.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/themes/vista_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {}
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }
  await themeController.load();
  runApp(
    ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, dark, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VistaTheme.light(),
        darkTheme: VistaTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const OnboardingScreen(),
      ),
    ),
  );
}

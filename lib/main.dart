import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:seelai_app/core/firebase_options.dart';
import 'package:seelai_app/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:seelai_app/themes/vista_theme.dart';
import 'package:seelai_app/shared/accessibility.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final avatarUrl = message.data['callerAvatar'] ?? '';

  if (message.data['type'] == 'emergency_alarm') {
    final patientName = message.data['patientName'] ?? 'Patient';
    final requestMsg =
        message.data['message'] ?? 'Emergency Assistance Needed!';
    final requestId =
        message.data['requestId'] ??
        'req_${DateTime.now().millisecondsSinceEpoch}';

    final callParams = CallKitParams(
      id: requestId,
      nameCaller: patientName,
      appName: 'VISTA EMERGENCY',
      avatar: avatarUrl,
      handle: '🚨 $requestMsg',
      type: 0,
      duration: 30000,
      textAccept: 'Respond',
      textDecline: 'Dismiss',
      extra: <String, dynamic>{'requestId': requestId},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#991B1B',
        actionColor: '#10B981',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        audioSessionMode: 'default',
        audioSessionActive: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(callParams);
  }
}

Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The env file is bundled as `assets/.env` (see pubspec.yaml). A missing
  // file must not stop the app from starting.
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('Could not load assets/.env: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await themeController.load();
  await a11y.load();

  runApp(const MainApp());

  // Ask after the first frame so the permission prompt never blocks startup.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => requestNotificationPermissions(),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final _light = VistaTheme.light();
  static final _dark = VistaTheme.dark();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeController, a11y]),
      builder: (context, _) => MaterialApp(
        title: 'Vista',
        debugShowCheckedModeBanner: false,
        theme: _light,
        darkTheme: _dark,
        themeMode: themeController.value ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: const Duration(milliseconds: 150),
        // Text size, bold text, contrast and motion from Vista's settings.
        builder: (context, child) =>
            MediaQuery(data: a11y.apply(MediaQuery.of(context)), child: child!),
        home: const AnimatedSplashScreenWidget(),
      ),
    );
  }
}

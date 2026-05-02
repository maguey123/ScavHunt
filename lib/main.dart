import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  runApp(const ScavHuntApp());
}

class ScavHuntApp extends StatelessWidget {
  const ScavHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScavHunt',
      theme: ScavTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

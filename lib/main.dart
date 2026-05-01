import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart'; // or AdminCreateGamePage if you prefer

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug // Use debug provider for dev/testing
        : AndroidProvider.playIntegrity, // Use Play Integrity for production
  );

  // 🔥 TEST: Try writing to Firestore
  try {
    final db = FirebaseFirestore.instance;
    await db.collection('test').add({'ping': DateTime.now().toString()});
    print('✅ Firestore write test successful!');
  } catch (e) {
    print('❌ Firestore write test failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Scav',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // or AdminCreateGamePage()
    );
  }
}

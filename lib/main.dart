import 'package:bakenation_staff/database/firebase_options.dart';
import 'package:bakenation_staff/staff/login.dart';
import 'package:bakenation_staff/staff/staff_frame.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? const StaffFramePage()
          : const LoginPage(),
      routes: {
        '/staffFrame': (context) => const StaffFramePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

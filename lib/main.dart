import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:king_queen/core/theme/app_theme.dart';
import 'package:king_queen/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBVhrARTXJgaE54lIlwKkGmxKHG6LCxlww",
      authDomain: "king-queen-minister.firebaseapp.com",
      projectId: "king-queen-minister",
      storageBucket: "king-queen-minister.firebasestorage.app",
      messagingSenderId: "934182573498",
      appId: "1:934182573498:web:fd5709ba2874fc56283983",
    ),
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KING QUEEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}

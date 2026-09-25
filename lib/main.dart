import 'rider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ShreeShyamApp());
}

class ShreeShyamApp extends StatelessWidget {
  const ShreeShyamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jai Shree Shyam Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC8019),
          primary: const Color(0xFFFC8019),
          secondary: const Color(0xFF60B244),
        ),
      ),
      home: MainHomeScreen(),
    );
  }
}

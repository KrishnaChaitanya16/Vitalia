import 'package:flutter/material.dart';
import '/pages/LoginScreen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB4x-t_owBbMSSr_ZzUWhKT8iWV0n8XFM4",
        appId: 'com.example.vitalia',
        messagingSenderId: 'messagingSenderId',
        projectId: 'vitalia-f1af0',
        storageBucket: 'vitalia-f1af0.firebasestorage.app',   ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Loginscreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[200], // Grayish background for BottomNavigationBar
          selectedItemColor: Colors.blue, // Set selected item color
          unselectedItemColor: Colors.black, // Set unselected item color
        ),
      ),
    );

  }
}


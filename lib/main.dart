import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '/providers/Location_provider.dart';  // Import LocationProvider
import '/pages/LoginScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/pages/SplashScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyB4x-t_owBbMSSr_ZzUWhKT8iWV0n8XFM4",
      appId: 'com.example.vitalia',
      messagingSenderId: 'messagingSenderId',
      projectId: 'vitalia-f1af0',
      storageBucket: 'vitalia-f1af0.firebasestorage.app',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        // You can add more providers here in the future like:
        // ChangeNotifierProvider(create: (context) => AnotherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Splashscreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: AppBarTheme(
          color: Colors.white
        ),


        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,

            ),

              
            
          ),
              labelStyle: TextStyle(color: Colors.black),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFBBDEFB), // Grayish background for BottomNavigationBar
          selectedItemColor: Colors.blue, // Set selected item color
          unselectedItemColor: Colors.black,

          // Set unselected item color
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.transparent,


        ),



      ),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child, // Applies gradient to the drawer
        );
      },
    );
  }
}

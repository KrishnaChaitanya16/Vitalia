import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/pages/SignUpScreen.dart';
import '/pages/HomePage.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper function to show Snackbars
  void _showSnackbar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isSuccess ? Colors.blue[900] : Colors.red[900],
      behavior: SnackBarBehavior.floating, // Makes it float above other elements
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _loginWithEmailPassword() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showSnackbar("Login Successful: ${userCredential.user?.email}", true);

      // Navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? "An error occurred", false);
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _showSnackbar("Google Sign-In canceled.", false);
        return; // Exit if the user cancels the sign-in
      }

      // Obtain the Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Generate Firebase credential using Google access tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase using the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Success message
      _showSnackbar("Welcome, ${userCredential.user?.displayName ?? 'User'}!", true);

      // Navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()), // Replace with your home page
      );
    } catch (e) {
      print("Error during Google Sign-In: $e");
      _showSnackbar("Google Sign-In failed. Please try again.", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Login Title
                Text(
                  "Login",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // Username TextField
                TextField(
                  controller: _usernameController,
                  style: GoogleFonts.nunito(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.nunito(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  style: GoogleFonts.nunito(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.nunito(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _loginWithEmailPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(29, 54, 107, 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.nunito(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // Google Login Button
                OutlinedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: Image.asset(
                    'assets/icons/google.png',
                    height: 24,
                  ),
                  label: Text(
                    'Login with Google',
                    style: GoogleFonts.nunito(color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.nunito(color: Colors.blue),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Signupscreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.nunito(color: Colors.blue),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Remove padding from TextButton
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

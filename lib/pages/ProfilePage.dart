import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String fullName, email, gender, dob;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  // Fetch user profile data from Firebase Firestore
  Future<void> _getUserProfile() async {
    User? user = _auth.currentUser;

    if (user != null) {
      // Fetch data from Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Use UID to access the user's profile data
          .get();

      if (snapshot.exists) {
        var userData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          fullName = userData['fullName'] ?? 'Unknown';
          email = userData['email'] ?? 'Unknown';
          gender = userData['gender'] ?? 'Unknown';
          dob = userData['dob'] ?? 'Unknown';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  // Logout function
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
  }

  @override
  Widget build(BuildContext context) {
    final paddingHorizontal = MediaQuery.of(context).size.width * 0.05; // 5% of screen width
    final paddingVertical = MediaQuery.of(context).size.height * 0.02; // 2% of screen height

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Column(
        children: [
          // Custom Container for AppBar with a shadow only below
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 8.0,
                  spreadRadius: 0.0,
                  offset: const Offset(0, 4), // Shadow position only below
                ),
              ],
            ),
            child: AppBar(
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.black), // Black text color
              ),
              backgroundColor: Colors.white, // White app bar
              elevation: 0, // Remove default shadow
              iconTheme: const IconThemeData(color: Colors.black), // Black icons
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: paddingVertical),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator
                  : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                    children: [
                      // Profile Picture Placeholder
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[100], // Grey circle avatar
                          child: const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(height: paddingVertical),
                      // Profile Details
                      _buildProfileDetail('Full Name', fullName, paddingVertical),
                      _buildProfileDetail('Email', email, paddingVertical),
                      _buildProfileDetail('Gender', gender, paddingVertical),
                      _buildProfileDetail('Date of Birth', dob, paddingVertical),
                      SizedBox(height: paddingVertical),
                      // Logout Button
                      TextButton(
                        onPressed: _logout,
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red, // Red color for logout button
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to display profile details inside a white card with shadow
  Widget _buildProfileDetail(String label, String value, double paddingVertical) {
    return Padding(
      padding: EdgeInsets.only(bottom: paddingVertical),
      child: Card(
        color: Colors.white, // White background for each card
        elevation: 5, // Slight shadow for the cards
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical / 2, // Half vertical padding inside the card
            horizontal: paddingVertical, // Horizontal padding relative to screen
          ),
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

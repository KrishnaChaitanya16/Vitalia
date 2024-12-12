import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  String _userName = ""; // To store user's name
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    _getUserDetails(); // Fetch user details when the page is loaded
  }

  // Function to get user details from Firestore
  Future<void> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user details from Firestore
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Assuming the user's full name is stored in the field 'fullName'
        setState(() {
          _userName = userDoc['fullName'] ?? "User";
          _isLoading = false; // Stop loading when user details are fetched
        });
      } else {
        setState(() {
          _userName = "User"; // Default if user data is not found
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false; // Stop loading if there's no user signed in
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to manually refresh user details (pull-to-refresh feature)
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true; // Start loading again
    });
    await _getUserDetails(); // Re-fetch the user details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keep the background white
      appBar: AppBar(
        backgroundColor: Colors.white, // Set the AppBar color to white
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black, // Set the menu icon color to black
          ),
          onPressed: () {
            // Handle menu click here
          },
        ),
        title: _isLoading
            ? null // Do not show any title while loading
            : Text(
          'Hello, ${_userName.length > 7 ? _userName.substring(0, 7) : _userName}',
          style: GoogleFonts.nunito(
            color: Colors.black, // Text color for greeting
            fontSize: 20, // Font size
          ),
          overflow: TextOverflow.ellipsis, // Prevent overflow if name is too long
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black, // Set the notification bell icon color to black
            ),
            onPressed: () {
              // Handle notification click here
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Use the pull-to-refresh feature
        child: Center(
          child: const Text(
            'Homepage Content',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light grey, almost white
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.grey[100], // Match background color with the container
          selectedItemColor: Colors.blue, // Selected item color
          unselectedItemColor: Colors.black54, // Unselected item color slightly faded
          type: BottomNavigationBarType.fixed, // Fix labels in place
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital),
              label: 'MyHealth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'MyBills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

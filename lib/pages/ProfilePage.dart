import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/pages/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({Key? key}) : super(key: key);

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String fullName = 'Unknown';
  late String email = 'Unknown';
  late String gender = 'Unknown';
  late String dob = 'Unknown';
  late String bloodGroup = 'Unknown'; // New blood group field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not logged in');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final userData = snapshot.data()!;
        setState(() {
          fullName = userData['fullName'] ?? 'Unknown';
          email = userData['email'] ?? 'Unknown';
          gender = userData['gender'] ?? 'Unknown';
          dob = userData['dob'] ?? 'Unknown';
          bloodGroup = userData['bloodGroup'] ?? 'Unknown'; // Fetch blood group
          _isLoading = false;
        });
      } else {
        _showSnackBar('User data not found in Firestore');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserProfile(String key, String value) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({key: value});
      _showSnackBar('$key updated successfully');
    } catch (e) {
      _showSnackBar('Error updating $key: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(),
                    const SizedBox(height: 30),
                    _buildProfileCard(),
                    const SizedBox(height: 30),
                    _buildLogoutButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          email,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEditableProfileItem(
            icon: Icons.person,
            title: 'Full Name',
            value: fullName,
            keyName: 'fullName',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.email,
            title: 'Email',
            value: email,
            keyName: 'email',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.wc,
            title: 'Gender',
            value: gender,
            keyName: 'gender',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.cake,
            title: 'Date of Birth',
            value: dob,
            keyName: 'dob',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.bloodtype,
            title: 'Blood Group',
            value: bloodGroup,
            keyName: 'bloodGroup', // Blood group field
          ),
        ],
      ),
    );
  }

  Widget _buildEditableProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required String keyName,
  }) {
    final bool isEditable = value == 'Unknown'; // Check if the value is 'Unknown'

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              isEditable
                  ? TextFormField(
                initialValue: '',
                decoration: InputDecoration(

                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                ),
                onFieldSubmitted: (newValue) {
                  if (newValue.isNotEmpty) {
                    setState(() {
                      if (keyName == 'fullName') fullName = newValue;
                      if (keyName == 'email') email = newValue;
                      if (keyName == 'gender') gender = newValue;
                      if (keyName == 'dob') dob = newValue;
                      if (keyName == 'bloodGroup') bloodGroup = newValue; // Update blood group
                    });
                    _updateUserProfile(keyName, newValue);
                  }
                },
              )
                  : Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        if (isEditable)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              _showSnackBar('You can edit the $title field directly.');
            },
          ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Log out the user
      await _auth.signOut();

      // Navigate to the login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginscreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showSnackBar('Error logging out: $e');
    }
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  late String bloodGroup = 'Unknown';
  late String height ='Unknown';
  late String weight ='Unknown';
  late String bloodPressure ='Unknown';
  late String pulseRate ='Unknown';
  late List<String> surgeries = [];
  late List<String> medications = [];
  late List<dynamic> allergies = [];

  // New blood group field
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
          bloodGroup = userData['bloodGroup'] ?? 'Unknown';
          height = userData['height']?.toString() ?? 'Unknown';
          weight = userData['weight']?.toString() ?? 'Unknown';
          bloodPressure = userData['bloodPressure'] ?? 'Unknown';
          pulseRate = userData['pulseRate'] ?? 'Unknown';

          // Fixed the list type conversions
          if (userData['surgeries'] is List) {
            surgeries = List<String>.from(userData['surgeries']);
          } else if (userData['surgeries'] is String) {
            surgeries = [userData['surgeries']];
          } else {
            surgeries = [];
          }

          if (userData['medications'] is List) {
            medications = List<String>.from(userData['medications']);
          } else if (userData['medications'] is String) {
            medications = [userData['medications']];
          } else {
            medications = [];
          }

          if (userData['allergies'] is List) {
            allergies = List<String>.from(userData['allergies']);
          } else if (userData['allergies'] is String) {
            allergies = [userData['allergies']];
          } else {
            allergies = [];
          }

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

  Future<void> _updateUserProfile(String key, dynamic value) async {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Basic Information'),
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
            keyName: 'bloodGroup',
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Vitals'),
          _buildEditableProfileItem(
            icon: Icons.height,
            title: 'Height',
            value: height,
            keyName: 'height',
            suffix: 'cm',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.monitor_weight,
            title: 'Weight',
            value: weight,
            keyName: 'weight',
            suffix: 'kg',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.favorite,
            title: 'Blood Pressure',
            value: bloodPressure,
            keyName: 'bloodPressure',
            suffix: 'mmHg',
          ),
          const Divider(height: 30),
          _buildEditableProfileItem(
            icon: Icons.timeline,
            title: 'Pulse Rate',
            value: pulseRate,
            keyName: 'pulseRate',
            suffix: 'bpm',
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Medical History'),
          _buildListSection(
            icon: Icons.medical_services,
            title: 'Past Conditions',
            items: surgeries,
            keyName: 'surgeries',
          ),
          const Divider(height: 30),
          _buildListSection(
            icon: Icons.medication,
            title: 'Current Medications',
            items: medications,
            keyName: 'medications',
          ),
          const Divider(height: 30),
          _buildListSection(
            icon: Icons.warning,
            title: 'Allergies',
            items: allergies,
            keyName: 'allergies',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildEditableProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required String keyName,
    String? suffix,
  }) {
    final bool isEditable = value == 'Unknown';

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
                  suffixText: suffix,
                ),
                onFieldSubmitted: (newValue) {
                  if (newValue.isNotEmpty) {
                    setState(() {
                      switch (keyName) {
                        case 'fullName':
                          fullName = newValue;
                          break;
                        case 'email':
                          email = newValue;
                          break;
                        case 'gender':
                          gender = newValue;
                          break;
                        case 'dob':
                          dob = newValue;
                          break;
                        case 'bloodGroup':
                          bloodGroup = newValue;
                          break;
                        case 'height':
                          height = newValue;
                          break;
                        case 'weight':
                          weight = newValue;
                          break;
                        case 'bloodPressure':
                          bloodPressure = newValue;
                          break;
                        case 'pulseRate':
                          pulseRate = newValue;
                          break;
                      }
                    });
                    _updateUserProfile(keyName, newValue);
                  }
                },
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            setState(() {
              switch (keyName) {
                case 'fullName':
                  fullName = 'Unknown';
                  break;
                case 'email':
                  email = 'Unknown';
                  break;
                case 'gender':
                  gender = 'Unknown';
                  break;
                case 'dob':
                  dob = 'Unknown';
                  break;
                case 'bloodGroup':
                  bloodGroup = 'Unknown';
                  break;
                case 'height':
                  height = 'Unknown';
                  break;
                case 'weight':
                  weight = 'Unknown';
                  break;
                case 'bloodPressure':
                  bloodPressure = 'Unknown';
                  break;
                case 'pulseRate':
                  pulseRate = 'Unknown';
                  break;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildListSection({
    required IconData icon,
    required String title,
    required List<dynamic> items,
    required String keyName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          items.remove(item);
                        });
                        _updateUserProfile(keyName, items);
                      },
                    ),
                  ],
                ),
              )),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Add new item...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      items.add(value);
                    });
                    _updateUserProfile(keyName, items);
                  }
                },
              ),
            ],
          ),
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
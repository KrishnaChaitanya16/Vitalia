import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';  // Import google_fonts package

class Yourtests extends StatefulWidget {
  const Yourtests({super.key});

  @override
  State<Yourtests> createState() => _YourtestsState();
}

class _YourtestsState extends State<Yourtests> {
  List<Map<String, dynamic>> _completedTests = [];
  List<Map<String, dynamic>> _upcomingTests = [];
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user full name from 'users' collection
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userFullName = userDoc.data()?['fullName'];
          });
        }

        // Fetch the user's test data from 'bookings' collection
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userName', isEqualTo: _userFullName)
            .get();

        // Segregate the tests into completed and upcoming based on date
        final now = DateTime.now();
        final completed = <Map<String, dynamic>>[];
        final upcoming = <Map<String, dynamic>>[];

        for (var doc in querySnapshot.docs) {
          final testData = doc.data();
          final testDate = DateTime.tryParse(testData['date'] ?? '');

          if (testDate != null) {
            if (testDate.isBefore(now)) {
              completed.add(testData);
            } else {
              upcoming.add(testData);
            }
          }
        }

        setState(() {
          _completedTests = completed;
          _upcomingTests = upcoming;
        });
      }
    } catch (e) {
      print("Error fetching user details or tests: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Tests',
          style: GoogleFonts.nunito(),  // Apply the Nunito font to the AppBar title
        ),
        elevation: 10,  // Add shadow effect to the AppBar
        toolbarHeight: 60,  // Adjust AppBar height if needed
      ),
      body: _completedTests.isEmpty && _upcomingTests.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner if no data
          : SingleChildScrollView(
        child: Column(
          children: [
            if (_completedTests.isNotEmpty)
              _buildTestSection('Completed Tests', _completedTests),
            _buildTestSection('Upcoming Tests', _upcomingTests),
          ],
        ),
      ),
    );
  }

  // Helper method to build a section for completed or upcoming tests
  Widget _buildTestSection(String title, List<Map<String, dynamic>> tests) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (tests.isEmpty)
            const Text('No tests found')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,  // Shadow color
                        offset: Offset(2, 2),  // Shadow offset
                        blurRadius: 6,  // Shadow blur radius
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child:ListTile(
                    title: Text(test['testName'] ?? 'Unknown Test',
                        style: GoogleFonts.nunito()),  // Apply Nunito font
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${test['date'] ?? 'Unknown Date'}',
                          style: GoogleFonts.nunito(),  // Apply Nunito font
                        ),
                        Text(
                          'Center: ${test['diagnosticCenter'] ?? 'Unknown Center'}',
                          style: GoogleFonts.nunito(),  // Apply Nunito font
                        ),
                        Text(
                          'Location: ${test['diagnosticCenterLocation'] ?? 'Unknown Location'}',
                          style: GoogleFonts.nunito(),  // Apply Nunito font
                        ),
                      ],
                    ),

                  ),

                );
              },
            ),
        ],
      ),
    );
  }
}

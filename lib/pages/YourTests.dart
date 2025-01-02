import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Yourtests extends StatefulWidget {
  const Yourtests({super.key});

  @override
  State<Yourtests> createState() => _YourtestsState();
}

class _YourtestsState extends State<Yourtests> {
  List<Map<String, dynamic>> _completedTests = [];
  List<Map<String, dynamic>> _upcomingTests = [];
  String? _userFullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userFullName = userDoc.data()?['fullName'];
          });
        }

        final querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userName', isEqualTo: _userFullName)
            .get();

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
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user details or tests: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'Your Tests',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchUserDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Upcoming',
                        _upcomingTests.length.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Completed',
                        _completedTests.length.toString(),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_upcomingTests.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming Tests', Icons.upcoming),
                  const SizedBox(height: 12),
                  ..._upcomingTests.map((test) => _buildTestCard(test, true)),
                  const SizedBox(height: 24),
                ],

                if (_completedTests.isNotEmpty) ...[
                  _buildSectionHeader('Completed Tests', Icons.check_circle),
                  const SizedBox(height: 12),
                  ..._completedTests.map((test) => _buildTestCard(test, false)),
                ],

                if (_completedTests.isEmpty && _upcomingTests.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    test['testName'] ?? 'Unknown Test',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildStatusChip(isUpcoming),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(test['date'] ?? 'Unknown Date')),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.local_hospital, 'Center', test['diagnosticCenter'] ?? 'Unknown Center'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Location', test['diagnosticCenterLocation'] ?? 'Unknown Location'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isUpcoming) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUpcoming ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpcoming ? Colors.blue : Colors.green,
          width: 1,
        ),
      ),
      child: Text(
        isUpcoming ? 'Upcoming' : 'Completed',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isUpcoming ? Colors.blue : Colors.green,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tests Found',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t booked any tests yet',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
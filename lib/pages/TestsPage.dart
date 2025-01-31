import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/HomePage.dart';

class Testspage extends StatelessWidget {
  final Map<String, dynamic> diagnosticCenter;


  const Testspage({super.key, required this.diagnosticCenter});

  // Method to fetch available tests from Firestore or use default tests if not available
  Future<List<String>> _fetchTests(BuildContext context) async {
    final String centerId = diagnosticCenter['id'] ?? 'default_id';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final centerDocRef = firestore.collection('diagnostic_centres').doc(centerId);
      final centerSnapshot = await centerDocRef.get();

      if (!centerSnapshot.exists) {
        List<String> defaultTests = ['Blood Test', 'X-Ray', 'MRI Scan', 'CT Scan', 'ECG'];

        // Create the diagnostic center with default tests if not present
        await centerDocRef.set({
          'name': diagnosticCenter['name'] ?? 'Unnamed Center',
          'location': diagnosticCenter['vicinity'] ?? 'Unknown Location',
          'tests': defaultTests,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagnostic center created with default tests.')),
        );

        return defaultTests;
      }

      final data = centerSnapshot.data()!;
      return List<String>.from(data['tests'] ?? []);
    } catch (e) {
      debugPrint('Error fetching or creating diagnostic center: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          diagnosticCenter['name'] ?? 'Diagnostic Center',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Tests:',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _fetchTests(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error fetching tests. Please try again later.',
                          style: GoogleFonts.nunito(fontSize: 16, color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No tests available at this center.',
                          style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }

                    final tests = snapshot.data!;
                    return ListView.builder(
                      itemCount: tests.length,
                      itemBuilder: (context, index) {
                        final testName = tests[index];
                        return ListTile(
                          title: Text(
                            testName,
                            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookSlotPage(testName: testName,diagnosticCenter:diagnosticCenter,),
                                ),
                              );
                            },
                            child: const Text(
                              'Book Test',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookSlotPage extends StatefulWidget {
  final String testName;
  final Map<String, dynamic> diagnosticCenter;


  const BookSlotPage({super.key, required this.testName,required this.diagnosticCenter});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to update booking in Firestore
  Future<void> _updateBookingInFirestore() async {
    try {
      // Retrieve the current user's ID from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId == null) {
        throw 'User not logged in';
      }

      // Retrieve user details from the Firestore 'users' collection
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Fetch the full name, or default to 'Anonymous' if not available
      final userName = userDoc.exists && userDoc.data() != null
          ? userDoc.data()!['fullName'] ?? 'Anonymous'
          : 'Anonymous';

      // Retrieve diagnostic center details
      final diagnosticCenterName = widget.diagnosticCenter['name'] ?? 'Unnamed Center';
      final diagnosticCenterLocation = widget.diagnosticCenter['vicinity'] ?? 'Unknown Location';

      // Add the booking data to Firestore
      await _firestore.collection('bookings').add({
        'testName': widget.testName,
        'date': _selectedDay?.toIso8601String().split('T').first ?? '',
        'time': _selectedTime?.format(context) ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'userName': userName,  // Add the user's full name
        'diagnosticCenter': diagnosticCenterName,  // Add the diagnostic center name
        'diagnosticCenterLocation': diagnosticCenterLocation,  // Add the diagnostic center location
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking confirmed!")),
      );
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating booking. Try again!")),
      );
    }
  }

  void _confirmBooking() async {
    if (_selectedDay != null && _selectedTime != null) {
      await _updateBookingInFirestore(); // Update Firestore with booking data

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessPage(
            testName: widget.testName,
            selectedDate: _selectedDay!,
            selectedTime: _selectedTime!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time!")),
      );
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Book Slot for ${widget.testName}",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Date:",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Select Time:",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(
                      _selectedTime == null
                          ? "Choose a time"
                          : "Selected Time: ${_selectedTime!.format(context)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.access_time, color: Colors.blue),
                    onTap: _selectTime,
                    tileColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class SuccessPage extends StatelessWidget {
  final String testName;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  const SuccessPage({
    super.key,
    required this.testName,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(  // Center the content horizontally and vertically
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),

              // Title Text
              const Text(
                "Booking Successful!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Booking Details Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Test: $testName\n"
                      "Date: ${selectedDate.toLocal().toString().split(' ')[0]}\n"
                      "Time: ${selectedTime.format(context)}",
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Go Back Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Homepage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Go Back to Home",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
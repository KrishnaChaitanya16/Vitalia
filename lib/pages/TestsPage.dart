import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';


class Testspage extends StatelessWidget {
  final Map<String, dynamic> diagnosticCenter;

  const Testspage({super.key, required this.diagnosticCenter});

  Future<List<String>> _fetchTests(BuildContext context) async {
    final String centerId = diagnosticCenter['id'] ?? 'default_id';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final centerDocRef = firestore.collection('diagnostic_centres').doc(centerId);
      final centerSnapshot = await centerDocRef.get();

      if (!centerSnapshot.exists) {
        List<String> defaultTests = ['Blood Test', 'X-Ray', 'MRI Scan', 'CT Scan', 'ECG'];

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
      body: Padding(
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
                                builder: (context) => BookSlotPage(testName: testName),
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
    );
  }
}

class BookSlotPage extends StatefulWidget {
  final String testName;

  const BookSlotPage({super.key, required this.testName});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;

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

  void _confirmBooking() {
    if (_selectedDay != null && _selectedTime != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time!")),
      );
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
                  // Calendar Widget
                  Text(
                    "Select Date:",
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

                  // Time Picker
                  Text(
                    "Select Time:",
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

          // Confirm Button at Bottom
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
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thin Circle with Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green, // Thin green border
                  width: 4, // Border thickness
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80, // Icon size
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Success Message
            const Text(
              "Booking Successful!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "Your test slot has been booked successfully.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Go Home Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                  foregroundColor: Colors.white, // Text color
                  minimumSize: const Size(double.infinity, 50), // Full-width button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                ),
                child: const Text(
                  "Go to Home",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

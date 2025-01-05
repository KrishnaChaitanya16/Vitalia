import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/HomePage.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsPage({super.key, required this.appointment});

  // Function to handle cancellation
  Future<void> _cancelAppointment(BuildContext context, String doctorName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Please log in again.')),
        );
        return;
      }

      // Query for the document with the current user and specific doctorName
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorName', isEqualTo: doctorName)
          .where('userId', isEqualTo: user.email) // Assuming userId is email
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching appointment found.')),
        );
        return;
      }

      // Loop through all matching documents and delete them
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel appointment. Please try again.')),
      );
      print('Error canceling appointment: $e');
    }
  }


  // Function to navigate to reschedule page
  void _rescheduleAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleAppointmentPage(appointment: appointment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = (appointment['selectedDate'] as Timestamp).toDate();
    final selectedSlot = appointment['selectedSlot'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 8.0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: const Color.fromRGBO(219, 239, 255, 1), // Background color
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor: ${appointment['doctorName']}',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
              style: GoogleFonts.nunito(
                fontSize: 20,
              ),
            ),
            Text(
              'Time: $selectedSlot',
              style: GoogleFonts.nunito(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Additional Details:',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Patient Name: ${appointment['patientName']}',
              style: GoogleFonts.nunito(
                fontSize: 20,
              ),
            ),
            Text(
              'Status: ${appointment['status']}',
              style: GoogleFonts.nunito(
                fontSize: 20,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reschedule Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Background color
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    textStyle: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _rescheduleAppointment(context),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                // Cancel Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Background color
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    textStyle: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      _cancelAppointment(context, appointment['doctorName']),
                  child: const Text(
                    'Cancel Appointment',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}





class RescheduleAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const RescheduleAppointmentPage({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  _RescheduleAppointmentPageState createState() => _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  DateTime? _newDate;
  String? _newSlot;
  Set<String> bookedSlots = {};
  List<String> availableSlots = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't load slots initially, wait for date selection
  }

  Future<void> _loadSlotsForDate(DateTime selectedDate) async {
    setState(() {
      isLoading = true;
      _newSlot = null; // Reset selected slot when date changes
      availableSlots.clear(); // Clear previous slots
      bookedSlots.clear(); // Clear previous booked slots
    });

    try {
      // First fetch all available slots for the doctor
      final slots = await _fetchTimeSlots();
      print("Fetched all slots from doctor: $slots"); // Debug print

      // Then fetch booked slots for the selected date
      await _fetchBookedSlots(selectedDate);
      print("Fetched booked slots: $bookedSlots"); // Debug print

      // Update available slots
      setState(() {
        availableSlots = slots;
        isLoading = false;
      });

      // Debug print filtered slots
      final filteredSlots = slots.where((slot) => !bookedSlots.contains(slot)).toList();
      print("Available slots after filtering: $filteredSlots");
    } catch (e) {
      print("Error loading slots: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchTimeSlots() async {
    try {
      // Query the doctors collection using the doctor's name
      final doctorQuery = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: widget.appointment['doctorName'])
          .get();

      if (doctorQuery.docs.isNotEmpty) {
        // Assuming there will only be one match for the doctor's name
        final doctorData = doctorQuery.docs.first.data();
        if (doctorData['availableSlots'] != null) {
          List<String> slots = List<String>.from(doctorData['availableSlots']);
          print("Successfully fetched slots: $slots"); // Debug print
          return slots;
        }
      }
      print("No slots found for the doctor name: ${widget.appointment['doctorName']}"); // Debug print
    } catch (e) {
      print("Error fetching time slots: $e");
    }
    return [];
  }


  Future<void> _fetchBookedSlots(DateTime selectedDate) async {
    try {
      // Normalize the selected date to start of day
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.appointment['doctorId'])
          .where('selectedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('selectedDate', isLessThan: Timestamp.fromDate(startOfDay.add(const Duration(days: 1))))
          .get();

      setState(() {
        bookedSlots = snapshot.docs
            .map((doc) => doc['selectedSlot'] as String)
            .toSet();
        print("Booked Slots for ${startOfDay.toString()}: $bookedSlots"); // Debug print
      });
    } catch (e) {
      print("Error fetching booked slots: $e");
    }
  }

  Future<void> _reschedule() async {
    if (_newDate == null || _newSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a new date and time slot.')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Query to find the document based on doctorName and patientName
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorName', isEqualTo: widget.appointment['doctorName'])
          .where('patientName', isEqualTo: widget.appointment['patientName'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming there is only one matching document
        final docId = querySnapshot.docs.first.id;

        // Update the selectedSlot and other fields
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({
          'selectedDate': Timestamp.fromDate(_newDate!),
          'selectedSlot': _newSlot,

          'lastUpdated': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rescheduled successfully!')),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context)=> Homepage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching appointment found.')),
        );
      }
    } catch (e) {
      print('Error while rescheduling: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reschedule appointment. Please try again.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the available slots excluding booked ones
    final filteredSlots = availableSlots.where((slot) => !bookedSlots.contains(slot)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a new date:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _newDate ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(_newDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _newDate = selectedDay;
                });
                _loadSlotsForDate(selectedDay);
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a new time slot:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_newDate == null)
              const Center(child: Text('Please select a date first'))
            else if (filteredSlots.isEmpty)
                const Center(child: Text('No available time slots for this date'))
              else
                GridView.builder(
                  shrinkWrap: true, // Ensures it doesn't take infinite height
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two slots per row
                    crossAxisSpacing: 10, // Space between columns
                    mainAxisSpacing: 10, // Space between rows
                    childAspectRatio: 3, // Adjust the aspect ratio for button height
                  ),
                  itemCount: filteredSlots.length,
                  itemBuilder: (context, index) {
                    final slot = filteredSlots[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _newSlot = slot;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _newSlot == slot ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 16,
                            color: _newSlot == slot ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: isLoading ? null : _reschedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reschedule Appointment',style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
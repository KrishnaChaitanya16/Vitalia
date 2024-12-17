import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsPage({super.key, required this.appointment});

  // Function to handle cancellation
  Future<void> _cancelAppointment(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment['appointmentId'])
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel appointment. Please try again.')),
      );
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
        title: const Text('Appointment Details'),
        elevation: 8.0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor: ${appointment['doctorName']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Time: $selectedSlot',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 25),
            const Text(
              'Additional Details:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Patient Name: ${appointment['patientName']}',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Status: ${appointment['status']}',
              style: const TextStyle(fontSize: 20),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  onPressed: () => _rescheduleAppointment(context),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  onPressed: () => _cancelAppointment(context),
                  child: const Text(
                    'Cancel Appointment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
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

  const RescheduleAppointmentPage({Key? key, required this.appointment})
      : super(key: key);

  @override
  _RescheduleAppointmentPageState createState() =>
      _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  DateTime? _newDate;
  String? _newSlot;
  Set<String> bookedSlots = {}; // Set to store booked slots

  // Fetch the available time slots from Firestore
  Future<List<String>> _fetchTimeSlots() async {
    try {
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.appointment['name']) // Assuming doctorId is available in the appointment
          .get();

      if (doctorSnapshot.exists) {
        final doctorData = doctorSnapshot.data();
        if (doctorData != null && doctorData['availableSlots'] != null) {
          return List<String>.from(doctorData['availableSlots']);
        }
      }
    } catch (e) {
      print("Error fetching time slots: $e");
    }
    return []; // Return empty if no slots are found or there's an error
  }

  // Fetch booked slots for the selected date
  Future<void> _fetchBookedSlots(DateTime selectedDate) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.appointment['name'])
          .where('selectedDate', isEqualTo: Timestamp.fromDate(selectedDate))
          .get();

      setState(() {
        bookedSlots = snapshot.docs
            .map((doc) => doc['selectedSlot'] as String)
            .toSet(); // Store booked slots in a set
        print("Booked Slots: $bookedSlots"); // Debugging: Check the booked slots
      });
    } catch (e) {
      print("Error fetching booked slots: $e");
    }
  }

  // Reschedule the appointment
  Future<void> _reschedule() async {
    if (_newDate == null || _newSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a new date and time slot.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment['appointmentId'])
          .update({
        'selectedDate': Timestamp.fromDate(_newDate!),
        'selectedSlot': _newSlot,
        'status': 'Rescheduled',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reschedule appointment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: Colors.white,
        elevation: 0, // Remove app bar shadow for a cleaner look
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
            // Calendar widget directly in the UI
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _newDate ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(_newDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _newDate = selectedDay; // Update new date
                });
                _fetchBookedSlots(selectedDay); // Fetch booked slots for the selected date
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange, // Highlight today's date
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue, // Highlight selected date
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
            FutureBuilder<List<String>>(
              future: _fetchTimeSlots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading time slots.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No available time slots.'));
                }
                final timeSlots = snapshot.data!;

                // If no appointments exist for the selected date, show all available slots
                if (_newDate == null || bookedSlots.isEmpty) {
                  return DropdownButton<String>(
                    value: _newSlot,
                    hint: const Text('Select Time Slot'),
                    items: timeSlots.map((slot) {
                      return DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _newSlot = value;
                      });
                    },
                  );
                } else {
                  // Filter out the booked slots
                  final availableSlots = timeSlots.where((slot) => !bookedSlots.contains(slot)).toList();
                  print("Available Slots after filtering: $availableSlots");

                  return availableSlots.isEmpty
                      ? const Center(child: Text('No available slots for this date.'))
                      : DropdownButton<String>(
                    value: _newSlot,
                    hint: const Text('Select Time Slot'),
                    items: availableSlots.map((slot) {
                      return DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _newSlot = value;
                      });
                    },
                  );
                }
              },
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: _reschedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue background color
                  padding: const EdgeInsets.symmetric(vertical: 16.0), // Larger button
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Reschedule Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '/pages/SuccessPage.dart';
import 'dart:async';

class Appoinmetpage extends StatefulWidget {
  final String doctorName;
  final List<String> availableSlots;

  const Appoinmetpage({
    Key? key,
    required this.doctorName,
    required this.availableSlots,
  }) : super(key: key);

  @override
  _AppoinmetpageState createState() => _AppoinmetpageState();
}

class _AppoinmetpageState extends State<Appoinmetpage> {
  DateTime? selectedDate; // Selected date
  DateTime focusedDate = DateTime.now(); // Currently focused date in the calendar
  int? selectedSlotIndex; // Index of the selected time slot
  Set<int> bookedSlots = {}; // Set of booked slot indices for the selected date
  StreamSubscription? appointmentListener; // Firestore listener for real-time updates

  // Firestore and Auth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAndAddDoctor();
    _listenToAppointments(); // Real-time updates for appointments
  }

  @override
  void dispose() {
    appointmentListener?.cancel(); // Cancel listener when the widget is disposed
    super.dispose();
  }

  // Check if the doctor exists in Firestore, add if not
  Future<void> _checkAndAddDoctor() async {
    final doctorSnapshot = await _firestore
        .collection('doctors')
        .where('name', isEqualTo: widget.doctorName)
        .get();

    if (doctorSnapshot.docs.isEmpty) {
      await _firestore.collection('doctors').add({
        'name': widget.doctorName,
        'availableSlots': widget.availableSlots,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // Listen to appointments in real-time and update booked slots
  void _listenToAppointments() {
    appointmentListener = _firestore
        .collection('appointments')
        .where('doctorName', isEqualTo: widget.doctorName)
        .snapshots()
        .listen((snapshot) {
      if (selectedDate != null) {
        _fetchBookedSlots(selectedDate!);
      }
    });
  }

  // Fetch booked slots for the selected date
  Future<void> _fetchBookedSlots(DateTime date) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('doctorName', isEqualTo: widget.doctorName)
        .where('selectedDate', isEqualTo: Timestamp.fromDate(date))
        .get();

    setState(() {
      bookedSlots = snapshot.docs.map((doc) {
        final slot = doc['selectedSlot'] as String;
        return widget.availableSlots.indexOf(slot);
      }).toSet();
    });
  }

  // Book an appointment
  Future<void> _bookAppointment() async {
    if (selectedDate != null && selectedSlotIndex != null) {
      final userEmail = _auth.currentUser?.email ?? 'Unknown User';

      await _firestore.collection('appointments').add({
        'doctorName': widget.doctorName,
        'patientName': userEmail,
        'selectedDate': selectedDate!,
        'selectedSlot': widget.availableSlots[selectedSlotIndex!],
        'userId': userEmail,
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment Confirmed for '
                '${selectedDate!.toLocal().toString().split(' ')[0]} at '
                '${widget.availableSlots[selectedSlotIndex!]}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessPage(
            doctorName: widget.doctorName,
            selectedDate: selectedDate!,
            selectedSlot: widget.availableSlots[selectedSlotIndex!],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Book Appointment - ${widget.doctorName}',
          style: const TextStyle(color: Colors.black),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date for ${widget.doctorName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Embedded Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: focusedDate,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              selectedDayPredicate: (day) => selectedDate != null && isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                  this.focusedDate = focusedDay;
                });
                _fetchBookedSlots(selectedDay); // Fetch booked slots for the selected day
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Available Slots',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3,
                ),
                itemCount: widget.availableSlots.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedSlotIndex == index;
                  bool isBooked = bookedSlots.contains(index);

                  return GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                      setState(() {
                        selectedSlotIndex = index;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected Slot: ${widget.availableSlots[index]}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      color: isBooked
                          ? Colors.grey.shade300 // Disable booked slots
                          : isSelected
                          ? Colors.blue
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          widget.availableSlots[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isBooked
                                ? Colors.grey
                                : isSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: (selectedDate != null && selectedSlotIndex != null && !bookedSlots.contains(selectedSlotIndex))
                  ? _bookAppointment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (selectedDate != null && selectedSlotIndex != null && !bookedSlots.contains(selectedSlotIndex))
                    ? Colors.blue
                    : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                (selectedDate != null && selectedSlotIndex != null && !bookedSlots.contains(selectedSlotIndex))
                    ? 'Confirm Appointment'
                    : 'Select Date & Slot',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

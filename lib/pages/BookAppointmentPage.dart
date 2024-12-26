import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/AppointmentDetailsPage.dart';// Import the AppointmentDetailsPage
import '/pages/ReveiwsPage.dart';

class Bookappointmentpage extends StatefulWidget {
  const Bookappointmentpage({super.key});

  @override
  State<Bookappointmentpage> createState() => _BookappointmentpageState();
}

class _BookappointmentpageState extends State<Bookappointmentpage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> completedAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final now = DateTime.now();
    final currentUserEmail = _auth.currentUser?.email;

    if (currentUserEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
      return;
    }

    final appointmentsSnapshot = await _firestore
        .collection('appointments')
        .where('patientName', isEqualTo: currentUserEmail)
        .get();

    List<Map<String, dynamic>> tempUpcomingAppointments = [];
    List<Map<String, dynamic>> tempCompletedAppointments = [];

    for (var doc in appointmentsSnapshot.docs) {
      final appointmentData = doc.data();
      final DateTime selectedDate = (appointmentData['selectedDate'] as Timestamp).toDate();

      if (selectedDate.isAfter(now)) {
        tempUpcomingAppointments.add(appointmentData);
      } else {
        tempCompletedAppointments.add(appointmentData);
      }
    }

    setState(() {
      upcomingAppointments = tempUpcomingAppointments;
      completedAppointments = tempCompletedAppointments;
    });
  }

  // Function to navigate to AppointmentDetailsPage
  void _navigateToDetails(Map<String, dynamic> appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsPage(appointment: appointment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        elevation: 6.0, // Shadow effect at the bottom of AppBar
        shadowColor: Colors.grey.withOpacity(0.3),
        backgroundColor: Colors.white,// Adjust the shadow color and opacity
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE3F2FD),  Color(0xFFBBDEFB)])
        ),
          child:Padding(

        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Upcoming Appointments Section
            if (upcomingAppointments.isNotEmpty)
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontFamily: 'Nunito',  // Set the font to Nunito
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (upcomingAppointments.isNotEmpty)
              ...upcomingAppointments.map((appointment) {
                final selectedDate = (appointment['selectedDate'] as Timestamp).toDate();
                final selectedSlot = appointment['selectedSlot'];

                return Card(
                  elevation: 9,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                    shadowColor: Colors.black54.withOpacity(0.7),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Colors.lightBlueAccent.shade100.withOpacity(0.7),
                  child: ListTile(
                    title: Text(
                      'Doctor: ${appointment['doctorName']}',
                      style: const TextStyle(fontFamily: 'Nunito'),  // Set the font to Nunito
                    ),
                    subtitle: Text(
                      'Date: ${selectedDate.toLocal().toString().split(' ')[0]}\nTime: $selectedSlot',
                      style: const TextStyle(fontFamily: 'Nunito'),  // Set the font to Nunito
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _navigateToDetails(appointment), // Navigate to details page on tap
                  ),
                );
              }).toList(),

            const SizedBox(height: 20),

            // Completed Appointments Section
            if (completedAppointments.isNotEmpty)
              const Text(
                'Completed Appointments',
                style: TextStyle(
                  fontFamily: 'Nunito',  // Set the font to Nunito
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (completedAppointments.isNotEmpty)
              ...completedAppointments.map((appointment) {
                final selectedDate = (appointment['selectedDate'] as Timestamp).toDate();
                final selectedSlot = appointment['selectedSlot'];

                return Card(
                  color: Colors.white,
                  shadowColor: Colors.black54.withOpacity(0.7),
                  elevation: 9,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          'Doctor: ${appointment['doctorName']}',
                          style: const TextStyle(fontFamily: 'Nunito'),
                        ),
                        subtitle: Text(
                          'Date: ${selectedDate.toLocal().toString().split(' ')[0]}\nTime: $selectedSlot',
                          style: const TextStyle(fontFamily: 'Nunito'),
                        ),
                        trailing: const Icon(Icons.history),
                        onTap: () => _navigateToDetails(appointment),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewsPage(appointment: appointment),
                                ),
                              );
                            },
                            child: const Text(
                              'Write a Review',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              }).toList(),

            if (upcomingAppointments.isEmpty && completedAppointments.isEmpty)
              const Center(
                child: Text(
                  'No appointments available',
                  style: TextStyle(fontFamily: 'Nunito'),  // Set the font to Nunito
                ),
              ),
          ],
        ),
      )),
    );
  }
}

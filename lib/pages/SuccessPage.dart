import 'package:flutter/material.dart';
import '/pages/HomePage.dart';
class SuccessPage extends StatelessWidget {
  final String doctorName;
  final DateTime selectedDate;
  final String selectedSlot;

  const SuccessPage({
    Key? key,
    required this.doctorName,
    required this.selectedDate,
    required this.selectedSlot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // This container centers the content vertically
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Checkmark animation
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeIn,
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Appointment Booked Successfully',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Doctor: $doctorName\n'
                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}\n'
                        'Time: $selectedSlot',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
            // This spacer pushes the button to the bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the home page, replacing the current screen
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Homepage())); // Replace '/home' with your actual route
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Go Back to Home',
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

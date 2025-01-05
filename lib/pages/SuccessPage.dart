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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: screenWidth * 0.015),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50, // Icon size remains constant
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Appointment Booked Successfully',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Doctor: $doctorName\n'
                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}\n'
                        'Time: $selectedSlot',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black54),
                  ),
                ],
              ),
            ),
            // This spacer pushes the button to the bottom
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the home page, replacing the current screen
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, screenHeight * 0.07),
                ),
                child: Text(
                  'Go Back to Home',
                  style: TextStyle(fontSize: screenWidth * 0.045),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

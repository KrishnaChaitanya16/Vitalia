import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const ReviewsPage({Key? key, required this.appointment}) : super(key: key);

  Future<void> _submitReview(BuildContext context, String review) async {
    if (review.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review cannot be empty!')),
      );
      return;
    }

    // Get the doctor's name from the appointment data
    final String doctorName = appointment['doctorName']; // Ensure 'doctorName' field exists in the appointment

    try {
      // Firestore reference to the doctor's document
      final doctorDocRef = FirebaseFirestore.instance
          .collection('doctors')  // Assuming doctors are stored in 'doctors' collection
          .where('name', isEqualTo: doctorName)  // Match the 'name' field with the doctor's name
          .limit(1);

      final querySnapshot = await doctorDocRef.get();

      if (querySnapshot.docs.isNotEmpty) {
        final doctorDoc = querySnapshot.docs.first; // Get the first document matching the query

        // Check if 'reviews' field exists and update it
        if (doctorDoc.exists) {
          // If 'reviews' field exists, add to the array
          await doctorDoc.reference.update({
            'reviews': FieldValue.arrayUnion([review]),
          });
        } else {
          // If 'reviews' doesn't exist, create it as an array and add the review
          await doctorDoc.reference.set({
            'reviews': [review],
          }, SetOptions(merge: true));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );

        Navigator.pop(context); // Go back after submitting
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController reviewController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor: ${appointment['doctorName']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _submitReview(context, reviewController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Dark blue color
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

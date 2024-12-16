import 'package:flutter/material.dart';
import '/pages/AppoinmetPage.dart';

class ResultsDisplayPage extends StatelessWidget {
  final Map specialist;

  const ResultsDisplayPage({Key? key, required this.specialist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5, // Shadow for the app bar
        shadowColor: Colors.black26,
        backgroundColor: Colors.white, // White background
        iconTheme: const IconThemeData(color: Colors.black), // Black icons (back button)
        title: Text(
          specialist['name'],
          style: const TextStyle(color: Colors.black), // Black text for title
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image or fallback image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: specialist['photos'] != null && specialist['photos'].isNotEmpty
                  ? Image.network(
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${specialist['photos'][0]['photo_reference']}&key=AIzaSyBL4yd55ZMxeZ-_tOYY_jQeIF0Gbr5zIUc',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.40,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/icons/medical-assistance.png',
                    fit: BoxFit.cover,
                    color: Colors.grey,
                  );
                },
              )
                  : Image.asset(
                'assets/icons/medical-assistance.png',
                fit: BoxFit.cover,
                color: Colors.black54.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            // Specialist Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specialist Name
                    Text(
                      specialist['name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Rating and number of reviews
                    if (specialist['rating'] != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${specialist['rating']} (${specialist['user_ratings_total'] ?? 0} reviews)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Address
                    Text(
                      specialist['vicinity'] ?? 'Address not available',
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    // Open/Closed status
                    if (specialist['opening_hours'] != null &&
                        specialist['opening_hours']['open_now'] != null)
                      Text(
                        specialist['opening_hours']['open_now']
                            ? 'Currently Open'
                            : 'Currently Closed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: specialist['opening_hours']['open_now']
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Category
                    if (specialist['types'] != null)
                      Text(
                        'Category: ${specialist['types'].join(', ')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 16),
                    // Public Reviews
                    if (specialist['reviews'] != null && specialist['reviews'].isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Public Reviews:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...specialist['reviews'].take(3).map((review) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['author_name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        review['text'] ?? 'No review text provided.',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Book Appointment Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to AppoinmetPage with parameters
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Appoinmetpage(
                        doctorName: specialist['name'] ?? 'Unknown',
                        availableSlots: [
                          '10:00 AM - 10:30 AM',
                          '11:00 AM - 11:30 AM',
                          '02:00 PM - 02:30 PM',
                          '03:30 PM - 04:00 PM',
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Book Appointment',
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

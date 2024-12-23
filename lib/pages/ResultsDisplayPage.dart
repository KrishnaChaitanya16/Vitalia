import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/pages/AppoinmetPage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ResultsDisplayPage extends StatefulWidget {
  final Map specialist;

  const ResultsDisplayPage({Key? key, required this.specialist}) : super(key: key);

  @override
  State<ResultsDisplayPage> createState() => _ResultsDisplayPageState();
}

class _ResultsDisplayPageState extends State<ResultsDisplayPage> {
  late Future<Map<String, dynamic>> specialistDetails;
  late String apiKey = "";

  @override
  void initState() {
    super.initState();
    specialistDetails = Future.value({});
    _fetchApiKey();
  }

  Future<void> _fetchApiKey() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    setState(() {
      apiKey = remoteConfig.getString('google_maps_api_key');
      // Now that apiKey is fetched, initialize specialistDetails
      specialistDetails = fetchSpecialistDetails(widget.specialist['place_id']);
    });
  }

  Future<Map<String, dynamic>> fetchSpecialistDetails(String placeId) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is not fetched from Remote Config');
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch place details: ${data['status']}');
      }
    } else {
      throw Exception('Failed to connect to Google Places API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 5,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.specialist['name'] ?? 'Specialist',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: specialistDetails,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Centering the loading indicator
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final details = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.specialist['photos'] != null &&
                            widget.specialist['photos'].isNotEmpty
                            ? Image.network(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${widget.specialist['photos'][0]['photo_reference']}&key=$apiKey',
                          fit: BoxFit.cover,
                          height: MediaQuery.of(context).size.height * 0.40,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.specialist['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (widget.specialist['rating'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.specialist['rating']} (${widget.specialist['user_ratings_total'] ?? 0} reviews)',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Text(
                              widget.specialist['vicinity'] ??
                                  'Address not available',
                              style: const TextStyle(
                                  fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 16),
                            if (details['reviews'] != null &&
                                details['reviews'].isNotEmpty) ...[
                              const Text(
                                'Public Reviews:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: details['reviews'].length,
                                  itemBuilder: (context, index) {
                                    final review = details['reviews'][index];
                                    return Container(
                                      width: 300,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: Card(
                                        elevation: 4,
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundImage: NetworkImage(
                                                        review['profile_photo_url'] ??
                                                            ''),
                                                    radius: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      review['author_name'] ??
                                                          'Anonymous',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                          FontWeight.bold),
                                                      overflow:
                                                      TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  ...List.generate(
                                                    review['rating'] ?? 0,
                                                        (index) => const Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: Colors.amber),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: Text(
                                                  review['text'] ??
                                                      'No review text provided.',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Appoinmetpage(
                        doctorName: widget.specialist['name'] ?? 'Unknown',
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
          ),
        ],
      ),
    );
  }
}

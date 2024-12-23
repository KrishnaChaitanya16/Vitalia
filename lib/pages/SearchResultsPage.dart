import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'ResultsDisplayPage.dart'; // Import the ResultsDisplayPage

class SearchResultsPage extends StatefulWidget {
  final String query;

  SearchResultsPage({required this.query});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  Position? _currentPosition;
  TextEditingController _searchController = TextEditingController();
  String apiKey = ""; // Variable to store the API key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.text = widget.query; // Set initial value
    _fetchApiKey(); // Fetch the API key from Firebase Remote Config
  }

  Future<void> _fetchApiKey() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      setState(() {
        apiKey = remoteConfig.getString('google_maps_api_key');
      });
    } catch (e) {
      _showError("Failed to fetch API key.");
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showError("Location permission is required.");
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _fetchSearchResults();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("An error occurred while fetching location.");
    }
  }

  Future<void> _fetchSearchResults() async {
    if (_currentPosition == null || apiKey.isEmpty) return;

    final String query = _searchController.text.trim();
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['results'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to fetch results. Please try again later.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('An error occurred. Please check your internet connection.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Search Results for "${widget.query}"',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) {
                setState(() {
                  _isLoading = true;
                });
                _fetchSearchResults();
              },
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
            child: Text(
              'No results found for "${_searchController.text}".',
              style: GoogleFonts.nunito(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(1),
                        child: Icon(Icons.local_hospital, color: Colors.red),
                      ),
                      title: Text(
                        result['name'] ?? 'No title available',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        result['vicinity'] ?? 'No address available',
                        style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
                      ),
                      onTap: () {
                        // Navigate to ResultsDisplayPage on tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultsDisplayPage(
                              specialist: result, // Pass the selected specialist details
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

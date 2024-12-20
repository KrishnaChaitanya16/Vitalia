import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

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

  // Replace with your Google API Key
  final String apiKey = 'AIzaSyBL4yd55ZMxeZ-_tOYY_jQeIF0Gbr5zIUc';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.text = widget.query; // Set initial value
  }

  // Get current user location using Geolocator
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request location permission and get the current position
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showError("Location permission is required.");
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Fetch search results after getting the location
      _fetchSearchResults();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("An error occurred while fetching location.");
    }
  }

  // Fetch search results using Google Places API
  Future<void> _fetchSearchResults() async {
    if (_currentPosition == null) return;

    final String query = _searchController.text.trim(); // Get query from search bar
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    // Construct the URL for Google Places API (Nearby Search)
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

  // Show error message in case of failure
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
      backgroundColor: Colors.white, // Set entire background to white
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
                // Trigger search when the user submits a query
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
                    color: Colors.white, // Set card color to white
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
                        // Open result link in Google Maps or browser
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Open Link'),
                            content: Text('Open ${result['place_id']}?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Handle opening the place in Google Maps
                                  Navigator.pop(context);
                                },
                                child: const Text('Open'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
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

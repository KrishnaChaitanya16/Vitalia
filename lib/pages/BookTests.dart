import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Add Remote Config import
import '/pages/Testspage.dart'; // Import the Testspage

class Booktests extends StatefulWidget {
  const Booktests({super.key});

  @override
  State<Booktests> createState() => _BooktestsState();
}

class _BooktestsState extends State<Booktests> {
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  Position? _currentPosition;
  TextEditingController _searchController = TextEditingController();

  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
  }

  Future<void> _initializeRemoteConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize and fetch Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();

      // Get the API key
      _apiKey = remoteConfig.getString('google_maps_api_key');

      // Fetch current location and search results
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Failed to initialize Remote Config: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
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
    if (_currentPosition == null || _apiKey == null) return;

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=diagnostic+center&key=$_apiKey';

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
          'Book a Test',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE3F2FD),  Color(0xFFBBDEFB)])
        ),
          child:Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for Diagnostic Centers',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
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
              'No results found.',
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
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          "assets/icons/test.png",
                          color: Colors.blue,
                          height: 25,
                          width: 25,
                        ),
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
                        // Navigate to Testspage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Testspage(diagnosticCenter: result),
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
      )),
    );
  }
}

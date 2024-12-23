import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({Key? key}) : super(key: key);

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'https://www.googleapis.com/auth/cloud-healthcare',
  ]);
  GoogleSignInAccount? _currentUser;

  late String fullName = 'Unknown';
  late String email = 'Unknown';
  late String gender = 'Unknown';
  late String dob = 'Unknown';
  List<Map<String, dynamic>> _uploadedRecords = [];
  bool _isLoading = true;
  String baseUrl="";

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _initializeRemoteConfig();
  }

  Future<void> _initializeUserData() async {
    setState(() => _isLoading = true);
    try {
      await _getUserProfile();
      await _fetchPatientRecords();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not logged in');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final userData = snapshot.data()!;
        fullName = userData['fullName'] ?? 'Unknown';
        email = userData['email'] ?? 'Unknown';
        gender = userData['gender'] ?? 'Unknown';
        dob = userData['dob'] ?? 'Unknown';
      } else {
        _showSnackBar('User data not found in Firestore');
      }
    } catch (e) {
      _showSnackBar('Error fetching user data: $e');
    }
  }
  Future<void> _initializeRemoteConfig() async {
    try {
      FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch every time
      ));
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(<String, dynamic>{
        'baseUrl': 'default_api_key', // Set a default API key (optional)
      });
      final fetchStatus = await remoteConfig.fetchAndActivate();
      print("Fetch status: $fetchStatus");
      baseUrl = remoteConfig.getString('baseurl');

      if (baseUrl == null || baseUrl!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key
      _fetchPatientRecords();
    } catch (e) {
      print("Failed to fetch API key from Remote Config.");
    }
  }

    Future<void> _fetchPatientRecords() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) {
        _showSnackBar("Sign-in failed");
        return;
      }
    }

    final token = await _currentUser!.authentication;

    if (token.accessToken == null) {
      print('Access token is null');
      return;
    }

    final authClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken('Bearer', token.accessToken!,
            DateTime.now().toUtc().add(const Duration(hours: 1))),
        '',
        _googleSignIn.scopes,
      ),
    );


    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception("Firebase user not found");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!userDoc.exists) throw Exception("User document not found");

      final userName = userDoc.data()?['fullName'] ?? '';
      if (userName.isEmpty) throw Exception("User name not found");

      // Fetch Patient resource
      final patientResponse =
      await authClient.get(Uri.parse('$baseUrl/Patient?name=$userName'));
      if (patientResponse.statusCode != 200) {
        throw Exception("Failed to fetch Patient. Status code: ${patientResponse.statusCode}");
      }

      final patientData = json.decode(patientResponse.body);
      final entries = patientData['entry'] ?? [];
      if (entries.isEmpty) {
        throw Exception("No Patient record found for name $userName");
      }

      final patientResource = entries[0]['resource'];
      final patientRef = patientResource['id'];
      if (patientRef == null) throw Exception("Patient reference ID not found");

      // Fetch MedicationRequest resources
      final medicationRequestUrl =
          '$baseUrl/MedicationRequest?subject=Patient/$patientRef';
      final medicationResponse = await authClient.get(Uri.parse(medicationRequestUrl));

      if (medicationResponse.statusCode != 200) {
        throw Exception("Failed to fetch MedicationRequest. Status code: ${medicationResponse.statusCode}");
      }

      final medicationData = json.decode(medicationResponse.body);
      final requests = medicationData['entry'] ?? [];

      List<Map<String, dynamic>> medications = [];
      for (var entry in requests) {
        final request = entry['resource'];
        medications.add({
          'medicationName': request['medicationCodeableConcept']?['coding']?[0]?['display'] ?? 'Unknown Medication',
          'dosage': request['dosageInstruction']?[0]?['text'] ?? 'Unknown Dosage',
          'startDate': request['authoredOn'] ?? 'Unknown Date',
        });
      }

      setState(() {
        _uploadedRecords = [
          {
            'patientRef': patientRef,
            'name': userName,
            'birthDate': patientResource['birthDate'] ?? 'Unknown Date',
            'medications': medications,
          }
        ];
      });

      _showSnackBar("Patient details fetched successfully");
    } catch (e) {
      print("Error fetching patient records: $e");
      _showSnackBar("Error fetching patient records: $e");
    }
  }

  Future<void> _signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      setState(() {
        _currentUser = account;
      });
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildDetail('Full Name', fullName),
            _buildDetail('Email', email),
            _buildDetail('Gender', gender),
            _buildDetail('Date of Birth', dob),
            const Divider(),
            const Text('Uploaded Records', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._uploadedRecords.map((record) => _buildDetail(
              'Medication',
              record['medications']
                  .map((m) => m['medicationName'])
                  .join(', '),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

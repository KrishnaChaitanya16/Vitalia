import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHealthPage extends StatefulWidget {
  const MyHealthPage({super.key});

  @override
  State<MyHealthPage> createState() => _MyHealthPageState();
}

class _MyHealthPageState extends State<MyHealthPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _uploadedRecords = [];
  List<Map<String, String>> _uploadedFiles = [];
  List<Map<String, String>> _uploadedFilesP = [];
  late PageController _pageController;
  double _indicatorPosition = 0;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );

  GoogleSignInAccount? _currentUser;


  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
      if (account != null) {
        _fetchPatientRecords();
        _fetchUploadedFiles();
        _fetchUploadedFilesP();
      }
    });
    _googleSignIn.signInSilently();
    _initializeRemoteConfig();
    _fetchPatientRecords();
  }
  String? baseUrl;
  String api1="";
  String api2="";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      print("Error signing in: $e");
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

      baseUrl = remoteConfig.getString('baseurl');

      if (baseUrl == null || baseUrl!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key
      _fetchPatientRecords();
    } catch (e) {


    }


    try {
      FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch every time
      ));
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(<String, dynamic>{
        'api': 'default_api_key', // Set a default API key (optional)
      });
      final fetchStatus = await remoteConfig.fetchAndActivate();

      api1 = remoteConfig.getString('apiurl1');

      if (api1 == null || api1!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key
      _fetchPatientRecords();
    } catch (e) {


    }
    try {
      FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch every time
      ));
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(<String, dynamic>{
        'api2': 'default_api_key', // Set a default API key (optional)
      });
      final fetchStatus = await remoteConfig.fetchAndActivate();
      print("Fetch status: $fetchStatus");
      api2 = remoteConfig.getString('apiurl2');

      if (api2 == null || api2!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key
      _fetchPatientRecords();
    } catch (e) {


    }
  }


  Future<void> _fetchPatientRecords() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in failed")),
        );
        return;
      }
    }

    final token = await _currentUser!.authentication;
    print(token);

    if (token.accessToken == null) {

      return;
    }
    print(token.accessToken);

    final authClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken('Bearer', token.accessToken!, DateTime.now().toUtc().add(Duration(hours: 1))),
        '',
        _googleSignIn.scopes,
      ),
    );




    try {
      // Step 1: Get the current Firebase user to fetch their UID
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception("Firebase user not found. Make sure the user is signed in.");
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        throw Exception("User document not found in Firestore");
      }

      final userData = userDoc.data();
      final userName = userData?['fullName'];
      if (userName == null || userName.isEmpty) {
        throw Exception("User name not found in Firestore");
      }

      // Step 2: Fetch the Patient resource matching the user's name
      final patientResponse = await authClient.get(Uri.parse('$baseUrl/Patient?name=$userName'));
      if (patientResponse.statusCode != 200) {
        throw Exception("Failed to fetch Patient resource");
      }

      final patientData = json.decode(patientResponse.body);
      final entries = patientData['entry'] ?? [];
      if (entries.isEmpty) {
        throw Exception("No Patient record found for the name $userName");
      }

      // Assuming the first entry corresponds to the current user
      final patientRef = entries[0]['resource']['id'];
      if (patientRef == null) {
        throw Exception("Patient reference not found for the current user");
      }

      // Step 3: Fetch medication requests for the identified patient
      final medicationRequestUrl = '$baseUrl/MedicationRequest?subject=Patient/$patientRef';
      final response = await authClient.get(Uri.parse(medicationRequestUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final requests = data['entry'] ?? [];

        List<Map<String, dynamic>> medications = [];
        for (var entry in requests) {
          final request = entry['resource'];
          medications.add({
            'medicationName': request['medicationCodeableConcept']?['coding']?[0]?['display'] ?? 'Unknown Medication',
            'dosage': request['dosageInstruction']?[0]?['text'] ?? 'Unknown Dosage',
            'startDate': request['authoredOn'] ?? 'Unknown Date',
          });
        }

        // Step 4: Update the state with fetched medications
        setState(() {
          _uploadedRecords = [
            {
              'patientRef': patientRef,
              'name': userName,
              'birthDate': entries[0]['resource']['birthDate'] ?? 'Unknown Date',
              'medications': medications,
            }
          ];
        });


      } else {
        throw Exception("Failed to fetch medication requests for the current user");
      }
    } catch (e) {


    }
  }

  Future<void> _fetchUploadedFiles() async {
    try {
      // Google Sign-In to get the authentication token
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {

        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String accessToken = googleAuth.accessToken ?? '';

      if (accessToken.isEmpty) {

        return;
      }

      // Correct API URL for fetching files from the bucket
      final apiUrl = 'https://storage.googleapis.com/storage/v1/b/health_care_bucket_10/o';

      // Send GET request to list the objects in the bucket
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );


      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> items = jsonResponse['items'] ?? [];

        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No files found in the bucket")),
          );
          return;
        }

        List<Map<String, String>> fileRecords = items.map((item) {
          return {
            'fileName': item['name'] as String,
            'uploadDate': item['timeCreated'] as String,
            'mediaLink': item['mediaLink'] as String,
            'cloudPath': item['name'] as String,
          };
        }).toList();

        setState(() {
          _uploadedFiles = fileRecords; // Update your state with fetched files
        });
      } else {


      }
    } catch (e) {


    }
  }

  Future<void> _fetchUploadedFilesP() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In failed")),
        );
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String accessToken = googleAuth.accessToken ?? '';

      if (accessToken.isEmpty) {

        return;
      }



      final response = await http.get(
        Uri.parse(api2),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<dynamic> items = jsonResponse['items'] ?? [];
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No files found in the bucket")),
          );
          return;
        }

        List<Map<String, String>> fileRecords = items.map((item) {
          return {
            'fileName': item['name'] as String,
            'uploadDate': item['timeCreated'] as String,
            'mediaLink': item['mediaLink'] as String,
            'cloudPath': item['name'] as String,

          };
        }).toList();

        setState(() {
          _uploadedFilesP = fileRecords;
        });
      } else {


      }
    } catch (e) {

    }
  }

  Future<void> _uploadPdfToGoogleCloudStorage() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in failed")),
        );
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    var file = result.files.single;
    String? filePath = file.path;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File path is null, upload failed")),
      );
      return;
    }

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';

    final token = await _currentUser!.authentication;
    final apiUrl =
        'https://storage.googleapis.com/upload/storage/v1/b/health_care_bucket_10/o?uploadType=media&name=$fileName';

    try {
      var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
      if (fileBytes.isEmpty) {

        return;
      }



      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/pdf',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF uploaded successfully")),
        );
        _fetchUploadedFiles();
      } else {

      }
    } catch (e) {

    }
  }

  Future<void> _uploadPdfToGoogleCloudStorageP() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in failed")),
        );
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    var file = result.files.single;
    String? filePath = file.path;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File path is null, upload failed")),
      );
      return;
    }

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';

    final token = await _currentUser!.authentication;
    final apiUrl =
        '${api2}?uploadType=media&name=$fileName';

    try {
      var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/pdf',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF uploaded successfully")),
        );
        _fetchUploadedFilesP();
      } else {

      }
    } catch (e) {

    }
  }

  void _navigateToAddMedicationPage() async {
    if (_currentUser != null) {
      final token = await _currentUser!.authentication;
      final accessToken = token.accessToken ?? '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMedicationPage(
            accessToken: accessToken,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User is not signed in"))
      );
    }
  }

  Widget _buildPageContent(String type) {
    List<Map<String, dynamic>> records = [];

    switch (type.toLowerCase()) {
      case "medication":
        records = _uploadedRecords;
        break;
      case "report":
        records = _uploadedFiles.map((file) => {
          'fileName': file['fileName'],
          'uploadDate': file['uploadDate'],
          'mediaLink': file['mediaLink'],
        }).toList();
        break;
      case "prescription":
        records = _uploadedFilesP.map((file) => {
          'fileName': file['fileName'],
          'uploadDate': file['uploadDate'],
          'mediaLink': file['mediaLink'],
        }).toList();
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: records.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "No ${type.toLowerCase()} records found",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent
              ),
              onPressed: () {
                if (type.toLowerCase() == "medication") {
                  _navigateToAddMedicationPage();
                } else if (type.toLowerCase() == "report") {
                  _uploadPdfToGoogleCloudStorage();
                } else {
                  _uploadPdfToGoogleCloudStorageP();
                }
              },
              child: Text("Add ${type}", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Dismissible(
            key: Key(record['fileName'] ?? ''),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              if (type.toLowerCase() == "medication") {
                // Assuming the medication has a unique identifier, such as 'id'.
                print(record.toString());

                final medications = record['medications'] as List?;
                if (medications != null && medications.isNotEmpty) {
                  final medication = medications[0]; // Assuming you want the first medication
                  final medicationName = medication['medicationName'];  // Get the medication name

                  if (medicationName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Medication details are missing")),
                    );
                    return;
                  }

                  // If you don't have a medicationId, use medicationName as identifier
                  print("Deleting medication: $medicationName");

                  // Perform deletion (use medicationName as the ID or unique identifier)
                  setState(() {
                    records.removeAt(index);
                  });

                  bool success = await _deleteMedication(medicationName);  // Using medicationName for deletion
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Medication deleted successfully")),
                    );
                  } else {
                    setState(() {
                      records.insert(index, record);  // Reinsert the record if deletion fails
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete medication")),
                    );
                  }
                }
              } else {
                // If it's not a medication, proceed to delete the file
                String? cloudPath = record['cloudPath'];
                setState(() {
                  records.removeAt(index); // Remove the record from the list
                });

                if (cloudPath != null) {
                  bool success = await _deleteFileFromCloud(cloudPath);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("File deleted successfully")),
                    );
                  } else {
                    setState(() {
                      records.insert(index, record); // Reinsert the record if deletion fails
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete file")),
                    );
                  }
                }
              }
            },
            child: GestureDetector(
              onTap: () => _previewFile(record),
              child: type.toLowerCase() == "medication"
                  ? Card(
                color:Color.fromRGBO(215, 236, 252, 1),
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication, color: Colors.blue, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              record['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Ongoing',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (record['medications'] != null)
                        ...(record['medications'] as List).map((med) {
                          // Debug print

                          return Column(

                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(height: 24),
                              Row(

                                children: [
                                  Expanded(

                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${med['medicationName']} ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: med['details'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildTimingIndicator(
                                    med['dosage']
                                        .contains('Morning'),
                                    Icons.wb_sunny,
                                    med['dosage'] ?? '10ml',
                                  ),
                                  _buildTimingIndicator(
                                    med['dosage']
                                        .contains('Afternoon'),
                                    Icons.wb_sunny,
                                    med['dosage'] ?? '10ml',
                                  ),
                                  _buildTimingIndicator(
                                    med['dosage']
                                        .contains('Evening'),
                                    Icons.wb_twilight,
                                    med['dosage'] ?? '10ml',
                                  ),
                                  _buildTimingIndicator(
                                    med['dosage']
                                        .contains('Night'),
                                    Icons.nightlight_round,
                                    med['dosage'] ?? '10ml',
                                  ),
                                  Spacer(),
                                  Text(
                                    med['dosage']?.contains('After Food') ?? false
                                        ? 'After Food'
                                        : 'Before Food',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // Dosage Information
                              Text(
                                'Dosage: ${med['dosage'] ?? '10ml'}, ${med['frequency'] ?? 'four times a day'}, ${med['duration'] ?? 'for 5 days'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
              )

                  : Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    _getFileIcon(record['fileName'] ?? ''),
                    color: Colors.blue,
                    size: 40,
                  ),
                  title: Text(
                    record['fileName'] ?? 'Unknown File',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Uploaded: ${record['uploadDate']}"),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeChip(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: color.withOpacity(0.8),
          child: Icon(
            icon,
            size: 18, // Increased size for better visibility
            color: Colors.white, // Ensure the icon contrasts with the background
          ),
        ),
        label: Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: 14), // Clearer text
        ),
        backgroundColor: color.withOpacity(0.2), // Softer background color
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
  Widget _buildTimingIndicator(bool? isActive, IconData icon, String dose) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive == true ? Colors.orange : Colors.grey,
            size: 26,
          ),
          SizedBox(height: 4),

        ],
      ),
    );
  }


  Future<void> _previewFile(Map<String, dynamic> record) async {
    String? mediaLink = record['mediaLink'];
    if (mediaLink != null && mediaLink.isNotEmpty) {
      try {
        final Uri url = Uri.parse(mediaLink);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open the file")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening the file: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No media link available")),
      );
    }
  }
  Future<bool> _deleteMedication(String medicationName) async {
    final token = await _currentUser!.authentication;

    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed")),
      );
      return false;
    }

    // Step 1: Search for the medication in the FHIR store using medicationName
    final searchUrl =
        'https://healthcare.googleapis.com/v1/projects/healthcaremapapp-444513/locations/us-central1/datasets/health_records/fhirStores/my_fhir_store/fhir/MedicationRequest?medication=$medicationName';

    try {
      final searchResponse = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/fhir+json',
        },
      );

      if (searchResponse.statusCode == 200) {
        final searchBody = json.decode(searchResponse.body);

        // Check if the medication exists and extract its ID
        final medicationId = searchBody['entry']?[0]?['resource']?['id'];

        if (medicationId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Medication ID not found")),
          );
          return false;
        }

        // Step 2: Construct the delete URL for the medication by its ID
        final deleteUrl =
            'https://healthcare.googleapis.com/v1/projects/healthcaremapapp-444513/locations/us-central1/datasets/health_records/fhirStores/my_fhir_store/fhir/MedicationRequest/$medicationId';

        // Send DELETE request to remove the medication
        final deleteResponse = await http.delete(
          Uri.parse(deleteUrl),
          headers: {
            'Authorization': 'Bearer ${token.accessToken}',
            'Content-Type': 'application/fhir+json',
          },
        );

        // Check the response status code
        if (deleteResponse.statusCode == 204) {
          print("Medication deleted successfully");
          return true;
        } else {
          print("Failed to delete medication: ${deleteResponse.statusCode}");
          print("Response Body: ${deleteResponse.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete medication")),
          );
          return false;
        }
      } else {
        print("Failed to find medication: ${searchResponse.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medication search failed")),
        );
        return false;
      }
    } catch (e) {
      print("Error deleting medication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while deleting medication")),
      );
      return false;
    }
  }

  Future<bool> _deleteFileFromCloud(String fileName) async {
    final token = await _currentUser!.authentication;

    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed")),
      );
      return false;
    }

    // URL-encode the file name
    final encodedFileName = Uri.encodeComponent(fileName);
    final deleteUrl =
        'https://storage.googleapis.com/storage/v1/b/health_care_bucket_10/o/$encodedFileName';

    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
        },
      );

      if (response.statusCode == 204) {
        print("File deleted successfully");
        return true;
      } else {
        print("Failed to delete file: ${response.statusCode}");
        print("Response Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting file: $e");
      return false;
    }
  }


  void _showFilePreviewDialog(String fileName, String fileUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Preview: $fileName"),
          content: fileUrl.isNotEmpty
              ? Image.network(fileUrl) // Show image preview for non-PDF files
              : const Text("No preview available."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) return Icons.image;
    if (fileName.endsWith('.txt')) return Icons.description;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Health Records",
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildCustomTabBar(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _indicatorPosition = index.toDouble());
        },
        children: [
          _buildPageContent("medication"),
          _buildPageContent("report"),
          _buildPageContent("prescription"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        onPressed: () {
          switch (_indicatorPosition.toInt()) {
            case 0:
              _navigateToAddMedicationPage();
              break;
            case 1:
              _uploadPdfToGoogleCloudStorage();
              break;
            case 2:
              _uploadPdfToGoogleCloudStorageP();
              break;
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("Medication", 'assets/icons/medicine.png', 0),
          _buildTabItem("Reports", 'assets/icons/test.png', 1),
          _buildTabItem("Prescriptions", 'assets/icons/prescription.png', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String iconPath, int index) {
    bool isSelected = _indicatorPosition == index.toDouble();

    return GestureDetector(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24, fit: BoxFit.contain),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}






class AddMedicationPage extends StatefulWidget {
  final String accessToken;

  const AddMedicationPage({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  _AddMedicationPageState createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();

  final _patientNameController = TextEditingController();

  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  bool _isLoading = false;

  String _selectedUnit = 'tablet'; // Default dosage unit
  final List<String> _dosageUnits = ['tablet', 'mg', 'ml', 'capsule'];
  final List<String> _timeOfDayOptions = ['Morning', 'Afternoon', 'Evening', 'Night'];
  final List<String> _beforeAfterFoodOptions = ['Before Food', 'After Food'];

  List<String> _selectedTimeOfDay = [];  // Default time of day
  String _selectedBeforeAfterFood = 'Before Food';
  List<String> _availableTimes = [];
  void _updateAvailableTimes() {
    final int? frequency = int.tryParse(_frequencyController.text);
    if (frequency != null) {
      if (frequency == 1) {
        _availableTimes = ['Morning'];
      } else if (frequency == 2) {
        _availableTimes = ['Morning', 'Evening'];
      } else if (frequency == 3) {
        _availableTimes = ['Morning', 'Afternoon', 'Evening'];
      } else {
        _availableTimes = ['Morning', 'Afternoon', 'Evening', 'Night'];
      }
    }
  }
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final patientId = await _createPatient();
      if (patientId == null) {
        throw Exception('Failed to create patient');
      }

      await _createMedicationRequest(patientId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication saved successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving medication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save medication')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createMedicationRequest(String patientId) async {
    final medicationRequestUrl = 'https://healthcare.googleapis.com/v1/projects/healthcaremapapp-444513/locations/us-central1/datasets/health_records/fhirStores/my_fhir_store/fhir/MedicationRequest';

    final medicationRequest = {
      "resourceType": "MedicationRequest",
      "status": "active",
      "intent": "order",
      "subject": {
        "reference": "Patient/$patientId"
      },
      "medicationCodeableConcept": {
        "text": _medicationNameController.text,
        "coding": [
          {
            "system": "http://snomed.info/sct",
            "display": _medicationNameController.text
          }
        ]
      },
      "dosageInstruction": [
        {
          "text": "${_dosageController.text} ${_selectedTimeOfDay.join(', ')}, ${_selectedBeforeAfterFood}",
          "timing": {
            "repeat": {
              "frequency": 1,
              "period": 1,
              "periodUnit": "d"
            }
          }
        }
      ],
      "requester": {
        "reference": "Patient/$patientId"
      },
      "authoredOn": DateTime.now().toUtc().toIso8601String().split('.').first + "Z",
      "priority": "routine"
    };

    final response = await http.post(
      Uri.parse(medicationRequestUrl),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Content-Type': 'application/fhir+json',
      },
      body: json.encode(medicationRequest),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create medication request: ${response.statusCode}\nResponse: ${response.body}');
    }
  }

  Future<String?> _createPatient() async {
    final patientUrl = 'https://healthcare.googleapis.com/v1/projects/healthcaremapapp-444513/locations/us-central1/datasets/health_records/fhirStores/my_fhir_store/fhir/Patient';

    final nameParts = _patientNameController.text.split(' ');
    final given = nameParts.first;
    final family = nameParts.length > 1 ? nameParts.last : '';

    final patientResource = {
      "resourceType": "Patient",
      "name": [
        {
          "use": "official",
          "given": [given],
          "family": family,
          "text": _patientNameController.text
        }
      ],
      "active": true,
      "gender": "unknown",  // Optional, can be dynamically set if needed
      "identifier": [
        {
          "system": "http://example.org/identifiers",
          "value": "patient-${DateTime.now().millisecondsSinceEpoch}"
        }
      ]
    };

    final response = await http.post(
      Uri.parse(patientUrl),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Content-Type': 'application/fhir+json',
      },
      body: json.encode(patientResource),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData['id'];
    } else {
      throw Exception('Failed to create patient: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        elevation: 4, // Add shadow to AppBar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicationNameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dosage field
              TextFormField(
                controller: _dosageController,  // Bind controller here
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g. 1 tablet)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency (e.g. 1, 2, 3, etc.)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _updateAvailableTimes();  // Update available times based on frequency
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Display time selection based on frequency
              ..._timeOfDayOptions.map((time) {
                return CheckboxListTile(
                  title: Text(time),
                  value: _selectedTimeOfDay.contains(time),
                  onChanged: (bool? selected) {
                    setState(() {
                      // Allow selection if the limit is not reached
                      if (selected == true && _selectedTimeOfDay.length < int.parse(_frequencyController.text)) {
                        _selectedTimeOfDay.add(time);
                      } else if (selected == false) {
                        _selectedTimeOfDay.remove(time);
                      }
                    });
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
              // Food timing selection (before or after food)
              DropdownButtonFormField<String>(
                value: _selectedBeforeAfterFood,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBeforeAfterFood = newValue!;
                  });
                },
                items: _beforeAfterFoodOptions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Before or After Food',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveMedication,
                child: const Text('Save Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _patientNameController.dispose();
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }
}

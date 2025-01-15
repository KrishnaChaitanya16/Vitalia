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
    try {
      // Step 1: Get current Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please sign in to view records")),
        );
        return;
      }

      // Step 2: Fetch user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User profile not found")),
        );
        return;
      }

      final userData = userDoc.data()!;
      final userName = userData['fullName'] as String?;
      final birthDate = userData['birthDate'] as String?;

      if (userName == null || userName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User profile incomplete")),
        );
        return;
      }

      // Step 3: Fetch medication requests for the user
      final currentUserDocId = firebaseUser.uid;

      final medicationSnapshot = await FirebaseFirestore.instance
          .collection('medicationRequests') // Access the medicationRequests collection directly
          .where('patientId', isEqualTo: currentUserDocId) // Filter by patientId
          // Order by authoredOn
          .get();


      List<Map<String, dynamic>> medications = [];

      for (var doc in medicationSnapshot.docs) {
        final data = doc.data();
        print("Data is :${data}");
        medications.add({
          'medicationName': data['medicationInfo']['name'] ?? 'Unknown Medication',
          'dosage': data['dosageInstruction']['text'] ?? 'Unknown Dosage',
          'startDate': data['authoredOn'] ?? 'Unknown Date',
          'status': data['status'] ?? 'active',
          'prescriber': data['prescriber'] ?? 'Unknown',
          'medicationId': doc.id,
        });
      }
      print("Medications: ${medications}");

      // Step 4: Update the state with fetched data
      setState(() {
        _uploadedRecords = [
          {
            'patientRef': firebaseUser.uid,
            'name': userName,
            'birthDate': birthDate ?? 'Unknown Date',
            'medications': medications,
          }
        ];
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching records: ${e.toString()}")),
      );
    }
  }

  Future<void> _fetchUploadedFiles() async {
    try {
      // Google Sign-In to get the authentication token
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User cancelled sign-in
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String accessToken = googleAuth.accessToken ?? '';
      String userEmail = googleUser.email;

      if (accessToken.isEmpty) {
        return; // Failed to get the access token
      }

      // Define the folder name for the user (using email as the folder name)
      final userFolder = Uri.encodeComponent(userEmail);

      // Correct API URL for fetching files from the user's folder in the bucket
      final apiUrl =
          'https://storage.googleapis.com/storage/v1/b/health_care_bucket_10/o?prefix=$userFolder/';

      // Send GET request to list the objects in the user's folder
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
            const SnackBar(content: Text("No files found in your folder")),
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
          _uploadedFiles = fileRecords; // Update state with fetched files
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch files: ${response.statusCode} - ${response.reasonPhrase}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  Future<void> _fetchUploadedFilesP() async {
    try {
      // Ensure the user is signed in
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Access token is empty")),
        );
        return;
      }

      // Current user's folder (use email or a unique identifier)
      String userFolder = googleUser.email ?? 'anonymous_user';

      // Fetch all files from the bucket (updated API URL)
      final response = await http.get(
        Uri.parse('https://storage.googleapis.com/storage/v1/b/health_car_bucket_11/o'), // Updated API URL
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

        // Filter files to include only those in the user's folder
        List<Map<String, String>> fileRecords = items
            .where((item) => item['name'].toString().startsWith(userFolder))
            .map((item) {
          return {
            'fileName': item['name'] as String,
            'uploadDate': item['timeCreated'] as String,
            'mediaLink': item['mediaLink'] as String,
            'cloudPath': item['name'] as String,
          };
        }).toList();

        // Check if there are any files for the user
        if (fileRecords.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No files found for the current user")),
          );
          return;
        }

        // Update the state with the filtered files
        setState(() {
          _uploadedFilesP = fileRecords;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to fetch files: ${response.statusCode} - ${response.reasonPhrase}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }


  Future<void> _uploadPdfToGoogleCloudStorage() async {
    if (_currentUser == null) {
      await _signIn(); // Sign-in logic
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in failed")),
        );
        return;
      }
    }

    // Let user pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'docx'],
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

    // Get user's email or a unique identifier
    String userFolder = _currentUser!.email ?? 'anonymous_user';
    String fileName = '$userFolder/${DateTime.now().millisecondsSinceEpoch}.pdf';

    final token = await _currentUser!.authentication;

    // API URL to upload file with the user's folder included in the path
    final apiUrl =
        'https://storage.googleapis.com/upload/storage/v1/b/health_care_bucket_10/o?uploadType=media&name=$fileName';

    try {
      // Get file bytes
      var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
      if (fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File is empty, upload failed")),
        );
        return;
      }

      // Send POST request to upload the PDF
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

        // Refresh the list of uploaded files
        _fetchUploadedFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to upload PDF: ${response.statusCode} - ${response.reasonPhrase}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
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

    // Pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'docx'],
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

    // Use the user's email as the folder name or fallback to "anonymous_user"
    String userFolder = _currentUser!.email ?? 'anonymous_user';
    String fileName = '$userFolder/${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

    // Ensure `api2` is properly initialized and valid
    final token = await _currentUser!.authentication;
    final apiUrl = 'https://storage.googleapis.com/upload/storage/v1/b/health_car_bucket_11/o?uploadType=media&name=$fileName';

    try {
      // Read file bytes
      var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

      // Upload the file to the bucket
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/pdf',  // You may want to adjust this for other file types
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File uploaded successfully")),
        );

        // Refresh the list of uploaded files
        _fetchUploadedFilesP();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to upload file: ${response.statusCode} - ${response.reasonPhrase}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  void _navigateToAddMedicationPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationPage(

        ),
      ),
    );
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
                              record['medications'] == null || record['medications'].isEmpty
                                  ? 'No Medications Yet'
                                  : 'Ongoing',
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
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User email not found")),
          );
        }
        return false;
      }

      // First get the user's document ID from users collection
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not found in database")),
          );
        }
        return false;
      }

      final userDoc = userQuery.docs.first.id;

      // Query the top-level medicationrequests collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('medicationRequests')
          .where('userId', isEqualTo: userDoc)
          .where('medicationInfo.name', isEqualTo: medicationName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Medication not found")),
          );
        }
        return false;
      }

      // Delete the medication document from medicationrequests collection
      await FirebaseFirestore.instance
          .collection('medicationRequests')
          .doc(querySnapshot.docs.first.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medication deleted successfully")),
        );
      }
      return true;

    } catch (e) {
      print("Error deleting medication: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete medication: ${e.toString()}")),
        );
      }
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


  const AddMedicationPage({
    Key? key,

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }
      final fullName = userDoc['fullName'];

      final patientId = await _createPatient(fullName: fullName);
      if (patientId == null) {
        throw Exception('Failed to create patient');
      }

      await _createMedicationRequest(medicationName: _medicationNameController.text,dosage:_dosageController.text,timeOfDay:_selectedTimeOfDay,beforeAfterFood:_selectedBeforeAfterFood,medicationNameController:_medicationNameController,dosageController:_dosageController);

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

  Future<void> _createMedicationRequest({
    required String medicationName,
    required String dosage,
    required List<String> timeOfDay,
    required String beforeAfterFood,
    required TextEditingController medicationNameController,
    required TextEditingController dosageController,
  }) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create medication request document
      final medicationRequest = {
        'resourceType': 'MedicationRequest',
        'status': 'active',
        'intent': 'order',
        'patientId': user.uid,
        'medicationInfo': {
          'name': medicationNameController.text,
          'coding': {
            'system': 'http://snomed.info/sct',
            'display': medicationNameController.text
          }
        },
        'dosageInstruction': {
          'text': '${dosageController.text} ${timeOfDay.join(', ')}, $beforeAfterFood',
          'timing': {
            'frequency': 1,
            'period': 1,
            'periodUnit': 'day'
          },
          'dosage': dosageController.text,
          'timeOfDay': timeOfDay,
          'foodTiming': beforeAfterFood
        },
        'requester': {
          'id': user.uid,
          'name': user.displayName ?? 'Unknown'
        },
        'authoredOn': FieldValue.serverTimestamp(),
        'priority': 'routine',
        'lastUpdated': FieldValue.serverTimestamp()
      };

      // Add to Firestore
      await _firestore
          .collection('medicationRequests')
          .add({
        ...medicationRequest,
        'userId': user.uid,
      });
      // Optionally, also add to a separate collection for all medication requests
      // This can be useful for admin tracking or analytics


    } catch (e) {
      throw Exception('Failed to create medication request: $e');
    }
  }


  Future<String> _createPatient({
    required String fullName,
    String gender = 'unknown',
  }) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Split name into given and family names
      final nameParts = fullName.split(' ');
      final given = nameParts.first;
      final family = nameParts.length > 1 ? nameParts.last : '';

      // Create patient document
      final patientData = {
        'resourceType': 'Patient',
        'name': {
          'use': 'official',
          'given': given,
          'family': family,
          'fullName': fullName,
        },
        'active': true,
        'gender': gender,
        'identifier': {
          'system': 'app.patient.identifier',
          'value': 'patient-${DateTime.now().millisecondsSinceEpoch}',
        },
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email,
      };

      // Create the patient profile in Firestore
      final docRef = await _firestore
          .collection('patients')
          .add(patientData);

      // Also update the user's profile document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'patientId': docRef.id,
        'fullName': fullName,
        'given': given,
        'family': family,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create patient profile: $e');
    }
  }
  Future<Map<String, dynamic>?> getPatientProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return null;
    }

    final patientId = userDoc.data()?['patientId'];
    if (patientId == null) {
      return null;
    }

    final patientDoc = await _firestore
        .collection('patients')
        .doc(patientId)
        .get();

    return patientDoc.data();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        elevation: 2,
        backgroundColor: Colors.grey[150],
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(219, 239, 255, 1), // Changed background color
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _patientNameController,
                          decoration: InputDecoration(
                            labelText: 'Patient Name',
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter patient name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _medicationNameController,
                          decoration: InputDecoration(
                            labelText: 'Medication Name',
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.medication),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter medication name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dosageController,
                          decoration: InputDecoration(
                            labelText: 'Dosage',
                            fillColor: Colors.white,
                            hintText: 'e.g. 1 tablet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.scale),
                            filled: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter dosage';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _frequencyController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            labelText: 'Frequency per Day',
                            hintText: 'e.g. 1, 2, 3',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.repeat),
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _updateAvailableTimes();
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
                        Card(

                          color: Colors.white,
                          child: Column(
                            children: _timeOfDayOptions.map((time) {
                              return CheckboxListTile(
                                title: Text(time),
                                checkColor: Colors.white,
                                activeColor: Colors.blueAccent,
                                value: _selectedTimeOfDay.contains(time),
                                secondary: const Icon(Icons.access_time),
                                onChanged: (bool? selected) {
                                  setState(() {
                                    // Make sure frequency is valid
                                    int? frequency = int.tryParse(_frequencyController.text);
                                    if (selected == true &&
                                        frequency != null &&
                                        _selectedTimeOfDay.length < frequency) {
                                      _selectedTimeOfDay.add(time);
                                    } else if (selected == false) {
                                      _selectedTimeOfDay.remove(time);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            labelText: 'Before or After Food',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.restaurant),
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saveMedication,

                  label: const Text('Save Medication'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue, // Blue background color
                  ),
                )

              ],
            ),
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
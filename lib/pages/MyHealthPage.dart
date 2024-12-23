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
      print("Fetch status: $fetchStatus");
      api1 = remoteConfig.getString('apiurl1');

      if (api1 == null || api1!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key
      _fetchPatientRecords();
    } catch (e) {

      print("Failed to fetch API key from Remote Config.");
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

      print("Failed to fetch API key from Remote Config.");
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

    if (token.accessToken == null) {
      print('Access token is null');
      return;
    }

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Current user's medications fetched successfully")),
        );
      } else {
        throw Exception("Failed to fetch medication requests for the current user");
      }
    } catch (e) {
      print("Error fetching patient records: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching patient records")),
      );
    }
  }

  Future<void> _fetchUploadedFiles() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to obtain access token")),
        );
        return;
      }



      final response = await http.get(
        Uri.parse(api1),
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
          };
        }).toList();

        setState(() {
          _uploadedFiles = fileRecords;
        });
      } else {
        print("Failed to fetch files: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch files")),
        );
      }
    } catch (e) {
      print("Error fetching files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching files")),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to obtain access token")),
        );
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
          };
        }).toList();

        setState(() {
          _uploadedFilesP = fileRecords;
        });
      } else {
        print("Failed to fetch files: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch files")),
        );
      }
    } catch (e) {
      print("Error fetching files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching files")),
      );
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
        '${api1}?uploadType=media&name=$fileName';

    try {
      var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

      final response = await http.post(
        Uri.parse(api2),
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
        print("Failed to upload file: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload PDF")),
        );
      }
    } catch (e) {
      print("Error uploading PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading PDF")),
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
        print("Failed to upload file: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload PDF")),
        );
      }
    } catch (e) {
      print("Error uploading PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading PDF")),
      );
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

    switch(type.toLowerCase()) {
      case "medication":
        records = _uploadedRecords;
        break;
      case "report":
        records = _uploadedFiles.map((file) => {
          'fileName': file['fileName'],
          'uploadDate': file['uploadDate'],
        }).toList();
        break;
      case "prescription":
        records = _uploadedFilesP.map((file) => {
          'fileName': file['fileName'],
          'uploadDate': file['uploadDate'],
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
              onPressed: () {
                if (type.toLowerCase() == "medication") {
                  _navigateToAddMedicationPage();
                } else if (type.toLowerCase() == "report") {
                  _uploadPdfToGoogleCloudStorage();
                } else {
                  _uploadPdfToGoogleCloudStorageP();
                }
              },
              child: Text("Add ${type}"),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Card(
            elevation: 2,
            color: Colors.grey[100],

            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                type.toLowerCase() == "medication"
                    ? Icons.medication
                    : _getFileIcon(record['fileName'] ?? ''),
                color: Colors.blue,
                size: 40,

              ),
              title: Text(
                type.toLowerCase() == "medication"
                    ? record['name'] ?? 'Unknown'
                    : record['fileName'] ?? 'Unknown File',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type.toLowerCase() == "medication") ...[

                    if (record['medications'] != null)
                      ...(record['medications'] as List).map((med) =>
                          Text("${med['medicationName']} - ${med['dosage']}")
                      ),
                  ] else
                    Text("Uploaded: ${record['uploadDate']}"),
                ],
              ),
              isThreeLine: type.toLowerCase() == "medication",
            ),
          );
        },
      ),
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

    int? frequency;
    try {
      frequency = int.parse(_frequencyController.text);
    } catch (e) {
      frequency = 1;
    }

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
          "text": "${_dosageController.text} $_selectedUnit ${frequency}x per day",
          "timing": {
            "repeat": {
              "frequency": frequency,
              "period": 1,
              "periodUnit": "d"
            }
          },
          "doseAndRate": [
            {
              "type": {
                "coding": [
                  {
                    "system": "http://terminology.hl7.org/CodeSystem/dose-rate-type",
                    "code": "ordered",
                    "display": "Ordered"
                  }
                ]
              },
              "doseQuantity": {
                "value": int.tryParse(_dosageController.text) ?? 1,
                "unit": _selectedUnit,
                "system": "http://unitsofmeasure.org",
                "code": _selectedUnit.toUpperCase()
              }
            }
          ]
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
      "gender": "unknown",
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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter dosage';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      dropdownColor: Colors.white,
                      items: _dosageUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Change button color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Medication',style: TextStyle(color: Colors.white),),
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

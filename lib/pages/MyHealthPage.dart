import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class MyHealthPage extends StatefulWidget {
  const MyHealthPage({super.key});

  @override
  State<MyHealthPage> createState() => _MyHealthPageState();
}

class _MyHealthPageState extends State<MyHealthPage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _uploadedRecords = [];
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
    });
    _googleSignIn.signInSilently();
  }

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

  Future<void> _uploadHealthRecord() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sign-in failed")));
        return;
      }
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No file selected")));
      return;
    }

    var file = result.files.single;
    String? filePath = file.path;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File path is null, upload failed")));
      return;
    }

    String fileName = file.name;

    // Log file selection
    print("File selected: $fileName");

    // Get the auth credentials
    final authHeaders = await _getAuthHeaders();
    if (authHeaders == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to get authentication headers")));
      return;
    }

    // Log authentication headers
    print("Auth headers: $authHeaders");

    // Upload the file to the Google Healthcare API using authenticated HTTP client
    try {
      final uploadResponse = await _uploadFile(fileName, filePath, authHeaders);

      // Log response status
      print("Upload response status: ${uploadResponse.statusCode}");
      if (uploadResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Health record uploaded successfully")));
        setState(() {
          _uploadedRecords.add({
            'fileName': fileName,
            'uploadDate': DateTime.now().toString(),
            'fileUrl': filePath,
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed. Status: ${uploadResponse.statusCode}")));
      }
    } catch (e) {
      print("Error during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    }
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    if (_currentUser == null) {
      await _signIn();
      if (_currentUser == null) return null;
    }

    final GoogleSignInAuthentication auth = await _currentUser!.authentication;
    final String accessToken = auth.accessToken!;

    // Log the access token for debugging
    print("Access token: $accessToken");

    // Return the headers with the token
    return {
      'Authorization': 'Bearer $accessToken',
      // We do NOT need to explicitly set Content-Type for multipart upload
    };
  }

  Future<http.Response> _uploadFile(String fileName, String filePath, Map<String, String> authHeaders) async {
    final url = Uri.parse('https://healthcare.googleapis.com/v1/projects/healthcaremapapp-444513/locations/us-central1/datasets/health_records/fhirStores/my_fhir_store/fhir/Patient'); // Replace with actual API endpoint

    // Read the file bytes
    final fileBytes = await File(filePath).readAsBytes();

    // Create multipart request
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(authHeaders)
    // Add file as multipart
      ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    // Log the request for debugging
    print("Sending upload request to: $url");

    // Send the request and get the response
    final response = await request.send();

    // Read the response stream to get the response body
    final responseBody = await response.stream.bytesToString();

    // Log the response for debugging
    print("Upload response body: $responseBody");

    // Return the response as an http.Response
    return http.Response(responseBody, response.statusCode);
  }


  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) return Icons.image;
    if (fileName.endsWith('.txt')) return Icons.description;
    return Icons.insert_drive_file; // Default icon
  }

  Widget _buildPageContent(String type) {
    List<Map<String, String>> filteredRecords = _uploadedRecords
        .where((record) => record['fileName']!.toLowerCase().contains(type.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: filteredRecords.isEmpty
          ? const Center(child: Text("No files uploaded in this category yet."))
          : ListView.builder(
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          var record = filteredRecords[index];
          return Dismissible(
            key: Key(record['fileName']!), // Key must be unique
            direction: DismissDirection.endToStart, // Swipe from right to left
            onDismissed: (direction) {
              // Delete the file from the list
              setState(() {
                _uploadedRecords.removeAt(index);
              });

              // Show a snackbar confirming the deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${record['fileName']} deleted")),
              );
            },
            background: Container(
              color: Colors.red, // Red background when swiped
              child: const Icon(Icons.delete, color: Colors.white, size: 40.0),
            ),
            child: ListTile(
              leading: Icon(
                _getFileIcon(record['fileName']!),
                color: Colors.blueAccent,
              ),
              title: Text(record['fileName']!),
              subtitle: Text("Uploaded on: ${record['uploadDate']}"),
              onTap: () => _viewFile(record['fileUrl'] ?? ""),
            ),
          );
        },
      ),
    );
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
        onPressed: _uploadHealthRecord,
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
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.lightBlue : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24, fit: BoxFit.contain),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  void _viewFile(String fileUrl) {
    // Function to view file
  }
}

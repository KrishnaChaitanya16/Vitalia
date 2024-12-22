import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:file_picker/file_picker.dart';

class Mybillspage extends StatefulWidget {
  const Mybillspage({super.key});

  @override
  State<Mybillspage> createState() => _MybillspageState();
}

class _MybillspageState extends State<Mybillspage> with SingleTickerProviderStateMixin {
  late TabController _tabController; // Declare TabController
  double _indicatorPosition = 0;
  List<Map<String, String>> _receipts = [];
  List<Map<String, String>> _bills = [];// List to store receipts information
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with the correct length
    _tabController = TabController(length: 2, vsync: this);
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
    });
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _indicatorPosition = _tabController.index.toDouble();
        });
      }
    });
    _googleSignIn.signInSilently();
    _fetchUploadedReceipts();
    _fetchUploadedBills();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController when done
    super.dispose();
  }


  // Google Sign-In logic
  Future<void> _signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/cloud-platform']);
    _currentUser = await googleSignIn.signIn();
    setState(() {});
  }

  // Google Sign-Out logic
  Future<void> _signOutFromGoogle() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bills & Payments",
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Tabs with grey background and shadow
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Paid Bills"),
                Tab(text: "Receipts"),
              ],
            ),
          ),
          // Content of tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaidBillsSection(),
                _buildReceiptsSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          if (_tabController.index == 0 ) {
            _uploadPdfToGoogleCloudStorage(); // Add Medication for Health Records
          } else if (_tabController.index== 1) {
            _uploadreceiptToGoogleCloudStorage(); // Add PDFs for Reports
          }
        }, // Trigger PDF upload
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white), // Add icon
      ),
      bottomNavigationBar: _currentUser == null
          ? ElevatedButton(
        onPressed: _signInWithGoogle,
        child: const Text("Sign In with Google"),
      )
          : SizedBox.shrink(),
    );
  }

  // Build the Paid Bills section
  Widget _buildReceiptsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _receipts.length, // Use the dynamic list of receipts
        itemBuilder: (context, index) {
          final receipt = _receipts[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: Text(
                receipt['fileName']!,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              onTap: () {
                // Handle view receipt action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Viewing receipt: ${receipt['fileName']}")),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Build the Receipts section
  Widget _buildPaidBillsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _bills.length, // Use the dynamic list of receipts
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: Text(
                bill['fileName']!,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              onTap: () {
                // Handle view receipt action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Viewing bill: ${bill['fileName']}")),
                );
              },
            ),
          );
        },
      ),
    );
  }



  Future<void> _fetchUploadedReceipts() async {
    try {
      // Get Google OAuth2 token
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

      final apiUrl = 'https://storage.googleapis.com/storage/v1/b/health_bills/o';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken', // Use the Google OAuth2 token
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
            // You can format or adjust the date if necessary
          };
        }).toList();

        setState(() {
          _receipts = fileRecords; // Update the state with file data
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
  Future<void> _fetchUploadedBills() async {
    try {
      // Get Google OAuth2 token
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

      final apiUrl = 'https://storage.googleapis.com/storage/v1/b/health_bills1/o';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken', // Use the Google OAuth2 token
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
            // You can format or adjust the date if necessary
          };
        }).toList();

        setState(() {
          _bills = fileRecords; // Update the state with file data
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

  // Upload health record (PDF) to Google Cloud Storage
  Future<void> _uploadreceiptToGoogleCloudStorage() async {
    if (_currentUser == null) {
      // Prompt user to sign in if not already signed in
      await _signInWithGoogle();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in required")),
        );
        return;
      }
    }

    // Pick a PDF file using File Picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
      return;
    }

    var file = result.files.single;
    if (file.path == null && file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid file, upload failed")),
      );
      return;
    }

    // Read file bytes
    var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

    // Generate a unique file name
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Get access token
    final token = await _currentUser!.authentication;
    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to obtain access token")),
      );
      return;
    }

    final apiUrl =
        'https://storage.googleapis.com/upload/storage/v1/b/health_bills/o?uploadType=media&name=$fileName';

    try {
      // Make the upload request
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
        _fetchUploadedReceipts(); // Refresh the list of uploaded files
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
  Future<void> _uploadPdfToGoogleCloudStorage() async {
    if (_currentUser == null) {
      // Prompt user to sign in if not already signed in
      await _signInWithGoogle();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in required")),
        );
        return;
      }
    }

    // Pick a PDF file using File Picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
      return;
    }

    var file = result.files.single;
    if (file.path == null && file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid file, upload failed")),
      );
      return;
    }

    // Read file bytes
    var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

    // Generate a unique file name
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Get access token
    final token = await _currentUser!.authentication;
    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to obtain access token")),
      );
      return;
    }

    final apiUrl =
        'https://storage.googleapis.com/upload/storage/v1/b/health_bills1/o?uploadType=media&name=$fileName';

    try {
      // Make the upload request
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
        _fetchUploadedBills(); // Refresh the list of uploaded files
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


}

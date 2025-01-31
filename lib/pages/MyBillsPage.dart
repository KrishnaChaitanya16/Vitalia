import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

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
  String api3="";
  String api4="";

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
    _initializeRemoteConfig();
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
  Future<void> _initializeRemoteConfig() async {




    try {
      FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch every time
      ));
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(<String, dynamic>{
        'api': 'default_api_key', // Set a default API key (optional)
      });
      final fetchStatus = await remoteConfig.fetchAndActivate();
      await remoteConfig.activate();
      print("Fetch status: $fetchStatus");
      api3 = remoteConfig.getString('apiurl3');

      if (api3 == null || api3!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key

    } catch (e) {

      print("Failed to fetch API key from Remote Config.");
    }
    try {
      FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch every time
      ));

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.activate();
      await remoteConfig.setDefaults(<String, dynamic>{
        'api4': 'default_api_key', // Set a default API key (optional)
      });
      final fetchStatus = await remoteConfig.fetchAndActivate();
      print("Fetch status: $fetchStatus");
      api4 = remoteConfig.getString('apiurl4');

      if (api4 == null || api4!.isEmpty) {
        throw Exception("API key not found in Remote Config");
      }

      // Fetch location after successfully fetching the API key

    } catch (e) {

      print("Failed to fetch API key from Remote Config.");
    }
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
      child: _receipts.isEmpty
          ? Center(
        child: Text(
          "No receipts found",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
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
      child: _bills.isEmpty
          ? Center(
        child: Text(
          "No bills exists",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _bills.length, // Use the dynamic list of receipts
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return Dismissible(
            key: Key(bill['fileName'] ?? index.toString()), // Unique key for each item
            direction: DismissDirection.endToStart, // Swipe left to delete
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              final success = await _deleteFileFromCloud(bill['fileName']!);

              if (success) {
                setState(() {
                  _bills.removeAt(index); // Remove the bill from the list
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bill deleted successfully")),
                );
                return true;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete bill")),
                );
                return false; // Prevent Dismissible from removing the widget
              }
            },
            child: Card(
              color: Colors.white,
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
                    SnackBar(content: Text("Viewing bill: ${bill['fileName']}")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }


  Future<bool> _deleteFileFromCloud(String fileName) async {
    final token = await _currentUser!.authentication;

    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication failed")),
      );
      return false;
    }

    // Construct the delete URL without the 'health_bills/' prefix twice
    final deleteUrl =
        'https://storage.googleapis.com/storage/v1/b/health_bills/o/${Uri.encodeComponent(fileName)}';

    // Print the delete URL for debugging
    print("Delete URL: $deleteUrl");

    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
        },
      );

      // Print the response details for debugging
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 204) {
        print("File deleted successfully");
        return true;
      } else {
        print("Failed to delete file: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error deleting file: $e");
      return false;
    }
  }


  Future<void> _fetchUploadedReceipts() async {
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
          const SnackBar(content: Text("Failed to obtain access token")),
        );
        return;
      }

      // Use the user's email as the folder name or fallback to "anonymous_user"
      String userFolder = googleUser.email ?? 'anonymous_user';

      // Define the API URL with the user folder to fetch only the files in their folder
      String apiUrl = 'https://storage.googleapis.com/storage/v1/b/health_bills/o?prefix=$userFolder/';

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
            const SnackBar(content: Text("No files found for this user")),
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

      // Use the user's email as the folder name or fallback to "anonymous_user"
      String userFolder = googleUser.email ?? 'anonymous_user';

      // Define the API URL with the user folder to fetch only the files in their folder
      String apiUrl = 'https://storage.googleapis.com/storage/v1/b/health_bills1/o?prefix=$userFolder/';

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
            const SnackBar(content: Text("No files found for this user")),
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

    // Get user's folder name based on email or fallback to "anonymous_user"
    String userFolder = _currentUser!.email ?? 'anonymous_user';

    // Generate a unique file name within the user's folder
    String fileName = '$userFolder/${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Get access token
    final token = await _currentUser!.authentication;
    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to obtain access token")),
      );
      return;
    }

    // Use the user's folder for uploading the receipt
    final apiUrl =
        'https://storage.googleapis.com/storage/v1/b/health_bills/o?uploadType=media&name=$fileName';

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
    var fileBytes = file.bytes ?? await File(file.path!).readAsBytes();

    // Get user's folder name based on email or fallback to "anonymous_user"
    String userFolder = _currentUser!.email ?? 'anonymous_user';

    // Generate a unique file name within the user's folder
    String fileName = '$userFolder/${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Get access token
    final token = await _currentUser!.authentication;
    if (token.accessToken == null || token.accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to obtain access token")),
      );
      return;
    }

    // Use the user's folder for uploading the PDF
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload PDF")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading PDF")),
      );
    }
  }



}

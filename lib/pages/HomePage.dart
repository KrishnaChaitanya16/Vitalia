import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // For location services
import 'package:provider/provider.dart'; // Import provider package
import '/providers/Location_provider.dart'; // Import LocationProvider
import '/pages/SpecialistsPage.dart';
import '/pages/MyHealthPage.dart';  // Add your page imports
import '/pages/MyBillsPage.dart';
import '/pages/ProfilePage.dart';
import '/pages/SearchResultsPage.dart';
import '/pages/BookAppointmentPage.dart';
import '/pages/BookTests.dart';
import '/pages/FindPharmacy.dart';
import '/pages/ChatbotPage.dart';
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  String _userName = ""; // To store user's name
  bool _isLoading = true; // To track loading state
  TextEditingController _searchController = TextEditingController();
  String _searchPlaceholder = 'Search by Speciality';
   // Placeholder until the name is fetched
  String? _profileImageUrl; // Null if no custom profile image
  final User? _currentUser = FirebaseAuth.instance.currentUser;
// Initial placeholder
  List<String> _searchOptions = [
    'Speciality',
    'Doctor',
    'Symptoms',
    'Hospital'
  ];
  int _currentSearchIndex = 0;

  // List of avatars with only 4 items
  List<Map<String, String>> _avatars = [
    {'image': 'assets/icons/appointment.png', 'label': 'My Appointments'},
    {'image': 'assets/icons/tests.png', 'label': 'Book Tests'},
    {'image': 'assets/icons/pharmacy.png', 'label': 'Find Pharmacy'},
    {'image': 'assets/icons/medicine.png', 'label': 'Medications'},
  ];

  // Specialist types for GridView
  List<Map<String, String>> _specialists = [
    {'image': 'assets/icons/heart.png', 'label': 'Cardiology'},
    {'image': 'assets/icons/hair.png', 'label': 'Dermatology'},
    {'image': 'assets/icons/brain.png', 'label': 'Neurology'},
    {'image': 'assets/icons/orthopedics.png', 'label': 'Orthopedics'},
    {'image': 'assets/icons/pediatric.png', 'label': 'Pediatrics'},
    {'image': 'assets/icons/stomach.png', 'label': 'Gastroentrology'},
    {'image': 'assets/icons/x-rays.png', 'label': 'Radiology'},
    {'image': 'assets/icons/kidney.png', 'label': 'Urology'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserDetails(); // Fetch user details when the page is loaded
    _startCyclingPlaceholders(); // Start cycling through search placeholders
    print("Calling getCurrentLocation...");
    Provider.of<LocationProvider>(context, listen: false).getCurrentLocation();
    _fetchUserDetails();
  }
  Future<void> _fetchUserDetails() async {
    if (_currentUser != null) {
      try {
        // Fetch user details from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['fullName'] ?? _currentUser!.displayName ?? "User";
            _profileImageUrl = userDoc['profileImageUrl'] ?? _currentUser!.photoURL;
          });
        } else {
          // Firestore document does not exist, fallback to Google data
          setState(() {
            _userName = _currentUser!.displayName ?? "User";
            _profileImageUrl = _currentUser!.photoURL; // Use Google profile photo
          });

          // Optionally, create a Firestore document for new Google sign-in users
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .set({
            'fullName': _currentUser!.displayName ?? "User",
            'profileImageUrl': _currentUser!.photoURL,
            'email': _currentUser!.email,
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          _userName = _currentUser!.displayName ?? "User";
          _profileImageUrl = _currentUser!.photoURL;
        });
      }
    }
  }


  Future<void> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        setState(() {
          // Check Firestore first, then fallback to Google data
          _userName = userDoc.exists
              ? (userDoc['fullName'] ?? user.displayName ?? "User")
              : user.displayName ?? "User";

          _isLoading = false; // Stop loading
        });

        // Optionally create Firestore entry for new Google users
        if (!userDoc.exists) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? "User",
            'email': user.email,
            'profileImageUrl': user.photoURL ?? '',
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");

        // In case of any error, fallback to Firebase Auth user data
        setState(() {
          _userName = user.displayName ?? "User";
          _isLoading = false;
        });
      }
    } else {
      // If no user is signed in
      setState(() {
        _userName = "User";
        _isLoading = false;
      });
    }
  }


  void _startCyclingPlaceholders() {
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _searchPlaceholder = 'Search by ${_searchOptions[_currentSearchIndex]}';
        _currentSearchIndex = (_currentSearchIndex + 1) % _searchOptions.length;
      });
      _startCyclingPlaceholders(); // Recursively call to keep cycling
    });
  }

  // Define a method to handle navigation based on selected index
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page based on selected index
    switch (index) {
      case 0:
      // Navigate to the HomePage (Current page)
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHealthPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Mybillspage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Profilepage()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the LocationProvider using Provider.of
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: _profileImageUrl != null
                        ? ClipOval(
                      child: Image.network(
                        _profileImageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : ClipOval(
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.white, // Default color background
                        child: Image.asset(
                          'assets/icons/user (1).png',
                          color: Colors.grey, // Tint the default image
                          colorBlendMode: BlendMode.srcIn,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "View and edit profile",
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // Increased spacing below the profile section
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 30), // Increased spacing below the divider

              // Menu Items
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Image.asset('assets/icons/appointment.png', height: 24),
                      title: Text(
                        "Your Appointments",
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context)=>Bookappointmentpage()));
                        // Navigate to Appointments Page
                      },
                    ),
                    const SizedBox(height: 20), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/tests.png', height: 24),
                      title: Text(
                        "Your Tests",
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to Tests Page
                      },
                    ),
                    const SizedBox(height: 20), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/user (1).png', height: 24),
                      title: Text(
                        "Profile",
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to Profile Page
                      },
                    ),
                    const SizedBox(height: 20), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/android.png', height: 24),
                      title: Text(
                        "Vital AI",
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to Chat with AI Page
                      },
                    ),
                  ],
                ),
              ),

              // Footer Section
              const SizedBox(height: 30), // Space before footer section
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Version 1.0.0",
                  style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      )

      ,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
            builder:(context)=>IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Scaffold.of(context).openDrawer();

          },
        )),
        title: _isLoading
            ? null
            : Text(
          'Hello, ${_userName.length > 7
              ? _userName.substring(0, 7)
              : _userName}',
          style: GoogleFonts.nunito(color: Colors.black, fontSize: 20),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getUserDetails,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchResultsPage(
                                query: query

                              ),
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: _searchPlaceholder,
                    hintStyle: GoogleFonts.nunito(
                        color: Colors.black45, fontSize: 18),
                    prefixIcon: const Icon(
                        Icons.search, color: Color.fromRGBO(29, 54, 107, 1)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                          color: Colors.black, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                  ),
                ),
              ),
              // Display user's current location from LocationProvider
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 5.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationProvider.currentLocation,
                        style: GoogleFonts.nunito(
                            color: Colors.black, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_avatars[index]['label'] == 'Medications') {
                                  // Navigate to MyHealthPage when 'Medications' is tapped
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyHealthPage(),
                                    ),
                                  );
                                }
                                if(_avatars[index]['label']=='My Appointments'){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context)=> Bookappointmentpage()),
                                  );
                                }
                                if(_avatars[index]['label']== 'Book Tests'){
                                  Navigator.push(
                                    context,MaterialPageRoute(builder: (context)=>Booktests()),
                                  );
                                }
                                if(_avatars[index]['label']== 'Find Pharmacy'){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Findpharmacy()));
                                }
                                // You can add similar navigation for other avatars as needed
                              },
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.lightBlueAccent.shade100.withOpacity(0.5),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    _avatars[index]['image']!,
                                    fit: BoxFit.contain,
                                    height: 60,
                                    width: 60,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _avatars[index]['label']!,
                              style: GoogleFonts.nunito(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              ),
              // Rectangular rounded container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width,// Increased height
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Confused or need help?',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10), // Adds space between the text and button
                      Text(
                        'Chat with VitalAi',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20), // Adds space before the button
                      ElevatedButton(
                        onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatbotPage()));
                        },
                        child: const Text('Start Chat',style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(1), // Button color
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ),
              const SizedBox(height: 20),
              // Specialists heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Specialists',
                  style: GoogleFonts.nunito(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              // Specialist types grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Three items in a row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 4 /
                        3, // Adjusted aspect ratio for smaller cells
                  ),
                  itemCount: _specialists.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Navigate to Specialistspage with the specialty name
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Specialistspage(
                                  specialistType: _specialists[index]['label']!,
                                ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        color: Colors.lightBlue.shade100.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _specialists[index]['image']!,
                              height: 40,
                              color: const Color.fromRGBO(
                                  29, 54, 107, 1), // Smaller image
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _specialists[index]['label']!,
                              style: GoogleFonts.nunito(
                                  fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.grey[100],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/home.png', height: 24),
            activeIcon: Image.asset(
              'assets/icons/home.png',
              height: 24,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/heart-beat.png', height: 24),
            activeIcon: Image.asset(
              'assets/icons/heart-beat.png',
              height: 24,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'MyHealth',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/receipt.png', height: 24),
            activeIcon: Image.asset(
              'assets/icons/receipt.png',
              height: 24,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'MyBills',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/user (1).png', height: 24),
            activeIcon: Image.asset(
              'assets/icons/user (1).png',
              height: 24,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

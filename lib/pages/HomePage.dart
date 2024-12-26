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
import '/pages/AllSpecialistsPage.dart';
import 'dart:async';
import '/pages/YourTests.dart';
import '/pages/YourCartPage.dart';
import '/pages/YourOrdersPage.dart';

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


  int _currentCharIndex = 0;
  Timer? _typingTimer;

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
    {'image': 'assets/icons/heart.png', 'label': 'Heart Issues'},
    {'image': 'assets/icons/hair.png', 'label': 'Skin & Hair'},
    {'image': 'assets/icons/brain.png', 'label': 'Brain and Nerves'},
    {'image': 'assets/icons/orthopedics.png', 'label': 'Bones and Joints'},
    {'image': 'assets/icons/pediatric.png', 'label': 'Child Specialist'},
    {'image': 'assets/icons/stomach.png', 'label': 'Gastroentrology'},
    {'image': 'assets/icons/nasal.png', 'label': 'Ear,Nose,Throat'},
    {'image': 'assets/icons/kidney.png', 'label': 'Urology'},
    {'image':'assets/icons/plus.png','label':'More'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserDetails(); // Fetch user details when the page is loaded
    _startTypingAnimation(); // Start cycling through search placeholders

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
            _userName = (userDoc['fullName'] != null && userDoc['fullName'].trim().isNotEmpty)
                ? userDoc['fullName']
                : _currentUser!.displayName ?? "User";
          });
        } else {
          // Firestore document does not exist, fallback to Google data
          setState(() {
            _userName = _currentUser!.displayName ?? "User";
          });

          // Optionally, create a Firestore document for new Google sign-in users
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .set({
            'fullName': _currentUser!.displayName ?? "User",
            'email': _currentUser!.email,
          });
        }
      } catch (e) {
        setState(() {
          _userName = _currentUser!.displayName ?? "User";
        });
      }
    }
  }
  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentCharIndex < _searchOptions[_currentSearchIndex].length) {
        setState(() {
          // Build the string character by character
          _searchPlaceholder = 'Search by ${_searchOptions[_currentSearchIndex].substring(0, _currentCharIndex + 1)}';
          _currentCharIndex++;
        });
      } else {
        // Typing for the current option is complete
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          // Move to the next search option
          setState(() {
            _currentSearchIndex = (_currentSearchIndex + 1) % _searchOptions.length;
            _currentCharIndex = 0; // Reset character index
          });
          _startTypingAnimation(); // Start typing the next option
        });
      }
    });
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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white
          ),
        child:Padding(
          padding:  EdgeInsets.only(top: screenHeight*0.05 , left: screenWidth*0.04, right: screenWidth*0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.1,
                    backgroundColor: Colors.grey[200],
                    child: _profileImageUrl != null
                        ? ClipOval(
                      child: Image.network(
                        _profileImageUrl!,
                        width: screenWidth * 0.26,
                        height: screenWidth * 0.26,
                        fit: BoxFit.cover,
                      ),
                    )
                        : ClipOval(
                      child: Container(
                        width: screenWidth * 0.26,
                        height: screenWidth * 0.26,
                        color: Colors.transparent, // Default color background
                        child: Image.asset(
                          'assets/icons/user (1).png',
                          color: Colors.black, // Tint the default image
                          colorBlendMode: BlendMode.srcIn,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),


                   SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.nunito(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black
                          ),
                        ),
                        Text(
                          "View and edit profile",
                          style: GoogleFonts.nunito(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
               SizedBox(height: screenHeight * 0.03), // Increased spacing below the profile section
              const Divider(thickness: 1, color: Colors.grey),
               SizedBox(height: screenHeight * 0.03), // Increased spacing below the divider

              // Menu Items
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Image.asset('assets/icons/appointment.png', height: screenHeight * 0.03),
                      title: Text(
                        "Your Appointments",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => Bookappointmentpage()));
                        // Navigate to Appointments Page
                      },
                    ),
                     SizedBox(height: screenHeight * 0.02), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/tests.png', height: screenHeight * 0.03),
                      title: Text(
                        "Your Tests",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Yourtests()));
                        // Navigate to Tests Page
                      },
                    ),
                     SizedBox(height: screenHeight * 0.02), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/user (1).png', height: screenHeight * 0.03),
                      title: Text(
                        "Profile",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Profilepage()));
                        // Navigate to Profile Page
                      },
                    ),
                     SizedBox(height: screenHeight * 0.02), // Spacing between menu items
                    ListTile(
                      leading: Image.asset('assets/icons/chatbot1.png', height: screenHeight * 0.04),
                      title: Text(
                        "Vital AI",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatbotPage()));

                      },
                    ),
                    SizedBox(height: screenHeight*0.02,),
                    ListTile(
                      leading: Image.asset('assets/icons/shopping-bag.png', height: screenHeight * 0.03),
                      title: Text(
                        "Your Cart",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>CartPage()));

                      },
                    ),
                    SizedBox(height: screenHeight*0.02,),
                    ListTile(
                      leading: Image.asset('assets/icons/package.png', height: screenHeight * 0.035),
                      title: Text(
                        "Your Orders",
                        style: GoogleFonts.nunito(fontSize: screenHeight * 0.016),
                      ),
                      trailing:  Icon(Icons.arrow_forward_ios, size: screenHeight * 0.017, color: Colors.grey.shade700),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>YourOrdersPage()));

                      },
                    ),
                  ],
                ),
              ),


              // Footer Section
               SizedBox(height: screenHeight * 0.03), // Space before footer section
              const Divider(thickness: 1, color: Colors.grey),
               SizedBox(height: screenHeight * 0.01),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Version 1.0.0",
                  style: GoogleFonts.nunito(fontSize: screenHeight * 0.012, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ))

      ,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
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
          style: GoogleFonts.nunito(color: Colors.black, fontSize: screenHeight * 0.022,fontWeight: FontWeight.bold),
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
      body:Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
    Color(0xFFE3F2FD), // Light blue at the top
    Color(0xFFBBDEFB), // Slightly darker blue at the bottom
    ],)
        ),
          child:RefreshIndicator(
        color: Colors.lightBlue,
        onRefresh: _getUserDetails,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:  EdgeInsets.all(screenHeight * 0.01),
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
                        color: Colors.black45, fontSize: screenHeight * 0.018),
                    prefixIcon: const Icon(
                        Icons.search, color: Color.fromRGBO(29, 79, 153, 1)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                          color: Colors.black, width: 1.5),
                    ),
                    focusedBorder:  OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)
                    ),
                    contentPadding:  EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015, horizontal: screenHeight * 0.02),
                  ),
                ),
              ),
              // Display user's current location from LocationProvider
              Padding(
                padding:  EdgeInsets.symmetric(
                    horizontal: screenHeight * 0.016, vertical: screenHeight * 0.005),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.redAccent),
                     SizedBox(width: screenWidth * 0.008),
                    Expanded(
                      child: Text(
                        locationProvider.currentLocation,
                        style: GoogleFonts.nunito(
                            color: Colors.black, fontSize: screenHeight * 0.016),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:  EdgeInsets.symmetric(vertical: screenHeight * 0.001),
                child: SizedBox(
                  height: screenHeight * 0.14,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.024),
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
                                radius: screenWidth*0.079,
                                backgroundColor: Colors.lightBlueAccent.shade100.withOpacity(0.5),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    _avatars[index]['image']!,
                                    fit: BoxFit.contain,
                                    height: screenWidth*0.11,
                                    width: screenWidth*0.11,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                             SizedBox(height: screenHeight*0.008),
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
                padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.038),
                child: Container(
                  height: screenHeight*0.16,
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
                          fontSize: screenHeight*0.019,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight*0.010), // Adds space between the text and button
                      Text(
                        'Chat with VitalAi',
                        style: GoogleFonts.nunito(
                          fontSize: screenHeight*0.017,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight*0.02), // Adds space before the button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatbotPage()));
                        },
                        child: const Text('Start Chat',style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(1), // Button color
                          padding:  EdgeInsets.symmetric(horizontal: screenHeight*0.032, vertical: screenWidth*0.012),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ),
               SizedBox(height: screenHeight*0.025),
              // Specialists heading
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.05),
                child: Text(
                  'Find a Doctor for your Health Problem',
                  style: GoogleFonts.nunito(fontSize: screenHeight*0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
               SizedBox(height: screenHeight*0.015),
              // Specialist types grid
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04),
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
                        if(index==_specialists.length-1){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Allspecialistspage() ));

                        }else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Specialistspage(
                                    specialistType: _specialists[index]['label']!,
                                  ),
                            ),
                          );
                        }
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
                              height: screenHeight*0.047,
                              color: const Color.fromRGBO(
                                  29, 54, 107, 1), // Smaller image
                            ),
                             SizedBox(height: screenHeight*0.008),
                            Text(
                              _specialists[index]['label']!,
                              style: GoogleFonts.nunito(
                                  fontSize: screenWidth*0.03, color: Colors.black),
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

      )),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.white70,
        elevation: 7,
        selectedItemColor: const Color.fromRGBO(29, 54, 107, 1),
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.nunito(),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/home.png', height: screenHeight*0.024),
            activeIcon: Image.asset(
              'assets/icons/home.png',
              height: 24,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/heart-beat.png', height: screenHeight*0.024),
            activeIcon: Image.asset(
              'assets/icons/heart-beat.png',
              height: screenHeight*0.024,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'MyHealth',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/receipt.png', height: screenHeight*0.024),
            activeIcon: Image.asset(
              'assets/icons/receipt.png',
              height: screenHeight*0.024,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'MyBills',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/user (1).png', height: screenHeight*0.024),
            activeIcon: Image.asset(
              'assets/icons/user (1).png',
              height: screenHeight*0.024,
              color: const Color.fromRGBO(29, 54, 107, 1),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

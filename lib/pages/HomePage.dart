import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _searchPlaceholder = 'Search by Speciality'; // Initial placeholder
  List<String> _searchOptions = ['Speciality', 'Doctor', 'Symptoms', 'Hospital'];
  int _currentSearchIndex = 0;

  // List of avatars with only 4 items
  List<Map<String, String>> _avatars = [
    {'image': 'assets/icons/avatar1.png', 'label': 'John'},
    {'image': 'assets/icons/avatar2.png', 'label': 'Anna'},
    {'image': 'assets/icons/avatar3.png', 'label': 'Mark'},
    {'image': 'assets/icons/avatar4.png', 'label': 'Lily'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserDetails(); // Fetch user details when the page is loaded
    _startCyclingPlaceholders(); // Start cycling through search placeholders
  }

  // Function to get user details from Firestore
  Future<void> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['fullName'] ?? "User";
          _isLoading = false; // Stop loading when user details are fetched
        });
      } else {
        setState(() {
          _userName = "User"; // Default if user data is not found
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false; // Stop loading if there's no user signed in
      });
    }
  }

  // Function to start cycling through the search placeholders
  void _startCyclingPlaceholders() {
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _searchPlaceholder = 'Search by ${_searchOptions[_currentSearchIndex]}';
        _currentSearchIndex = (_currentSearchIndex + 1) % _searchOptions.length;
      });
      _startCyclingPlaceholders(); // Recursively call to keep cycling
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to manually refresh user details (pull-to-refresh feature)
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true; // Start loading again
    });
    await _getUserDetails(); // Re-fetch the user details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black,
          ),
          onPressed: () {
            // Handle menu click here
          },
        ),
        title: _isLoading
            ? null // Do not show any title while loading
            : Text(
          'Hello, ${_userName.length > 7 ? _userName.substring(0, 7) : _userName}',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              // Handle notification click here
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Search bar below AppBar
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _searchPlaceholder,
                  hintStyle: GoogleFonts.nunito(
                    color: Colors.black45,
                    fontSize: 18,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(29, 54, 107, 1)),
                  filled: true,
                  fillColor: Colors.white, // Background color white
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Colors.black, // Black outline
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),

            // Horizontal ListView of Circle Avatars with 4 avatars
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                height: 120, // Adjust height to fit larger avatars
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40, // Increased size of the avatar
                            backgroundImage: AssetImage(_avatars[index]['image']!),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _avatars[index]['label']!,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: const Text(
                  'Homepage Content',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.only(top: 10), // Adjust top padding for height
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.grey[100],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/home.png',
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/icons/home.png',
                height: 24,
                color: const Color.fromRGBO(29, 54, 107, 1),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/heart-beat.png',
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/icons/heart-beat.png',
                color: const Color.fromRGBO(29, 54, 107, 1),
                height: 24,
              ),
              label: 'MyHealth',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/receipt.png',
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/icons/receipt.png',
                height: 24,
                color: const Color.fromRGBO(29, 54, 107, 1),
              ),
              label: 'MyBills',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/user (1).png',
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/icons/user (1).png',
                height: 24,
                color: const Color.fromRGBO(29, 54, 107, 1),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

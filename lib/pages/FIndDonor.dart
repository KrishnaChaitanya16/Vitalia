import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class Donor {
  final String id;
  final String name;
  final String bloodType;
  final String location;
  final String phoneNumber;
  final bool isAvailable;
  final String userId;

  Donor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.location,
    required this.phoneNumber,
    required this.userId,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bloodType': bloodType,
      'location': location,
      'phoneNumber': phoneNumber,
      'isAvailable': isAvailable,
      'userId': userId,
    };
  }

  factory Donor.fromMap(String id, Map<String, dynamic> map) {
    return Donor(
      id: id,
      name: map['name'] ?? '',
      bloodType: map['bloodType'] ?? '',
      location: map['location'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      userId: map['userId'] ?? '',
    );
  }
}

class Finddonor extends StatefulWidget {
  const Finddonor({super.key});

  @override
  State<Finddonor> createState() => _FinddonorState();
}

class _FinddonorState extends State<Finddonor> {
  final _formKey = GlobalKey<FormState>();
  bool _isDonor = true;
  String _selectedBloodType = 'A+';
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController=TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Donor>>? _donorsStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDonorsStream();
  }

  void _initializeDonorsStream() {
    _donorsStream = _firestore
        .collection('donors')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          Donor.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });

    _searchController.addListener(() {
      final city = _searchController.text.trim();
      setState(() {
        _donorsStream = _firestore
            .collection('donors')
            .where('isAvailable', isEqualTo: true)
            .where('location', isEqualTo: city.isEmpty ? null : city)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
              Donor.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
        });
      });
    });
  }


  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('User registration failed');
      }

      if (_isDonor) {
        await _firestore.collection('donors').add({
          'name': _nameController.text,
          'bloodType': _selectedBloodType,
          'location': _locationController.text,
          'phoneNumber': _phoneController.text,
          'isAvailable': true,
          'userId': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('recipients').add({
          'name': _nameController.text,
          'bloodType': _selectedBloodType,
          'location': _locationController.text,
          'phoneNumber': _phoneController.text,
          'userId': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful as ${_isDonor ? "Donor" : "Recipient"}',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _locationController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.nunitoTextTheme(Theme
        .of(context)
        .textTheme);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.nunito(),
          hintStyle: GoogleFonts.nunito(),
          errorStyle: GoogleFonts.nunito(color: Colors.red),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Find Donor',
            style: GoogleFonts.nunito(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
        ),
        backgroundColor: const Color.fromRGBO(219, 239, 255, 1),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register as:',
                        style: GoogleFonts.nunito(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _isDonor = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isDonor
                                    ? Colors.blueAccent
                                    : Colors.grey[300],
                                foregroundColor: _isDonor
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: Text('Donor', style: GoogleFonts.nunito()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _isDonor = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_isDonor
                                    ? Colors.blueAccent
                                    : Colors.grey[300],
                                foregroundColor: !_isDonor
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: Text(
                                  'Recipient', style: GoogleFonts.nunito()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registration Form',
                          style: GoogleFonts.nunito(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black45)),
                              labelStyle: TextStyle(color: Colors.black45)
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedBloodType,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                            labelText: 'Blood Type',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)
                            ),
                          ),
                          items: _bloodTypes.map((String bloodType) {
                            return DropdownMenuItem(
                              value: bloodType,
                              child: Text(
                                  bloodType, style: GoogleFonts.nunito(color: Colors.black)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBloodType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          style: GoogleFonts.nunito(),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : Text('Register', style: GoogleFonts.nunito(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isDonor) ...[
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Search Donors by City',
                            style: GoogleFonts.nunito(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Card(

                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Enter city name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.black45),
                                ),
                                prefixIcon: Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Available Donors',
                          style: GoogleFonts.nunito(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<Donor>>(
                          stream: _donorsStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}',
                                  style: GoogleFonts.nunito());
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final donors = snapshot.data ?? [];

                            if (donors.isEmpty) {
                              return Center(
                                child: Text('No donors available',
                                    style: GoogleFonts.nunito()),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: donors.length,
                              itemBuilder: (context, index) {
                                final donor = donors[index];
                                return Card(
                                  color: Colors.white,
                                  shadowColor: Colors.black,
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    title: Text(donor.name,
                                        style: GoogleFonts.nunito()),
                                    subtitle: Text(
                                      '${donor.bloodType} | ${donor.location}',
                                      style: GoogleFonts.nunito(),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.phone,color: Colors.blueAccent,),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: donor.phoneNumber)).then((_) {
                                          // Show Snackbar confirming the action
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Phone number copied to clipboard',
                                                style: GoogleFonts.nunito(),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

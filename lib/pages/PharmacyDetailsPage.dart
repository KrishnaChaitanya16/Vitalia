import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/pages/YourCartPage.dart';
class PharmacyDetailsPage extends StatefulWidget {
  final String pharmacyName;
  final String pharmacyAddress;

  const PharmacyDetailsPage({
    Key? key,
    required this.pharmacyName,
    required this.pharmacyAddress,
  }) : super(key: key);

  @override
  _PharmacyDetailsPageState createState() => _PharmacyDetailsPageState();
}

class _PharmacyDetailsPageState extends State<PharmacyDetailsPage> {
  bool _isLoading = false;
  List<dynamic> _medicines = [];
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchMedicines();
  }

  // Fetch the user's full name from Firestore
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists && userDoc.data()?['fullName'] != null) {
          setState(() {
            _userName = userDoc.data()!['fullName'];
          });
        } else {
          print('User document does not exist or "fullName" field is missing.');
        }
      } else {
        print('No user is logged in.');
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  // Example static list of medicines
  Future<void> _fetchMedicines() async {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> medicines = [
      {'name': 'Aspirin', 'purpose': 'Pain reliever', 'prescription': false},
      {'name': 'Paracetamol', 'purpose': 'Pain and fever relief', 'prescription': false},
      {'name': 'Amoxicillin', 'purpose': 'Antibiotic', 'prescription': true},
      {'name': 'Ibuprofen', 'purpose': 'Anti-inflammatory', 'prescription': false},
      {'name': 'Cetirizine', 'purpose': 'Antihistamine', 'prescription': false},
      {'name': 'Diazepam', 'purpose': 'Anti-anxiety', 'prescription': true},
      {'name': 'Omeprazole', 'purpose': 'Acid reflux', 'prescription': false},
      {'name': 'Metformin', 'purpose': 'Diabetes management', 'prescription': true},
      {'name': 'Atorvastatin', 'purpose': 'Cholesterol management', 'prescription': true},
      {'name': 'Diphenhydramine', 'purpose': 'Allergy relief', 'prescription': false},
      {'name': 'Losartan', 'purpose': 'Hypertension', 'prescription': true},
      {'name': 'Lisinopril', 'purpose': 'Blood pressure medication', 'prescription': true},
      {'name': 'Hydrocodone', 'purpose': 'Pain relief', 'prescription': true},
      {'name': 'Fluoxetine', 'purpose': 'Antidepressant', 'prescription': true},
      {'name': 'Vitamin D3', 'purpose': 'Supplement', 'prescription': false},
      {'name': 'Folic Acid', 'purpose': 'Supplement', 'prescription': false},
      {'name': 'Loperamide', 'purpose': 'Anti-diarrheal', 'prescription': false},
      {'name': 'Ibuprofen Gel', 'purpose': 'Topical pain relief', 'prescription': false},
      {'name': 'Prednisone', 'purpose': 'Anti-inflammatory', 'prescription': true},
      // Add more medicines as needed...
    ];

    setState(() {
      _medicines = medicines;
      _isLoading = false;
    });
  }

  // Add a medicine to the cart collection
  Future<void> _addToCart(String medicineName, int quantity) async {
    if (_userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User name is not available. Cannot add to cart.')),
      );
      return;
    }

    try {
      // Get a reference to the cart collection for the current user
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(_userName);

      // Check if the cart document exists
      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // If the cart document exists, update the cart
        await cartRef.update({
          'medicines': FieldValue.arrayUnion([{
            'name': medicineName,
            'quantity': quantity,
          }]),
        });
      } else {
        // If the cart document does not exist, create a new one
        await cartRef.set({
          'userName': _userName,
          'medicines': [{
            'name': medicineName,
            'quantity': quantity,
          }],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$medicineName x$quantity added to cart!')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding to cart. Please try again later.')),
      );
    }
  }


  // Show the modal bottom sheet for selecting quantity
  void _showQuantitySelector(String medicineName) {
    int quantity = 1; // Default quantity
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(

          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Quantity',
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.black),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent.shade200, // Custom color using hex code
                    ),

                    onPressed: () {
                      _addToCart(medicineName, quantity);
                      Navigator.pop(context);
                    },

                    child: const Text('Add to Cart',style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pharmacyName,
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(

            icon: Container(
              margin: EdgeInsets.only(right: 35),
                child:Image.asset(
      'assets/icons/shopping-bag.png', // Path to your custom icon
        width: 24, // Adjust the size as needed
        height: 24,

      )),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _medicines.isEmpty
            ? Center(
          child: Text(
            'No medicines found.',
            style: GoogleFonts.nunito(fontSize: 18, color: Colors.black54),
          ),
        )
            : ListView.builder(
          itemCount: _medicines.length,
          itemBuilder: (context, index) {
            final medicine = _medicines[index];
            final medicineName = medicine['name'] ?? 'Unknown Medicine';
            final purpose = medicine['purpose'] ?? 'No purpose specified';
            final prescriptionRequired = medicine['prescription'] ?? false;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.medication, color: Colors.blue),
                title: Text(
                  medicineName,
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purpose,
                      style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
                    ),
                    if (prescriptionRequired)
                      Text(
                        'Prescription Required',
                        style: GoogleFonts.nunito(fontSize: 12, color: Colors.red),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    _showQuantitySelector(medicineName);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

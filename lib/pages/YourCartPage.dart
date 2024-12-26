import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoading = false;
  List<dynamic> _cartItems = [];
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
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
          _fetchCartItems();
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

  // Fetch the cart items from Firestore
  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_userName != null) {
        final cartDoc = await FirebaseFirestore.instance.collection('carts').doc(_userName).get();

        if (cartDoc.exists && cartDoc.data()?['medicines'] != null) {
          setState(() {
            _cartItems = List.from(cartDoc.data()?['medicines']);
          });
        } else {
          print('No cart items found.');
        }
      } else {
        print('User name is null, cannot fetch cart items.');
      }
    } catch (e) {
      print('Error fetching cart items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Place the order
  // Place the order
  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Cannot place an order.')),
      );
      return;
    }

    try {
      // Calculate delivery time (2 days from the current time)
      final orderDate = Timestamp.now();
      final deliveryDate = orderDate.toDate().add(const Duration(days: 2));

      // Create the order in Firestore
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      await orderRef.set({
        'userName': _userName,
        'medicines': _cartItems,
        'orderDate': orderDate,
        'deliveryTime': Timestamp.fromDate(deliveryDate),
        'status': 'Pending',
      });

      // Fetch the generated order ID
      final orderId = orderRef.id;

      // Clear the cart after placing the order
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(_userName);
      await cartRef.update({
        'medicines': FieldValue.delete(),
      });

      // Navigate to the SuccessPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessPage(orderId: orderId),
        ),
      );
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error placing order. Please try again later.')),
      );
    }
  }

  // Update the quantity of a medicine in the cart
  Future<void> _updateQuantity(int index, int newQuantity) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(_userName);
      final updatedCartItems = List.from(_cartItems);
      updatedCartItems[index]['quantity'] = newQuantity;

      await cartRef.update({
        'medicines': updatedCartItems,
      });

      setState(() {
        _cartItems = updatedCartItems;
      });
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating quantity. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Cart',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
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
            : _cartItems.isEmpty
            ? Center(
          child: Text(
            'Your cart is empty.',
            style: GoogleFonts.nunito(fontSize: 18, color: Colors.black54),
          ),
        )
            : ListView.builder(
          itemCount: _cartItems.length,
          itemBuilder: (context, index) {
            final cartItem = _cartItems[index];
            final medicineName = cartItem['name'] ?? 'Unknown Medicine';
            final quantity = cartItem['quantity'] ?? 1;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.medication, color: Colors.blue),
                title: Text(
                  medicineName,
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity:',
                      style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.black),
                          onPressed: () {
                            if (quantity > 1) {
                              _updateQuantity(index, quantity - 1);
                            }
                          },
                        ),
                        Text(
                          '$quantity',
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black),
                          onPressed: () {
                            _updateQuantity(index, quantity + 1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Custom color
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _placeOrder,
          child: const Text(
            'Place Order',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  final String orderId;

  const SuccessPage({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Successful',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.check,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your order has been placed successfully!',
              style: GoogleFonts.nunito(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Order ID: $orderId',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the home page
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YourOrdersPage extends StatefulWidget {
  const YourOrdersPage({Key? key}) : super(key: key);

  @override
  _YourOrdersPageState createState() => _YourOrdersPageState();
}

class _YourOrdersPageState extends State<YourOrdersPage> {
  final PanelController _panelController = PanelController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }
  String getFormattedDeliveryTime(DateTime deliveryTime) {
    final now = DateTime.now();
    final difference = deliveryTime.difference(now);
    final formatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    if (difference.inDays == 0) {
      if (difference.isNegative) {
        return 'Delivered on ${formatter.format(deliveryTime)} at ${timeFormatter.format(deliveryTime)}';
      } else {
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        if (hours > 0) {
          return 'Delivery in $hours hours ${minutes > 0 ? '$minutes minutes' : ''}';
        } else {
          return 'Delivery in $minutes minutes';
        }
      }
    } else if (difference.inDays == 1) {
      return 'Delivery tomorrow at ${timeFormatter.format(deliveryTime)}';
    } else if (difference.inDays == -1) {
      return 'Delivered yesterday at ${timeFormatter.format(deliveryTime)}';
    } else if (difference.inDays > 1) {
      return 'Delivery on ${formatter.format(deliveryTime)} at ${timeFormatter.format(deliveryTime)}';
    } else {
      return 'Delivered on ${formatter.format(deliveryTime)} at ${timeFormatter.format(deliveryTime)}';
    }
  }
  Future<String?> _fetchCurrentUserName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch user document from the Firestore 'users' collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Return the fullName if it exists, else null
        return userDoc.exists ? userDoc['fullName'] as String? : null;
      } catch (e) {
        print('Error fetching fullName: $e');
      }
    }
    return null; // Return null if no user is signed in or an error occurs
  }




  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Await the result of _fetchCurrentUserName
      String? currentUserName = await _fetchCurrentUserName();

      if (currentUserName != null) {
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userName', isEqualTo: currentUserName)
            .get();

        final orders = ordersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        setState(() {
          _orders = orders;
        });
      } else {
        print('User name not found.');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Widget _buildMedicineList(List<dynamic> medicines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Medicines in Order',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final medicine = medicines[index];
            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  medicine['name'] ?? 'Unknown Medicine',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: ${medicine['quantity']}',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  String getCurrentStatus(DateTime deliveryTime, String savedStatus) {
    final now = DateTime.now();
    // Calculate step times based on 2-day window
    final orderPlacedTime = deliveryTime.subtract(const Duration(hours: 48)); // Order placed 48 hours before delivery
    final processingTime = deliveryTime.subtract(const Duration(hours: 36)); // Processing starts 36 hours before delivery
    final shippedTime = deliveryTime.subtract(const Duration(hours: 24)); // Shipped 24 hours before delivery
    final outForDeliveryTime = deliveryTime.subtract(const Duration(hours: 12)); // Out for delivery 12 hours before

    if (now.isAfter(deliveryTime)) {
      return 'Delivered';
    } else if (now.isAfter(outForDeliveryTime)) {
      return 'Out for Delivery';
    } else if (now.isAfter(shippedTime)) {
      return 'Shipped';
    } else if (now.isAfter(processingTime)) {
      return 'Processing';
    } else if (now.isAfter(orderPlacedTime)) {
      return 'Order Placed';
    }
    return savedStatus;
  }

  DateTime getStepTime(DateTime deliveryTime, int stepIndex) {
    switch (stepIndex) {
      case 0: // Order Placed
        return deliveryTime.subtract(const Duration(hours: 48));
      case 1: // Processing
        return deliveryTime.subtract(const Duration(hours: 36));
      case 2: // Shipped
        return deliveryTime.subtract(const Duration(hours: 24));
      case 3: // Out for Delivery
        return deliveryTime.subtract(const Duration(hours: 12));
      case 4: // Delivered
        return deliveryTime;
      default:
        return deliveryTime;
    }
  }

  String getStepTimeDisplay(DateTime stepTime) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM d, h:mm a');
    final timeFormatter = DateFormat('h:mm a');
    final dateFormatter = DateFormat('MMM d');

    if (stepTime.day == now.day) {
      return 'Today ${timeFormatter.format(stepTime)}';
    } else if (stepTime.day == now.day + 1) {
      return 'Tomorrow ${timeFormatter.format(stepTime)}';
    } else if (stepTime.day == now.day - 1) {
      return 'Yesterday ${timeFormatter.format(stepTime)}';
    } else {
      return formatter.format(stepTime);
    }
  }

  Widget _buildOrderTimeline(Map<String, dynamic> order) {
    final deliveryTime = (order['deliveryTime'] as Timestamp).toDate();
    final savedStatus = order['status'] ?? 'Pending';
    final currentStatus = getCurrentStatus(deliveryTime, savedStatus);
    final steps = ['Order Placed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'];
    final currentIndex = steps.indexOf(currentStatus);

    return Timeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        color: Colors.blue,
        connectorTheme: const ConnectorThemeData(
          thickness: 3.0,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        itemCount: steps.length,
        contentsBuilder: (_, index) {
          final stepTime = getStepTime(deliveryTime, index);
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[index],
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: index <= currentIndex ? FontWeight.bold : FontWeight.normal,
                    color: index <= currentIndex ? Colors.black : Colors.grey,
                  ),
                ),
                if (index <= currentIndex)
                  Text(
                    getStepTimeDisplay(stepTime),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          );
        },
        indicatorBuilder: (_, index) {
          return DotIndicator(
            size: 20.0,
            color: index <= currentIndex ? Colors.blue : Colors.grey,
            child: index <= currentIndex
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          );
        },
        connectorBuilder: (_, index, ___) => SolidLineConnector(
          color: index < currentIndex ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
  Widget _buildSlidingPanel() {
    if (_selectedOrder == null) return Container();

    final order = _selectedOrder!;
    final orderId = order['id'] ?? 'Unknown ID';
    final deliveryTime = (order['deliveryTime'] as Timestamp).toDate();
    final medicines = order['medicines'] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Order ID: $orderId',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getFormattedDeliveryTime(deliveryTime),
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order Status:',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: _buildOrderTimeline(order),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ordered Items:',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMedicineList(medicines),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Orders',
          style: GoogleFonts.nunito(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 3,
        shadowColor: Colors.black45,
      ),
      body: Container( 
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE3F2FD),  Color(0xFFBBDEFB)])
        ),
          child:Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              final orderId = order['id'] ?? 'Unknown ID';
              final deliveryTime = (order['deliveryTime'] as Timestamp).toDate();
              final status = DateTime.now().isAfter(deliveryTime) ? 'Delivered' : (order['status'] ?? 'Pending');


              return Card(
                color: Colors.white,
                shadowColor: Colors.black45,
                elevation: 6,
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: ListTile(
                  title: Text(
                    'Order ID: $orderId',
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                  subtitle: Text(
                    'Delivery Time: ${deliveryTime.toLocal()}',
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: Text(
                    status,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: status == 'Delivered' ? Colors.green : Colors.blueAccent,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedOrder = order;
                    });
                    _panelController.open();
                  },
                ),
              );
            },
          ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 0,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            panelBuilder: (sc) => SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.all(16.0),
              child: _buildSlidingPanel(),
            ),
          ),
        ],
      )),
    );
  }
}

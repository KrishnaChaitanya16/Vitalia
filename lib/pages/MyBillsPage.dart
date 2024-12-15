import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Mybillspage extends StatefulWidget {
  const Mybillspage({super.key});

  @override
  State<Mybillspage> createState() => _MybillspageState();
}

class _MybillspageState extends State<Mybillspage> with SingleTickerProviderStateMixin {
  late TabController _tabController;  // Declare TabController

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with the correct length
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();  // Dispose TabController when done
    super.dispose();
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
    );
  }

  // Build the Paid Bills section
  Widget _buildPaidBillsSection() {
    return Center(
      child: Text(
        "No Paid Bills available.",
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }

  // Build the Receipts section
  Widget _buildReceiptsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: 5, // Example: replace with the actual number of receipts
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: Text(
                "Receipt #${index + 1}",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Date: 2024-12-14\nAmount: \$${(index + 1) * 50}",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              onTap: () {
                // Handle view receipt action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Viewing receipt #${index + 1}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

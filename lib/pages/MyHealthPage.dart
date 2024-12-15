import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

class Myhealthpage extends StatefulWidget {
  const Myhealthpage({super.key});

  @override
  State<Myhealthpage> createState() => _MyhealthpageState();
}

class _MyhealthpageState extends State<Myhealthpage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _uploadedRecords = [];
  late PageController _pageController;  // Declare the controller here
  double _indicatorPosition = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the controller in initState
    _pageController = PageController();
  }

  @override
  void dispose() {
    // Dispose the controller when done
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Health Records",
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.5),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.black),
            onPressed: () {
              // Add your filter functionality here
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildCustomTabBar(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _indicatorPosition = index.toDouble();
          });
        },
        children: [
          _buildHealthRecordsPage(),
          const Center(child: Text("Photos Page")),
          const Center(child: Text("Prescriptions Page")),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        onPressed: _uploadHealthRecord,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Custom TabBar with rounded rectangular highlight for the selected tab
  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("Medication", 'assets/icons/medicine.png', 0),
          _buildTabItem("Reports", 'assets/icons/test.png', 1),
          _buildTabItem("Prescriptions", 'assets/icons/prescription.png', 2),
        ],
      ),
    );
  }

  // Build each individual tab item with a rounded rectangular background for the selected tab
  Widget _buildTabItem(String label, String iconPath, int index) {
    bool isSelected = _indicatorPosition == index.toDouble();

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(30), // rounded rectangle
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24,  // Set explicit size for icons
              height: 24, // Set explicit size for icons
              fit: BoxFit.contain,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Health Records Page UI
  Widget _buildHealthRecordsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 10),
          Expanded(
            child: _uploadedRecords.isEmpty
                ? const Center(child: Text("No health records uploaded yet."))
                : ListView.builder(
              itemCount: _uploadedRecords.length,
              itemBuilder: (context, index) {
                var record = _uploadedRecords[index];
                return ListTile(
                  leading: const Icon(Icons.file_copy, color: Colors.green),
                  title: Text(record['fileName'] ?? "Unknown"),
                  subtitle: Text("Uploaded on: ${record['uploadDate']}"),
                  onTap: () => _viewFile(record['fileUrl'] ?? ""),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Upload Health Record
  Future<void> _uploadHealthRecord() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    var file = result.files.single;
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

    setState(() {
      _uploadedRecords.add({
        'fileName': file.name,
        'uploadDate': DateTime.now().toString(),
        'fileUrl': file.path ?? '',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Health record uploaded successfully")),
    );
  }

  // View uploaded file
  void _viewFile(String fileUrl) {
    print("View file at: $fileUrl");
  }
}

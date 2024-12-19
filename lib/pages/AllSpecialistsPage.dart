import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/pages/SpecialistsPage.dart';

class Allspecialistspage extends StatefulWidget {
  const Allspecialistspage({super.key});

  @override
  State<Allspecialistspage> createState() => _AllspecialistspageState();
}

class _AllspecialistspageState extends State<Allspecialistspage> {
  // List of specialists, should be the same as your grid data
  final List<Map<String, String>> _specialists = [
    {'label': 'Heart Issues', 'image': 'assets/icons/heart.png'},
    {'label': 'Dental Care', 'image': 'assets/icons/tooth.png'},
    {'label': 'Skin & Hair', 'image': 'assets/icons/hair.png'},
    {'label': 'Child Specialist', 'image': 'assets/icons/pediatric.png'},
    {'label': 'Women\'s Health', 'image': 'assets/icons/pregnant.png'},
    {'label': 'Brain and Nerves', 'image': 'assets/icons/brain.png'},
    {'label': 'Bones & Joints', 'image': 'assets/icons/orthopedics.png'},
    {'label': 'Eye Specialist', 'image': 'assets/icons/eye.png'},
    {'label': 'Mental Wellness', 'image': 'assets/icons/img.png'},
    {'label': 'Ear, Nose,Throat', 'image': 'assets/icons/nasal.png'},
    {'label': 'Kidney Issues', 'image': 'assets/icons/kidney.png'},
    {'label': 'General Surgeon', 'image': 'assets/icons/neurosurgeon.png'},
    {'label': 'Physiotherapy', 'image': 'assets/icons/physiotherapist.png'},
    {'label': 'Nutritionist', 'image': 'assets/icons/salad.png'},
    {'label': 'General Physician', 'image': 'assets/icons/stethoscope.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Specialists", style: GoogleFonts.nunito()),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _specialists.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Handle navigation or any other action when a list item is tapped
                // For example, navigate to a specialist's detail page:
                 Navigator.push(context, MaterialPageRoute(builder: (context) => Specialistspage(
                   specialistType: _specialists[index]['label']!,
                 )));
              },
              child: Card(
                elevation: 2,
                color: Colors.lightBlue.shade100.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Image.asset(
                    _specialists[index]['image']!,
                    height: 40,
                    color: const Color.fromRGBO(29, 54, 107, 1), // Set the image color
                  ),
                  title: Text(
                    _specialists[index]['label']!,
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

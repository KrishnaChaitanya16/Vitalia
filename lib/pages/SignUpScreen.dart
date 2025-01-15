import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '/pages/HomePage.dart';
import '/pages/LoginScreen.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Basic Details Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();


  // Vitals Controllers

  String _bloodGroup = 'A+';
  bool _isSmokingYes = false;
  bool _isAlcoholYes = false;

  // Medical History
  List<String> _selectedAllergies = [];
  List<String> _selectedConditions = [];
  List<String> _medications=[];
  List<String> _surgeries = [];
  TextEditingController _medicationsController = TextEditingController();
  TextEditingController _surgeriesController = TextEditingController();

  final List<String> _allergiesList = ['Peanuts', 'Dairy', 'Latex', 'Penicillin', 'Other'];
  final List<String> _conditionsList = ['Diabetes', 'Hypertension', 'Asthma', 'Heart Disease'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  void _addMedication() {
    if (_medicationsController.text.isNotEmpty) {
      setState(() {
        _medications.add(_medicationsController.text);
        _medicationsController.clear();
      });
    }
  }
  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }
  void _addSurgery() {
    if (_surgeriesController .text.isNotEmpty) {
      setState(() {
        _surgeries.add(_surgeriesController .text);
        _surgeriesController.clear();
      });
    }
  }Widget _buildMedicalRecordsCard() {
    return _buildCard(
      title: 'Medical Records',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medicationsController,
                    decoration: InputDecoration(
                      labelText: 'Add Medication',
                      prefixIcon: Icon(Icons.medication),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addMedication,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _medications.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  onDeleted: () => _removeMedication(entry.key),
                  backgroundColor: Colors.blue[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _surgeriesController,
                    decoration: InputDecoration(
                      labelText: 'Add Surgery',
                      prefixIcon: Icon(Icons.medical_services),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addSurgery,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _surgeries.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  onDeleted: () => _removeSurgery(entry.key),
                  backgroundColor: Colors.blue[100],
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _registerUser() async {
    double height = double.tryParse(_heightController.text) ?? 0;
    double weight = double.tryParse(_weightController.text) ?? 0;
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          // Basic Details
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _dobController.text.trim(),
          'gender': _selectedGender,

          // Vitals
          'height': height,
          'weight': weight,
          'bloodGroup': _bloodGroup,
          'smoking': _isSmokingYes,
          'alcohol': _isAlcoholYes,

          // Medical History
          'allergies': _selectedAllergies,
          'conditions': _selectedConditions,
          'medications': _medications,
          'surgeries': _surgeries,
          'createdAt': DateTime.now(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
  void _removeSurgery(int index) {
    setState(() {
      _surgeries.removeAt(index);
    });
  }
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(29, 54, 107, 1),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  List<Step> getSteps() {
    return [
      Step(
        stepStyle: StepStyle(color: _currentStep == 0 ? Colors.blueAccent : Colors.grey,),

        title: const Text('Basic Details'),
        content: Column(
          children: [
            _buildCard(
              title: 'Personal Information',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  readOnly: true, // Makes the field non-editable
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.date_range_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dialogBackgroundColor: Colors.white, // Set the background color to white
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      _dobController.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format as yyyy-MM-dd
                    }
                  },
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please select your DOB' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Security',
              children: [
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) =>
                  (value?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Additional Details',
              children: [
                DropdownButtonFormField<String>(

                  value: _selectedGender,
                  dropdownColor: Colors.white,
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),

                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });

                  },
                  decoration: InputDecoration(


                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value == null ? 'Please select your gender' : null,
                ),
              ],
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        stepStyle: StepStyle(color:_currentStep == 1 ? Colors.blueAccent : Colors.grey,),
        title: const Text('Vitals'),
        content: Column(
          children: [
          _buildCard(
          title: 'Body Measurements',
          children: [
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                final height = double.tryParse(value);
                if (height == null || height < 100 || height > 220) {
                  return 'Height must be between 100 and 220 cm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight < 30 || weight > 150) {
                  return 'Weight must be between 30 and 150 kg';
                }
                return null;
              },
            ),
          ],
        ),

            const SizedBox(height: 16),
            _buildCard(
              title: 'Blood Information',
              children: [
                DropdownButtonFormField<String>(
                  value: _bloodGroup,
                  dropdownColor: Colors.white,
                  items: _bloodGroups
                      .map((group) => DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _bloodGroup = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Lifestyle',
              children: [
                SwitchListTile(
                  title: Row(
                    children: [
                      Icon(Icons.smoking_rooms, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Do you smoke?'),
                    ],
                  ),
                  value: _isSmokingYes,
                  onChanged: (bool value) {
                    setState(() {
                      _isSmokingYes = value;
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
                SwitchListTile(
                  title: Row(
                    children: [
                      Icon(Icons.local_bar, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Do you consume alcohol?'),
                    ],
                  ),
                  value: _isAlcoholYes,
                  onChanged: (bool value) {
                    setState(() {
                      _isAlcoholYes = value;
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        stepStyle: StepStyle(color:_currentStep == 2 ? Colors.blueAccent : Colors.grey,),
        title: const Text('Medical History'),
        content: Column(
          children: [
            _buildCard(
              title: 'Allergies & Conditions',
              children: [
                Text('Allergies',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                Wrap(
                  spacing: 8.0,
                  children: _allergiesList.map((allergy) {
                    return FilterChip(backgroundColor: Colors.white,

                      label: Text(allergy),
                      selected: _selectedAllergies.contains(allergy),
                      selectedColor: Colors.blue[100],
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedAllergies.add(allergy);
                          } else {
                            _selectedAllergies.remove(allergy);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Medical Conditions',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                Wrap(
                  spacing: 8.0,
                  children: _conditionsList.map((condition) {
                    return FilterChip(
                      backgroundColor: Colors.white,
                      label: Text(condition),
                      selected: _selectedConditions.contains(condition),
                      selectedColor: Colors.blue[100],
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMedicalRecordsCard(),

          ],
        ),
        isActive: _currentStep >= 2,
      ),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              steps: getSteps(),
              elevation: 0,
              onStepContinue: () {
                if (_currentStep < getSteps().length - 1) {
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  _registerUser();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep--;
                  });
                }
              },
              controlsBuilder: (context, controls) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      if (_currentStep < getSteps().length - 1)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controls.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(29, 54, 107, 1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controls.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(29, 54, 107, 1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controls.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back',style: TextStyle(color: Colors.black),),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
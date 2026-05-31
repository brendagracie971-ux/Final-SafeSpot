import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  String? gender;
  String? bloodGroup;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 20),

              const Icon(Icons.shield, size: 70, color: Color(0xFF8B0000)),

              const SizedBox(height: 10),

              const Text(
                "SafeSpot Registration",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              _buildField("Full Name", nameController),
              _buildField("Contact Number", contactController),

              _buildDropdown(
                label: "Gender",
                value: gender,
                items: ["Male", "Female", "Other"],
                onChanged: (val) {
                  setState(() {
                    gender = val;
                  });
                },
              ),

              _buildDropdown(
                label: "Blood Group",
                value: bloodGroup,
                items: ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
                onChanged: (val) {
                  setState(() {
                    bloodGroup = val;
                  });
                },
              ),

              _buildField("Allergies", allergiesController),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  minimumSize: const Size(double.infinity, 55),
                ),
                onPressed: () async {
                    // simple validation (optional but important)
                    if (nameController.text.isEmpty || contactController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in name and contact"),
                        ),
                      );
                      return;
                    }

                    await StorageService.saveUser(
                      name: nameController.text,
                      contact: contactController.text,
                      gender: gender ?? "",
                      blood: bloodGroup ?? "",
                      allergies: allergiesController.text,
                    );

                    // go to next screen (temporary placeholder)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                child: const Text("REGISTER"),
                  
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
  required String label,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),

        filled: true,
        fillColor: const Color(0xFF1A1A1A),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF8B0000),
            width: 2,
          ),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
    ),
  );
}
}
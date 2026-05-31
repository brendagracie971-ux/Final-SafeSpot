import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bloodController = TextEditingController();
  final allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nameController.text = prefs.getString("name") ?? "";
      phoneController.text = prefs.getString("phone") ?? "";
      bloodController.text = prefs.getString("blood") ?? "";
      allergyController.text = prefs.getString("allergy") ?? "";
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("name", nameController.text);
    await prefs.setString("phone", phoneController.text);
    await prefs.setString("blood", bloodController.text);
    await prefs.setString("allergy", allergyController.text);

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  Widget buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _infoTile("Name", nameController.text),
        _infoTile("Phone", phoneController.text),
        _infoTile("Blood Group", bloodController.text),
        _infoTile("Allergies", allergyController.text),

      ],
    );
  }

  Widget buildEditMode() {
    return Column(
      children: [

        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name"),
        ),

        TextField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: "Phone Number"),
          keyboardType: TextInputType.phone,
        ),

        TextField(
          controller: bloodController,
          decoration: const InputDecoration(labelText: "Blood Group"),
        ),

        TextField(
          controller: allergyController,
          decoration: const InputDecoration(labelText: "Allergies"),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? "Not set" : value,
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53935),
        elevation: 0,
        actions: [

          TextButton(
            onPressed: () {
              if (isEditing) {
                saveData();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
            child: Text(
              isEditing ? "SAVE" : "EDIT",
                style: const TextStyle(
                 color: Color(0xFFE53935),
                 fontWeight: FontWeight.bold,
                )
            ),
          ),

        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: isEditing ? buildEditMode() : buildViewMode(),
      ),
    );
  }
}
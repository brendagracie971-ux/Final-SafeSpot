import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;
  String? photoUrl;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bloodController = TextEditingController();
  final ageController = TextEditingController();
  final medicalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadUser());
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    bloodController.dispose();
    ageController.dispose();
    medicalController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final uid = provider.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data != null) {
      nameController.text = data['fullName'] ?? '';
      phoneController.text = data['phoneNumber'] ?? '';
      bloodController.text = data['bloodGroup'] ?? '';
      ageController.text = data['age']?.toString() ?? '';
      medicalController.text = data['medicalNotes'] ?? '';
      photoUrl = data['photoUrl'];
    }

    setState(() => isLoading = false);
  }

  Future<void> saveData() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final uid = provider.uid;
    if (uid == null) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': nameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'bloodGroup': bloodController.text.trim(),
        'age': ageController.text.trim(),
        'medicalNotes': medicalController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await provider.refresh();

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully")),
      );
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Update failed: $e")));
    }
  }

  Widget buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(Icons.person, "Full Name", nameController.text),
        _infoTile(Icons.phone, "Phone Number", phoneController.text),
        _infoTile(Icons.bloodtype, "Blood Group", bloodController.text),
        _infoTile(Icons.cake, "Age", ageController.text),
        _infoTile(
          Icons.medical_information,
          "Medical Notes",
          medicalController.text,
        ),
      ],
    );
  }

  Widget buildEditMode() {
    return Column(
      children: [
        _editField(nameController, "Full Name", Icons.person),
        const SizedBox(height: 12),
        _editField(
          phoneController,
          "Phone Number",
          Icons.phone,
          type: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _editField(bloodController, "Blood Group", Icons.bloodtype),
        const SizedBox(height: 12),
        _editField(
          ageController,
          "Age",
          Icons.cake,
          type: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _editField(
          medicalController,
          "Medical Notes\n(e.g. I have diabetes, asthma, cancer...)",
          Icons.medical_information,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _editField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "Not set" : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: isSaving
                ? null
                : () {
                    if (isEditing) {
                      saveData();
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.redAccent,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEditing ? "SAVE" : "EDIT",
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile photo (display only, no upload for now)
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.redAccent,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 55, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 8),

            // Name display under avatar
            Text(
              nameController.text.isEmpty ? "Your Name" : nameController.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // Blood group badge
            if (bloodController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "🩸 ${bloodController.text}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Fields
            isEditing ? buildEditMode() : buildViewMode(),

            const SizedBox(height: 20),

            // SOS info reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This information will be included in your SOS alert messages.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

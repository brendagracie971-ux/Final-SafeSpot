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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bloodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadUser());
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
    }

    setState(() => isLoading = false);
  }

  Future<void> saveData() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final uid = provider.uid;

    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'fullName': nameController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'bloodGroup': bloodController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await provider.refresh();

    setState(() => isEditing = false);

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
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? "Not set" : value,
            style: const TextStyle(
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          TextButton(
            onPressed: () {
              if (isEditing) {
                saveData();
              } else {
                setState(() => isEditing = true);
              }
            },
            child: Text(
              isEditing ? "SAVE" : "EDIT",
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
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
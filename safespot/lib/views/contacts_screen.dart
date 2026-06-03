import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {

  Future<void> addOrUpdateContact({
    String? docId,
    required String name,
    required String phone,
  }) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final uid = provider.uid;

    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('emergencyContacts');

    if (docId == null) {
      await ref.add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.doc(docId).update({
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteContact(String docId) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final uid = provider.uid;

    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('emergencyContacts')
        .doc(docId)
        .delete();
  }

  void openDialog({String? docId, String? oldName, String? oldPhone}) {
    final nameController = TextEditingController(text: oldName ?? '');
    final phoneController = TextEditingController(text: oldPhone ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Add Contact" : "Edit Contact"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                await addOrUpdateContact(
                  docId: docId,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final uid = provider.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("No user found")),
      );
    }

    final contactsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('emergencyContacts');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.red,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => openDialog(),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: contactsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No emergency contacts"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['phone'] ?? ''),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => openDialog(
                        docId: doc.id,
                        oldName: data['name'],
                        oldPhone: data['phone'],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteContact(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
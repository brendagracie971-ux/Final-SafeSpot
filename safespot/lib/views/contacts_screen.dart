import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<String> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      contacts = prefs.getStringList("contacts") ?? [];
    });
  }

  Future<void> saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("contacts", contacts);
  }

  void openContactDialog({int? index}) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    if (index != null) {
      final parts = contacts[index].split(":");
      nameController.text = parts[0];
      phoneController.text = parts[1];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? "Add Contact" : "Edit Contact"),

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
              onPressed: () {
                Navigator.pop(context); // ❌ cancel
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                String newContact =
                    "${nameController.text}:${phoneController.text}";

                setState(() {
                  if (index == null) {
                    contacts.add(newContact);
                  } else {
                    contacts[index] = newContact;
                  }
                });

                await saveContacts();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteContact(int index) async {
    setState(() {
      contacts.removeAt(index);
    });
    await saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.red,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => openContactDialog(),
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final parts = contacts[index].split(":");

          return ListTile(
            title: Text(parts[0]),
            subtitle: Text(parts[1]),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openContactDialog(index: index),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteContact(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
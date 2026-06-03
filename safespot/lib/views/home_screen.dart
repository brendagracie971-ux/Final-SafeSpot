import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_provider.dart';
import 'settings_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;

  Future<void> sendSOS() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      final uid = provider.uid!;
      final user = provider.userData;

      // 1. Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location services are disabled";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw "Location permission permanently denied";
      }

      // 2. Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Google Maps link
      String googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      String message =
          "🚨 EMERGENCY ALERT!\nMy location: $googleMapsLink";

      // 4. Save SOS to Firestore
      await FirebaseFirestore.instance.collection("sos_alerts").add({
        "userId": uid,
        "userName": user?['fullName'] ?? "Unknown",
        "phone": user?['phoneNumber'] ?? "",
        "location": {
          "latitude": position.latitude,
          "longitude": position.longitude,
        },
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 5. Get emergency contacts
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .get();

      if (contactsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No emergency contacts found")),
        );
        setState(() => isLoading = false);
        return;
      }

      // 6. Send SOS to ALL contacts
      for (final doc in contactsSnapshot.docs) {
        final data = doc.data();
        final phone = data['phone'];

        if (phone == null || phone.toString().isEmpty) continue;

        final Uri smsUri = Uri.parse(
          "sms:$phone?body=${Uri.encodeComponent(message)}",
        );

        launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
      }

      // 7. Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 SOS SENT SUCCESSFULLY")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SOS Failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        title: Text(
          "SafeSpot - ${provider.userData?['fullName'] ?? ''}",
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
      ),

      body: Column(
        children: [
          // MAP CARD
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Location & Nearby Help",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Hospitals • Police • Pharmacies",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Icon(Icons.map, color: Colors.redAccent, size: 40),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SOS BUTTON
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFB00020), Color(0xFFFF1744)],
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isLoading ? null : sendSOS,
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SEND SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTile(Icons.contacts, "Emergency Contacts", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactsScreen(),
                    ),
                  );
                }),

                _buildTile(Icons.person, "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                }),

                _buildTile(Icons.settings, "Settings", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
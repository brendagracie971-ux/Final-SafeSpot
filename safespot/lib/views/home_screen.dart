import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // 🚨 SOS FUNCTION
  Future<void> sendSOS() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      String message =
          "🚨 EMERGENCY ALERT!\nMy location: $googleMapsLink";

      String phoneNumber = "2376XXXXXXX"; // replace with real contact

      final Uri smsUri = Uri.parse(
        "sms:$phoneNumber?body=${Uri.encodeComponent(message)}",
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot open SMS app")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        title: const Text("SafeSpot"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),

      body: Column(
        children: [

          // 🗺 MAP SECTION
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
                    "Nearby Emergency Services",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Hospitals • Clinics • Police • Pharmacies",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Icon(Icons.map, color: Colors.redAccent, size: 40),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🚨 SOS BUTTON
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFB00020), Color(0xFFFF1744)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: sendSOS,
              child: const Center(
                child: Text(
                  "SEND SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 📌 OPTIONS
         Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [

              _buildTile(
                Icons.contacts,
                "Emergency Contacts",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactsScreen(),
                    ),
                  );
                },
         ),

      _buildTile(
        Icons.person,
        "Profile",
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            ),
          );
        },
      ),

      _buildTile(
        Icons.location_on,
        "Share Location",
        () {
          // later: direct GPS share feature
        },
      ),

      _buildTile(
      Icons.settings,
      "Settings",
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
      },
    ),
    ],
  ),
),
        ],
      ),
    );
  }

  // 📌 TILE BUILDER
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
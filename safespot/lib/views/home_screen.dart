import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/providers/user_provider.dart';
import 'settings_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'contacts_screen.dart';

const _channel = MethodChannel('com.example.safespot/sos_service');

Future<void> startSosService() async {
  try {
    await _channel.invokeMethod('startService');
    debugPrint('✅ SOS Service started');
  } catch (e) {
    debugPrint('⚠️ Service start error: $e');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      await _requestBatteryOptimizationExemption();
      await cacheContactsLocally();
      await startSosService();
      await _checkAccessibilityService();
    });
  }

  Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
      await Permission.sms.request();
      await Permission.location.request();
    } catch (e) {
      debugPrint('⚠️ Permission error: $e');
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
        debugPrint('✅ Battery optimization exemption requested');
      } else {
        debugPrint('✅ Battery optimization already exempted');
      }
    } catch (e) {
      debugPrint('⚠️ Battery optimization error: $e');
    }
  }

  Future<void> _checkAccessibilityService() async {
    // Check if already enabled using shared prefs flag
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('accessibility_asked') ?? false;
    if (alreadyAsked) return;

    // Show dialog once
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.accessibility_new, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Enable SOS When Screen is OFF",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          "To send SOS alerts even when your screen is OFF, SafeSpot needs Accessibility permission.\n\n"
          "Steps:\n"
          "1. Tap 'Enable Now'\n"
          "2. Find 'SafeSpot' in the list\n"
          "3. Toggle it ON\n\n"
          "This is required for emergency detection when the screen is locked.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('accessibility_asked', true);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Later", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await prefs.setBool('accessibility_asked', true);
              if (mounted) Navigator.pop(context);
              try {
                await _channel.invokeMethod('openAccessibilitySettings');
              } catch (e) {
                debugPrint('Error opening accessibility settings: $e');
              }
            },
            child: const Text(
              "Enable Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> cacheContactsLocally() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergencyContacts')
          .get();

      final numbers = snapshot.docs
          .map((doc) => doc['phone'].toString())
          .where((phone) => phone.isNotEmpty)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sos_contacts', numbers.join(','));

      final provider = Provider.of<UserProvider>(context, listen: false);
      await prefs.setString(
        'sos_user_name',
        provider.userData?['fullName'] ?? 'Unknown',
      );
      await prefs.setString(
        'sos_user_phone',
        provider.userData?['phoneNumber'] ?? 'Unknown',
      );
      await prefs.setString(
        'sos_user_blood',
        provider.userData?['bloodGroup'] ?? 'Unknown',
      );
      await prefs.setString(
        'sos_user_age',
        provider.userData?['age']?.toString() ?? 'Unknown',
      );
      await prefs.setString(
        'sos_user_medical',
        provider.userData?['medicalNotes'] ?? 'None',
      );
      await prefs.setString(
        'sos_user_photo',
        provider.userData?['photoUrl'] ?? '',
      );

      debugPrint('✅ Contacts cached: $numbers');
    } catch (e) {
      debugPrint('❌ Cache error: $e');
    }
  }

  String _cleanNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '237${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+') && !cleaned.startsWith('237')) {
      cleaned = '237$cleaned';
    }
    cleaned = cleaned.replaceAll('+', '');
    return cleaned;
  }

  String _buildSOSMessage({
    required String name,
    required String phone,
    required String bloodGroup,
    required String age,
    required String medicalNotes,
    required String mapsLink,
  }) {
    return "🚨 SOS ALERT - EMERGENCY!\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "👤 Name: $name\n"
        "🎂 Age: $age\n"
        "📞 Phone: $phone\n"
        "🩸 Blood Group: $bloodGroup\n"
        "🏥 Medical Notes: $medicalNotes\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "📍 Live Location:\n$mapsLink\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "⚠️ Please help immediately!";
  }

  Future<void> sendSOS() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      final uid = provider.uid!;
      final user = provider.userData;

      // 1. Check location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location services are disabled";

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

      // 3. Build message
      String mapsLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      String name = user?['fullName'] ?? "Unknown";
      String phone = user?['phoneNumber'] ?? "Unknown";
      String bloodGroup = user?['bloodGroup'] ?? "Unknown";
      String age = user?['age']?.toString() ?? "Unknown";
      String medicalNotes = user?['medicalNotes'] ?? "None";
      String photoUrl = user?['photoUrl'] ?? "";

      String message = _buildSOSMessage(
        name: name,
        phone: phone,
        bloodGroup: bloodGroup,
        age: age,
        medicalNotes: medicalNotes,
        mapsLink: mapsLink,
      );

      // 4. Save to Firestore
      await FirebaseFirestore.instance.collection("sos_alerts").add({
        "userId": uid,
        "userName": name,
        "phone": phone,
        "bloodGroup": bloodGroup,
        "age": age,
        "medicalNotes": medicalNotes,
        "photoUrl": photoUrl,
        "location": {
          "latitude": position.latitude,
          "longitude": position.longitude,
        },
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 5. Get contacts
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

      final List<String> numbers = contactsSnapshot.docs
          .map((doc) => doc.data()['phone'].toString())
          .where((p) => p.isNotEmpty)
          .toList();

      // 6. Check internet
      final connectivityResult = await Connectivity().checkConnectivity();
      final bool isOnline = connectivityResult != ConnectivityResult.none;

      // 7. Always send SMS first
      await _channel.invokeMethod('sendSOS', {
        'numbers': numbers,
        'message': message,
      });

      // 8. Send WhatsApp if online
      if (isOnline) {
        for (final number in numbers) {
          try {
            final cleaned = _cleanNumber(number);

            // Include photo URL in message if available
            final fullMessage = photoUrl.isNotEmpty
                ? "📸 Photo: $photoUrl\n\n$message"
                : message;

            final whatsappUri = Uri.parse(
              "whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(fullMessage)}",
            );
            if (await canLaunchUrl(whatsappUri)) {
              await launchUrl(
                whatsappUri,
                mode: LaunchMode.externalApplication,
              );
              await Future.delayed(const Duration(seconds: 2));
            } else {
              final fallbackUri = Uri.parse(
                "https://wa.me/$cleaned?text=${Uri.encodeComponent(fullMessage)}",
              );
              await launchUrl(
                fallbackUri,
                mode: LaunchMode.externalApplication,
              );
              await Future.delayed(const Duration(seconds: 2));
            }
            debugPrint('✅ WhatsApp sent to: $number');
          } catch (e) {
            debugPrint('❌ WhatsApp failed for $number: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚨 SOS sent via SMS + WhatsApp!")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🚨 SOS sent via SMS!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SOS Failed: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("SafeSpot - ${provider.userData?['fullName'] ?? ''}"),
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
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  );
                }),
                _buildTile(Icons.person, "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }),
                _buildTile(Icons.settings, "Settings", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

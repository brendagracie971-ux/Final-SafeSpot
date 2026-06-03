import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SosService {

  static Future<Position> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<void> sendSOS({
    required String userId,
    required String userName,
    required String phone,
  }) async {

    Position pos = await _getLocation();

    await FirebaseFirestore.instance.collection("sos_alerts").add({
      "userId": userId,
      "userName": userName,
      "phone": phone,
      "location": {
        "latitude": pos.latitude,
        "longitude": pos.longitude,
      },
      "status": "active",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
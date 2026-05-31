import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  LatLng? userLocation;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        userLocation = newLocation;
        loading = false;
      });

      // 🚨 ONLY MOVE CAMERA AFTER MAP IS READY
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = const LatLng(3.8480, 11.5021);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeSpot Map"),
        backgroundColor: Colors.red,
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation ?? fallback,
              zoom: 14,
            ),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            onMapCreated: (controller) {
              mapController = controller;

              // 🚨 important: re-center once map is ready
              if (userLocation != null) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(userLocation!, 16),
                );
              }
            },
          ),

          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
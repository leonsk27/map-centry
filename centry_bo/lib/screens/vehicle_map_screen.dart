import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleMapScreen extends StatefulWidget {
  const VehicleMapScreen({super.key});

  @override
  State<VehicleMapScreen> createState() => _VehicleMapScreenState();
}

class _VehicleMapScreenState extends State<VehicleMapScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(-17.393151, -66.27334);
  StreamSubscription<Position>? _positionStream;
  bool _mapInitialized = false;
  final String _documentId = "pTrNxDbd11qMlGgvnwJS";

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
    _startLocationTracking();
  }

  Future<void> _loadInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  return Future.error('Los servicios de ubicación están deshabilitados.');
}

LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    return Future.error('Permiso de ubicación denegado.');
  }
}

if (permission == LocationPermission.deniedForever) {
  return Future.error('Permiso denegado permanentemente.');
}

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _initialPosition = LatLng(pos.latitude, pos.longitude);
    });
    if (_mapController != null) {
      _mapController!.moveCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (_mapInitialized) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      }

      FirebaseFirestore.instance.collection("autos").doc(_documentId).set({
        "placa": "Mi Vehículo",
        "ubicacion": GeoPoint(position.latitude, position.longitude),
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16),
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        _mapInitialized = true;
      },
    );
  }
}

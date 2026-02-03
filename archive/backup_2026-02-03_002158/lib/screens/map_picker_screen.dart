import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerScreen({super.key, required this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _controller;
  LatLng? _picked;
  String? _pickedAddress;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPosition;
    _updateAddressFor(_picked);
  }

  Future<void> _updateAddressFor(LatLng? latLng) async {
    if (latLng == null) return;
    setState(() => _loadingAddress = true);
    try {
      final places = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.postalCode,
          p.country,
        ];
        final addr = parts.where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() => _pickedAddress = addr);
      }
    } catch (_) {
      // ignore errors, keep address null
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) return;
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        final latLng = LatLng(pos.latitude, pos.longitude);
        _controller.animateCamera(CameraUpdate.newLatLng(latLng));
        setState(() => _picked = latLng);
        await _updateAddressFor(latLng);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick delivery location'),
        actions: [
          TextButton(
            onPressed: _picked == null
                ? null
                : () {
                    Navigator.pop(context, _picked);
                  },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 14,
            ),
            onMapCreated: (c) => _controller = c,
            onTap: (latLng) {
              setState(() => _picked = latLng);
              _updateAddressFor(latLng);
            },
            markers: _picked == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _picked!,
                    ),
                  },
          ),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'loc',
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          if (_pickedAddress != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Card(
                color: const Color.fromRGBO(255, 255, 255, 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _pickedAddress!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_loadingAddress) const SizedBox(width: 8),
                          if (_loadingAddress)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (_loadingAddress) const SizedBox(height: 6),
                      if (_loadingAddress)
                        const SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

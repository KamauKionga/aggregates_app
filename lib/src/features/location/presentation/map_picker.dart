import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/location_model.dart';
import '../location_providers.dart';
import '../../auth/domain/models/user_role.dart';
import '../../auth/auth_providers.dart';

/// MapPicker widget
/// - shows map with draggable pin
/// - search by address (geocoding fallback for Places)
/// - saves lat, lng, address via LocationSaveService
class MapPicker extends ConsumerStatefulWidget {
  final LocationModel? initialLocation;
  final bool
  allowShowOtherEntities; // if false, do not show quarry/truck markers
  final bool hasActiveOrder; // if true for buyers show only distance & ETA

  const MapPicker({
    super.key,
    this.initialLocation,
    this.allowShowOtherEntities = true,
    this.hasActiveOrder = false,
  });

  @override
  ConsumerState<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends ConsumerState<MapPicker> {
  GoogleMapController? _mapController;
  LatLng? _markerPos;
  String _address = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _markerPos = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _address = widget.initialLocation!.address;
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    try {
      setState(() => _loading = true);
      final permService = ref.read(locationPermissionServiceProvider);
      final granted = await permService.requestPermission();
      if (!granted) throw Exception('Location permission not granted');
      final pos = await permService.getCurrentPosition();
      setState(() {
        _markerPos = LatLng(pos.latitude, pos.longitude);
      });
      await _reverseGeocode(_markerPos!);
    } catch (e) {
      // ignore errors and allow manual search
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final places = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );
    if (places.isNotEmpty) {
      final p = places.first;
      setState(() {
        _address = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.country ?? ''}'
            .trim();
      });
    }
  }

  Future<void> _searchAndMove(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final list = await locationFromAddress(query);
      if (list.isNotEmpty) {
        final f = list.first;
        final pos = LatLng(f.latitude, f.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
        setState(() {
          _markerPos = pos;
          _address = query;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No results')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_markerPos == null) return;
    final model = LocationModel(
      latitude: _markerPos!.latitude,
      longitude: _markerPos!.longitude,
      address: _address,
    );
    final svc = ref.read(locationSaveServiceProvider);
    setState(() => _loading = true);
    try {
      await svc.saveLocation(location: model);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location saved')));
      Navigator.of(context).pop(model);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  double _distanceMetersTo(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  String _etaFromDistanceMeters(double meters, {double speedKmph = 40}) {
    final km = meters / 1000.0;
    final hours = km / speedKmph;
    final totalMinutes = (hours * 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        final role = user?.role;

        // Buyers with active order see distance & ETA only
        if (widget.hasActiveOrder && role == UserRole.buyer) {
          // For demonstration: show distance from current position to saved marker
          return _buildOrderStatusView();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Pick Location')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search address',
                        ),
                        onSubmitted: _searchAndMove,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _markerPos == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _markerPos!,
                              zoom: 15,
                            ),
                            onMapCreated: (c) => _mapController = c,
                            markers: {
                              Marker(
                                markerId: const MarkerId('selected'),
                                position: _markerPos!,
                                draggable: true,
                                onDragEnd: (p) async {
                                  setState(() => _markerPos = p);
                                  await _reverseGeocode(p);
                                },
                              ),
                            },
                          ),
                          if (role != UserRole.buyer &&
                              widget.allowShowOtherEntities) ...[
                            // placeholder other markers for quarries/trucks - in real app fetch from Firestore
                            const Positioned(
                              top: 16,
                              right: 16,
                              child: Chip(
                                label: Text('Quarries & Trucks visible'),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Address: $_address'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _saveLocation,
                      icon: const Icon(Icons.save),
                      label: _loading
                          ? const Text('Saving...')
                          : const Text('Save Location'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Auth error')),
    );
  }

  Widget _buildOrderStatusView() {
    // If we don't have a marker, we cannot compute distance; show placeholder
    if (_markerPos == null)
      return const Center(child: Text('Order active — location not available'));

    return FutureBuilder<Position>(
      future: ref.read(locationPermissionServiceProvider).getCurrentPosition(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (!snap.hasData)
          return const Center(child: Text('Location unavailable'));
        final pos = snap.data!;
        final current = LatLng(pos.latitude, pos.longitude);
        final meters = _distanceMetersTo(current, _markerPos!);
        final eta = _etaFromDistanceMeters(meters);
        return Scaffold(
          appBar: AppBar(title: const Text('Order status')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Distance remaining: ${(meters / 1000).toStringAsFixed(2)} km',
                ),
                const SizedBox(height: 8),
                Text('ETA: $eta'),
              ],
            ),
          ),
        );
      },
    );
  }
}

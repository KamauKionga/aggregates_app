import 'package:flutter/material.dart';
import 'invoice_screen.dart';
import '../services/app_settings.dart';
import 'admin_screen.dart';
import 'map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';

import 'orders_list_screen.dart';
import 'chat_screen.dart';
import '../services/order_service.dart';

class BuyerOrderScreen extends StatefulWidget {
  const BuyerOrderScreen({super.key});

  @override
  State<BuyerOrderScreen> createState() => _BuyerOrderScreenState();
}

class _BuyerOrderScreenState extends State<BuyerOrderScreen> {
  late AppSettings _settings;
  Map<String, int> _prices = {};

  String _selectedType = '';
  int _tons = 14;
  int _tonsPerVehicle = 14;
  double _distanceKm = 0.0; // distance from quarry to delivery

  // delivery selection
  LatLng? _deliveryLatLng;
  String? _deliveryAddress;
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  bool _loadingAddress = false;
  // quarry (assumed) - Kayole Junction (approx). Update if you want a different point.
  static const LatLng _quarryLatLng = LatLng(-1.2850, 36.8930);

  bool _loading = true;

  @override
  void dispose() {
    _detailsController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
    if (!mounted) return;
    setState(() {
      _prices = Map.from(_settings.prices);
      _tonsPerVehicle = _settings.tonsPerVehicle;
      _loading = false;
      _selectedType = _prices.keys.first;
    });
  }

  int get _numTrucks => (_tons / _tonsPerVehicle).ceil();

  int get _aggregatesCost => _prices[_selectedType]! * _tons;

  int get _transportCostPerTruck =>
      (_settings.transportRatePerKm * _distanceKm).ceil();

  int get _transportCostTotal => _transportCostPerTruck * _numTrucks;

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    double dLat = _degToRad(b.latitude - a.latitude);
    double dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final hav =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1) * cos(lat2) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  Future<void> _updateDeliveryAddressFor(LatLng? latLng) async {
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
        setState(() => _deliveryAddress = addr);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _setDeliveryToMyLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
          return;
        }
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _deliveryLatLng = latLng;
        _distanceKm = _calculateDistanceKm(_quarryLatLng, _deliveryLatLng!);
        _distanceController.text = _distanceKm.toStringAsFixed(2);
      });
      await _updateDeliveryAddressFor(_deliveryLatLng);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _pickOnMap() async {
    final initial = _deliveryLatLng ?? _quarryLatLng;
    final picked = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialPosition: initial),
      ),
    );
    if (picked != null) {
      setState(() {
        _deliveryLatLng = picked;
        _distanceKm = _calculateDistanceKm(_quarryLatLng, _deliveryLatLng!);
        _distanceController.text = _distanceKm.toStringAsFixed(2);
      });
      await _updateDeliveryAddressFor(_deliveryLatLng);
    }
  }

  void _proceedToInvoice() {
    final invoice = {
      'type': _selectedType,
      'tons': _tons,
      'pricePerTon': _prices[_selectedType]!,
      'aggregatesCost': _aggregatesCost,
      'distanceKm': _distanceKm,
      'numTrucks': _numTrucks,
      'transportCost': _transportCostTotal,
      'deliveryLocation': _deliveryLatLng == null
          ? null
          : {
              'lat': _deliveryLatLng!.latitude,
              'lng': _deliveryLatLng!.longitude,
            },
      'deliveryDetails': _detailsController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceScreen(invoice: invoice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Aggregates Order'),
        actions: [
          // Notifications (undelivered orders)
          FutureBuilder<int>(
            future: OrderService.getUndeliveredOrders().then((v) => v.length),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersListScreen()),
                  );
                  if (!mounted) return;
                  _loadSettings();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
              if (!mounted) return;
              _loadSettings();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Select aggregate type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const ValueKey('aggregate_type'),
              isExpanded: true,
              value: _selectedType,
              items: _prices.keys
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text('$k — Kshs. ${_prices[k]} per ton'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedType = v!;
              }),
            ),

            const SizedBox(height: 16),
            const Text(
              'Select tonnage (multiples of 14 tonnes)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              key: const ValueKey('tonnage'),
              value: _tons,
              isExpanded: true,
              items: List.generate(10, (i) => (i + 1) * _tonsPerVehicle)
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text('$t tons')),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _tons = v!;
              }),
            ),

            const SizedBox(height: 16),
            const Text(
              'Delivery location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_deliveryLatLng == null) ...[
              const Text('No delivery location selected'),
            ] else ...[
              SizedBox(
                height: 150,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _deliveryLatLng!,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('delivery'),
                      position: _deliveryLatLng!,
                    ),
                    Marker(
                      markerId: const MarkerId('quarry'),
                      position: _quarryLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                    ),
                  },
                  liteModeEnabled: true,
                  onTap: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              if (_deliveryAddress != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _deliveryAddress!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                const SizedBox(height: 6),
              ],
              Text(
                'Distance from quarry: ${_distanceKm.toStringAsFixed(2)} km',
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  key: const ValueKey('pin_location'),
                  onPressed: _setDeliveryToMyLocation,
                  child: const Text('Use my location'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const ValueKey('pick_map'),
                  onPressed: _pickOnMap,
                  child: const Text('Pick on Map'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'More details (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Distance from quarry (km)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance in km (auto or editable)',
                border: OutlineInputBorder(),
              ),
              controller: _distanceController,
              onChanged: (v) => setState(() {
                _distanceKm = double.tryParse(v) ?? _distanceKm;
              }),
            ),

            const SizedBox(height: 16),
            Text(
              'Tonnage per vehicle: $_tonsPerVehicle tonnes (configurable in admin)',
            ),
            const SizedBox(height: 12),

            ListTile(title: Text('Aggregates cost: Kshs. $_aggregatesCost')),
            ListTile(
              title: Text(
                'Transport cost (per truck): Kshs. $_transportCostPerTruck',
              ),
            ),
            ListTile(title: Text('Number of trucks: $_numTrucks')),
            ListTile(
              title: Text('Total transport cost: Kshs. $_transportCostTotal'),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _proceedToInvoice,
              child: const Text('Proceed to Invoice & Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

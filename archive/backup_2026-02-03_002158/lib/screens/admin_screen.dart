import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late AppSettings _settings;
  bool _loading = true;

  final Map<String, TextEditingController> _priceControllers = {};
  final TextEditingController _tonsController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _settings = await AppSettings.load();
    if (!mounted) return;
    for (final entry in _settings.prices.entries) {
      _priceControllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
    _tonsController.text = _settings.tonsPerVehicle.toString();
    _rateController.text = _settings.transportRatePerKm.toStringAsFixed(0);
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _tonsController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    for (final k in _priceControllers.keys) {
      _settings.prices[k] =
          int.tryParse(_priceControllers[k]!.text) ?? _settings.prices[k]!;
    }
    _settings.tonsPerVehicle =
        int.tryParse(_tonsController.text) ?? _settings.tonsPerVehicle;
    _settings.transportRatePerKm =
        double.tryParse(_rateController.text) ?? _settings.transportRatePerKm;
    await _settings.save();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Prices (Kshs. per ton)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._settings.prices.keys.map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _priceControllers[k],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: k),
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _tonsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tonnage per vehicle',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Transport rate per km (Kshs)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

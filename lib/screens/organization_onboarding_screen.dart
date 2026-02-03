import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../Models/trucker_model.dart';
import '../Models/document_model.dart';
import '../Models/truck_model.dart';
import '../Models/driver_model.dart';
import '../services/trucker_repository.dart';
import '../Models/enums.dart';

class OrganizationOnboardingScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String phone;

  const OrganizationOnboardingScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.phone,
  });

  @override
  State<OrganizationOnboardingScreen> createState() =>
      _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState
    extends State<OrganizationOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _incorpDate = TextEditingController();
  final _kra = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _repName = TextEditingController();
  final _repId = TextEditingController();

  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final t = TruckerModel(
      id: const Uuid().v4(),
      userId: widget.userId,
      email: widget.email,
      phone: widget.phone,
      type: TruckerType.organization,
      verificationStatus: VerificationStatus.incomplete,
      documents: [
        DocumentModel(
          id: 'incorporation',
          name: 'Certificate of Incorporation',
          type: 'pdf',
        ),
        DocumentModel(id: 'cr12', name: 'CR12', type: 'pdf'),
        DocumentModel(id: 'company_kra', name: 'Company KRA PIN', type: 'pdf'),
        DocumentModel(
          id: 'tax',
          name: 'Tax Compliance Certificate',
          type: 'pdf',
        ),
        DocumentModel(id: 'permit', name: 'Business Permit', type: 'pdf'),
      ],
      trucks: [],
      drivers: [],
    );

    await TruckerRepository.saveTrucker(t);

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationFleetScreen(truckerId: t.id),
      ),
    );
  }

  @override
  void dispose() {
    _companyName.dispose();
    _registrationNumber.dispose();
    _incorpDate.dispose();
    _kra.dispose();
    _address.dispose();
    _contact.dispose();
    _repName.dispose();
    _repId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _companyName,
                decoration: const InputDecoration(
                  labelText: 'Registered Company Name',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registrationNumber,
                decoration: const InputDecoration(
                  labelText: 'Business Registration Number',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _incorpDate,
                decoration: const InputDecoration(
                  labelText: 'Incorporation Date (YYYY-MM-DD)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kra,
                decoration: const InputDecoration(labelText: 'Company KRA PIN'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Physical Address',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(
                  labelText: 'Official Company Email',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repName,
                decoration: const InputDecoration(
                  labelText: 'Authorized Representative Name',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repId,
                decoration: const InputDecoration(
                  labelText: 'Authorized Representative ID',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrganizationFleetScreen extends StatefulWidget {
  final String truckerId;
  const OrganizationFleetScreen({super.key, required this.truckerId});

  @override
  State<OrganizationFleetScreen> createState() =>
      _OrganizationFleetScreenState();
}

class _OrganizationFleetScreenState extends State<OrganizationFleetScreen> {
  TruckerModel? _trucker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await TruckerRepository.getById(widget.truckerId);
    setState(() {
      _trucker = t;
      _loading = false;
    });
  }

  Future<void> _addTruck() async {
    final formKey = GlobalKey<FormState>();
    final reg = TextEditingController();
    final type = TextEditingController();
    final payload = TextEditingController(text: '14');
    final axles = TextEditingController();
    final fuel = TextEditingController();
    final year = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Truck'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: reg,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: type,
                  decoration: const InputDecoration(
                    labelText: 'Truck Type (Tipper/Lorry/Semi-Trailer)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                // For this product only 14-ton trucks are supported. Pre-fill and validate.
                TextFormField(
                  controller: payload,
                  decoration: const InputDecoration(
                    labelText: 'Payload (Tons)',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '14',
                  validator: (v) => v == null || v.isEmpty
                      ? 'Required'
                      : (double.tryParse(v) != 14.0
                            ? 'Only 14-ton trucks allowed'
                            : null),
                ),
                TextFormField(
                  controller: axles,
                  decoration: const InputDecoration(labelText: 'Axles Count'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: fuel,
                  decoration: const InputDecoration(labelText: 'Fuel Type'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: year,
                  decoration: const InputDecoration(
                    labelText: 'Year of Manufacture',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('save_truck'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final truck = TruckModel(
                id: const Uuid().v4(),
                registrationNumber: reg.text.trim(),
                truckType: type.text.trim(),
                payloadTons: double.tryParse(payload.text) ?? 0.0,
                axles: int.tryParse(axles.text) ?? 2,
                fuelType: fuel.text.trim(),
                year: int.tryParse(year.text) ?? 2000,
              );
              final t = _trucker!;
              final updated = TruckerModel(
                id: t.id,
                userId: t.userId,
                email: t.email,
                phone: t.phone,
                type: t.type,
                verificationStatus: t.verificationStatus,
                documents: t.documents,
                trucks: [...t.trucks, truck],
                drivers: t.drivers,
              );
              await TruckerRepository.update(updated);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res == true) await _load();
  }

  Future<void> _editTruck(TruckModel truck) async {
    final formKey = GlobalKey<FormState>();
    final reg = TextEditingController(text: truck.registrationNumber);
    final type = TextEditingController(text: truck.truckType);
    final payload = TextEditingController(text: truck.payloadTons.toString());
    final axles = TextEditingController(text: truck.axles.toString());
    final fuel = TextEditingController(text: truck.fuelType);
    final year = TextEditingController(text: truck.year.toString());

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Truck'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: reg,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: type,
                  decoration: const InputDecoration(
                    labelText: 'Truck Type (Tipper/Lorry/Semi-Trailer)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                // Payload is fixed at 14 tons for this app
                TextFormField(
                  controller: payload,
                  decoration: const InputDecoration(
                    labelText: 'Payload (Tons)',
                    helperText: '14 tons fixed',
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Required'
                      : (double.tryParse(v) != 14.0
                            ? 'Only 14-ton trucks allowed'
                            : null),
                ),
                TextFormField(
                  controller: axles,
                  decoration: const InputDecoration(labelText: 'Axles Count'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: fuel,
                  decoration: const InputDecoration(labelText: 'Fuel Type'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: year,
                  decoration: const InputDecoration(
                    labelText: 'Year of Manufacture',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('update_truck'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final t = _trucker!;
              final updatedTruck = TruckModel(
                id: truck.id,
                registrationNumber: reg.text.trim(),
                truckType: type.text.trim(),
                payloadTons: double.tryParse(payload.text) ?? 0.0,
                axles: int.tryParse(axles.text) ?? 2,
                fuelType: fuel.text.trim(),
                year: int.tryParse(year.text) ?? 2000,
              );
              final updated = TruckerModel(
                id: t.id,
                userId: t.userId,
                email: t.email,
                phone: t.phone,
                type: t.type,
                verificationStatus: t.verificationStatus,
                documents: t.documents,
                trucks: t.trucks
                    .map((tr) => tr.id == updatedTruck.id ? updatedTruck : tr)
                    .toList(),
                drivers: t.drivers,
              );
              await TruckerRepository.update(updated);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (res == true) await _load();
  }

  Future<void> _removeTruck(String truckId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Remove this truck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final t = _trucker!;
    final updated = TruckerModel(
      id: t.id,
      userId: t.userId,
      email: t.email,
      phone: t.phone,
      type: t.type,
      verificationStatus: t.verificationStatus,
      documents: t.documents,
      trucks: t.trucks.where((tr) => tr.id != truckId).toList(),
      drivers: t.drivers
          .map(
            (d) => d.assignedTruckId == truckId
                ? DriverModel(
                    id: d.id,
                    fullName: d.fullName,
                    nationalId: d.nationalId,
                    phone: d.phone,
                    drivingLicense: d.drivingLicense,
                    psvBadge: d.psvBadge,
                    assignedTruckId: null,
                  )
                : d,
          )
          .toList(),
    );
    await TruckerRepository.update(updated);
    await _load();
  }

  Future<void> _addDriver() async {
    final formKey = GlobalKey<FormState>();
    final full = TextEditingController();
    final nid = TextEditingController();
    final phone = TextEditingController();
    final license = TextEditingController();
    String? assignedTruckId = _trucker?.trucks.isNotEmpty == true
        ? _trucker!.trucks.first.id
        : null;

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Driver'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: full,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: nid,
                  decoration: const InputDecoration(labelText: 'National ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: license,
                  decoration: const InputDecoration(
                    labelText: 'Driving License',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                if (_trucker != null && _trucker!.trucks.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: assignedTruckId,
                    items: _trucker!.trucks
                        .map(
                          (tr) => DropdownMenuItem(
                            value: tr.id,
                            child: Text(tr.registrationNumber),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => assignedTruckId = v,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Truck',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('save_driver'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final drv = DriverModel(
                id: const Uuid().v4(),
                fullName: full.text.trim(),
                nationalId: nid.text.trim(),
                phone: phone.text.trim(),
                drivingLicense: license.text.trim(),
                assignedTruckId: assignedTruckId,
              );
              final t = _trucker!;
              final updated = TruckerModel(
                id: t.id,
                userId: t.userId,
                email: t.email,
                phone: t.phone,
                type: t.type,
                verificationStatus: t.verificationStatus,
                documents: t.documents,
                trucks: t.trucks,
                drivers: [...t.drivers, drv],
              );
              await TruckerRepository.update(updated);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  key: const ValueKey('add_truck'),
                  onPressed: _addTruck,
                  child: const Text('Add Truck'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const ValueKey('add_driver'),
                  onPressed: _addDriver,
                  child: const Text('Add Driver'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    'Trucks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_trucker!.trucks.isEmpty)
                    const Text('No trucks yet')
                  else
                    ..._trucker!.trucks.map(
                      (tr) => ListTile(
                        key: ValueKey('truck_${tr.id}'),
                        title: Text(tr.registrationNumber),
                        subtitle: Text('${tr.truckType} • ${tr.payloadTons}t'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: ValueKey('edit_truck_${tr.id}'),
                              onPressed: () => _editTruck(tr),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              key: ValueKey('delete_truck_${tr.id}'),
                              onPressed: () => _removeTruck(tr.id),
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Drivers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_trucker!.drivers.isEmpty)
                    const Text('No drivers yet')
                  else
                    ..._trucker!.drivers.map(
                      (d) => ListTile(
                        key: ValueKey('driver_${d.id}'),
                        title: Text(d.fullName),
                        subtitle: Text(
                          '${d.nationalId} • ${d.phone} • Assigned: ${d.assignedTruckId ?? 'None'}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../Models/trucker_model.dart';
import '../Models/enums.dart';
import '../Models/document_model.dart';
import '../services/trucker_repository.dart';
import '../services/mock_storage_repository.dart';
import '../services/upload_service.dart';

class IndividualOnboardingScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String phone;

  const IndividualOnboardingScreen({super.key, required this.userId, required this.email, required this.phone});

  @override
  State<IndividualOnboardingScreen> createState() => _IndividualOnboardingScreenState();
}

class _IndividualOnboardingScreenState extends State<IndividualOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _nationalId = TextEditingController();
  final _dob = TextEditingController();
  final _kra = TextEditingController();
  final _years = TextEditingController();

  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final t = TruckerModel(
      id: const Uuid().v4(),
      userId: widget.userId,
      email: widget.email,
      phone: widget.phone,
      type: TruckerType.individual,
      verificationStatus: VerificationStatus.incomplete,
      documents: [
        DocumentModel(id: 'nid_front', name: 'National ID (Front)', type: 'image'),
        DocumentModel(id: 'nid_back', name: 'National ID (Back)', type: 'image'),
        DocumentModel(id: 'license', name: 'Driving License', type: 'image'),
        DocumentModel(id: 'psv', name: 'PSV / Commercial License', type: 'image'),
        DocumentModel(id: 'kra', name: 'KRA PIN Certificate', type: 'pdf'),
        DocumentModel(id: 'cog', name: 'Certificate of Good Conduct', type: 'pdf'),
      ],
      trucks: [],
      drivers: [],
    );

    await TruckerRepository.saveTrucker(t);

    if (!mounted) return;
    setState(() => _saving = false);

    // Navigate to document upload / truck management
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DocumentUploadScreen(truckerId: t.id, requiredDocs: t.documents)),
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    _nationalId.dispose();
    _dob.dispose();
    _kra.dispose();
    _years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Individual Trucker Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Full Legal Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalId,
                decoration: const InputDecoration(labelText: 'National ID Number'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dob,
                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kra,
                decoration: const InputDecoration(labelText: 'KRA PIN'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _years,
                decoration: const InputDecoration(labelText: 'Years of Driving Experience'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DocumentUploadScreen is referenced above; provide a simplified implementation below.

class DocumentUploadScreen extends StatefulWidget {
  final String truckerId;
  final List<DocumentModel> requiredDocs;

  const DocumentUploadScreen({super.key, required this.truckerId, required this.requiredDocs});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _storage = MockStorageRepository();
  late final UploadService _uploader;
  final Map<String, double> _progress = {};
  final Map<String, String?> _uploadedUrls = {};

  @override
  void initState() {
    super.initState();
    _uploader = UploadService(storage: _storage);
  }

  Future<void> _pickAndUpload(DocumentModel doc) async {
    // In mock mode, simulate selecting a file and uploading it. Replace with real FilePicker + Firebase uploads when enabling Firebase.
    final path = 'mock/${doc.id}';
    final ext = 'jpg';
    final destination = 'truckers/${widget.truckerId}/documents/${doc.id}.$ext';

    final stream = _uploader.uploadFile(path, destination);
    _progress[doc.id] = 0.0;
    setState(() {});

    await for (final p in stream) {
      _progress[doc.id] = p;
      setState(() {});
    }

    final url = await _storage.getDownloadUrl(destination);
    if (url != null) {
      _uploadedUrls[doc.id] = url;
      // Update Trucker document in repository (SharedPreferences-backed)
      final t = await TruckerRepository.getById(widget.truckerId);
      if (t != null) {
        final updatedDocs = t.documents.map((d) {
          if (d.id == doc.id) {
            return DocumentModel(id: d.id, name: d.name, type: d.type, url: url, status: VerificationStatus.submitted);
          }
          return d;
        }).toList();
        final updated = TruckerModel(
          id: t.id,
          userId: t.userId,
          email: t.email,
          phone: t.phone,
          type: t.type,
          verificationStatus: t.verificationStatus,
          documents: updatedDocs,
          trucks: t.trucks,
          drivers: t.drivers,
        );
        await TruckerRepository.update(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Trucker ID: ${widget.truckerId}'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.requiredDocs.length,
                itemBuilder: (_, i) {
                  final d = widget.requiredDocs[i];
                  final p = _progress[d.id] ?? 0.0;
                  final url = _uploadedUrls[d.id];
                  return ListTile(
                    title: Text(d.name),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.type), if (url != null) Text('Uploaded: $url')]),
                    trailing: p > 0 && p < 1
                        ? SizedBox(width: 120, child: LinearProgressIndicator(value: p))
                        : ElevatedButton(
                            onPressed: () => _pickAndUpload(d),
                            child: const Text('Upload'),
                          ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Mark verification status as submitted
                final t = await TruckerRepository.getById(widget.truckerId);
                if (t != null) {
                  final updated = TruckerModel(
                    id: t.id,
                    userId: t.userId,
                    email: t.email,
                    phone: t.phone,
                    type: t.type,
                    verificationStatus: VerificationStatus.submitted,
                    documents: t.documents,
                    trucks: t.trucks,
                    drivers: t.drivers,
                  );
                  await TruckerRepository.update(updated);
                }

                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VerificationDashboardScreen()),
                );
              },
              child: const Text('Submit for Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationDashboardScreen extends StatelessWidget {
  const VerificationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Dashboard')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Text('Status: submitted'), SizedBox(height: 8), Text('Missing: Driving License (Back)')])),
    );
  }
}

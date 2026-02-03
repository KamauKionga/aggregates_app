import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../reports_providers.dart';

class AdminEodReportsScreen extends ConsumerWidget {
  const AdminEodReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reportsRepositoryProvider);
    final srv = ref.read(receiptServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('EoD Reports')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              'Generate EoD Reports',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, i) {
                  final date = DateTime.now().toUtc().subtract(
                    Duration(days: i),
                  );
                  final label =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  return Card(
                    child: ListTile(
                      title: Text('EoD Report • $label'),
                      trailing: ElevatedButton(
                        child: const Text('Generate'),
                        onPressed: () async {
                          final r = await repo.generateEodReport(date);
                          final url = await srv.generateAndUploadEodReport(r);
                          if (url != null)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Report uploaded: $url')),
                            );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

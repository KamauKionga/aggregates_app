import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/report_models.dart';
import '../reports_providers.dart';

class ReceiptDownloadButton extends ConsumerWidget {
  final String orderId;
  const ReceiptDownloadButton({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsRepo = ref.read(reportsRepositoryProvider);
    final receiptSrv = ref.read(receiptServiceProvider);

    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Download Receipt (PDF)'),
      onPressed: () async {
        try {
          final r = await reportsRepo.createReceiptFromOrder(orderId);
          final url = await receiptSrv.generateAndUploadOrderReceipt(r);
          if (url != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Receipt uploaded: $url')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt generation failed')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      },
    );
  }
}

class AgentReceiptButton extends ConsumerWidget {
  final AgentReceipt receipt;
  const AgentReceiptButton({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptSrv = ref.read(receiptServiceProvider);
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Download Agent Receipt'),
      onPressed: () async {
        final url = await receiptSrv.generateAndUploadAgentReceipt(receipt);
        if (url != null)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Receipt uploaded: $url')));
      },
    );
  }
}

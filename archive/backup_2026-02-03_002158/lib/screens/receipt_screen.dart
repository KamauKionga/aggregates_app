import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../Models/order.dart';
import 'order_detail_screen.dart';
import 'chat_screen.dart';
import 'buyer_order_screen.dart';

class ReceiptScreen extends StatelessWidget {
  final Order order;
  const ReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Add chat icon to app bar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _buildPdf(format),
              canChangePageFormat: false,
              maxPageWidth: 700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('download_pdf'),
                    onPressed: () async {
                      final bytes = await _buildPdf(PdfPageFormat.a4);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'receipt_${order.id}.pdf',
                      );
                    },
                    child: const Text('Download / Print'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const ValueKey('view_order_status'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  child: const Text('View Order Status'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const ValueKey('new_order'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BuyerOrderScreen(),
                      ),
                    );
                  },
                  child: const Text('Place another order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final invoice = order.invoice;

    final created = DateFormat.yMMMd().add_jm().format(order.createdAt);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('Aggregates Receipt')),
            pw.SizedBox(height: 8),
            pw.Text('Order ID: ${order.id}'),
            pw.Text('Created: $created'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Text(
              'Order Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Bullet(text: 'Type: ${invoice['type'] ?? ''}'),
            pw.Bullet(text: 'Tonnage: ${invoice['tons'] ?? ''} tons'),
            pw.Bullet(
              text: 'Price per ton: Kshs. ${invoice['pricePerTon'] ?? ''}',
            ),
            pw.Bullet(
              text: 'Aggregates cost: Kshs. ${invoice['aggregatesCost'] ?? ''}',
            ),
            pw.Bullet(
              text: 'Transport cost: Kshs. ${invoice['transportCost'] ?? ''}',
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Text(
              'Delivery',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Distance: ${invoice['distanceKm']?.toStringAsFixed(2) ?? 'N/A'} km',
            ),
            pw.Text('Details: ${invoice['deliveryDetails'] ?? ''}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Text('Status: ${order.status}'),
            pw.SizedBox(height: 8),
            if (order.timeline.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'History:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  for (final e in order.timeline.entries)
                    pw.Text(
                      '${e.key}: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(e.value))}',
                    ),
                  pw.SizedBox(height: 8),
                ],
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Estimated delivery: ${order.estimatedDelivery != null ? DateFormat.yMMMd().add_jm().format(order.estimatedDelivery!) : 'N/A'}',
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Thank you for your order!',
              style: pw.TextStyle(fontSize: 12),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

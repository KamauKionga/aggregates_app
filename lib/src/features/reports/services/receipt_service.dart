import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:aggregates_app/services/storage_repository.dart';
import '../domain/report_models.dart';

class ReportsPaths {
  static String buyerReceipt(String buyerId, String orderId) =>
      'receipts/buyers/$buyerId/orders/$orderId.pdf';
  static String agentReceipt(String agentId, String receiptId) =>
      'receipts/agents/$agentId/$receiptId.pdf';
  static String eodReport(DateTime date) =>
      'reports/eod/${DateFormat('yyyy-MM-dd').format(date)}/report.pdf';
  static String purchaseHistory(String buyerId, DateTime date) =>
      'reports/purchase_history/$buyerId/${DateFormat('yyyy-MM-dd').format(date)}.pdf';
}

class ReceiptService {
  final StorageRepository storage;
  ReceiptService({required this.storage});

  Future<Uint8List> _buildOrderPdf(Receipt r) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Order ID: ${r.orderId}'),
                pw.Text('Buyer: ${r.buyerId}'),
                pw.Text('Date: ${DateFormat.yMMMd().format(r.createdAt)}'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Column(
                  children: (r.invoice.entries)
                      .map(
                        (e) => pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(e.key),
                            pw.Text(e.value.toString()),
                          ],
                        ),
                      )
                      .toList(),
                ),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: Ksh ${r.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildAgentPdf(AgentReceipt ar) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              children: [
                pw.Text(
                  'Agent Commission Receipt',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Agent: ${ar.agentId}'),
                pw.Text('Amount: Ksh ${ar.amount}'),
                pw.Text('Reference: ${ar.reference}'),
                pw.Text('Date: ${DateFormat.yMMMd().format(ar.createdAt)}'),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<String?> generateAndUploadOrderReceipt(Receipt receipt) async {
    final bytes = await _buildOrderPdf(receipt);
    final destination = ReportsPaths.buyerReceipt(
      receipt.buyerId,
      receipt.orderId,
    );
    return _writeAndUpload(bytes, destination);
  }

  Future<String?> generateAndUploadAgentReceipt(AgentReceipt ar) async {
    final bytes = await _buildAgentPdf(ar);
    final destination = ReportsPaths.agentReceipt(ar.agentId, ar.id);
    return _writeAndUpload(bytes, destination);
  }

  Future<String?> generateAndUploadEodReport(EodReport report) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (c) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EoD Report ${DateFormat('yyyy-MM-dd').format(report.date)}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Total orders: ${report.totalOrders}'),
                pw.Text(
                  'Total value: Ksh ${report.totalValue.toStringAsFixed(2)}',
                ),
                pw.Text('Total commissions: Ksh ${report.totalCommissions}'),
                pw.Text('Total payouts: Ksh ${report.totalPayouts}'),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final destination = ReportsPaths.eodReport(report.date);
    return _writeAndUpload(bytes, destination);
  }

  Future<String?> _writeAndUpload(Uint8List bytes, String destination) async {
    // write to temp file
    final file = File(
      '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    // upload and wait for completion (MockStorage expects file path)
    await for (final _ in storage.upload(file.path, destination)) {
      // consumed progress
    }
    return await storage.getDownloadUrl(destination);
  }
}

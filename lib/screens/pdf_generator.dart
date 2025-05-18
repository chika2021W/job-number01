// lib/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// A simple data class for one row in the services table:
class PdfService {
  final String description;
  final int    quantity;
  final double amount;
  PdfService({
    required this.description,
    required this.quantity,
    required this.amount,
  });
}

/// Builds your quote PDF, with company header, bill‑to, Qty column,
/// left‑aligned amounts, and a footer.
class PdfGenerator {
  static Future<Uint8List> buildQuote({
    required PdfPageFormat format,
    required String companyName,
    required String companyPhone,
    required String companyEmail,
    required String companyWebsite,
    required String gstNumber,
    required String clientName,
    required String clientAddress,
    required String clientContact,
    required String clientEmail,
    required List<PdfService> services,
    required double gstRate,
    required int validDays,
    required String paymentTerms,
  }) async {
    final doc  = pw.Document();
    final date = DateFormat('d MMM yyyy').format(DateTime.now());

    doc.addPage(pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) {
        // compute totals
        final subTotal = services.fold<double>(
            0, (sum, s) => sum + s.amount * s.quantity);
        final gstAmt = subTotal * gstRate;
        final total  = subTotal + gstAmt;

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ─ HEADER ─
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(date),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.Text(companyPhone),
                    pw.Text(companyEmail),
                    pw.Text(companyWebsite),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('GST Number'),
                    pw.Text(gstNumber),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // ─ BILL TO ─
            pw.Text('Bill To:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Text(clientName),
            pw.Text(clientAddress),
            pw.Text(clientContact),
            pw.Text(clientEmail),

            pw.SizedBox(height: 20),

            // ─ QUOTE TABLE ─
            pw.Text('Quote',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Service', 'Qty', 'Amount'],
              data: services.map((s) => [
                    s.description,
                    s.quantity.toString(),
                    s.amount.toStringAsFixed(2),
                  ]).toList(),

              // left‑align the amount column only
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
              },

              // give a bit more room to the description column
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },

              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 10),

            // ─ TOTALS ─
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('GST (${(gstRate * 100).toInt()}%): '),
                pw.Text('\$${gstAmt.toStringAsFixed(2)}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),

            pw.SizedBox(height: 20),

            // ─ TERMS & CONDITIONS ─
            pw.Text('Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Text('Quote valid for $validDays days'),
            pw.Text('Payment: $paymentTerms'),

            pw.Spacer(),

            // ─ FOOTER ─
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        );
      },
    ));

    return doc.save();
  }
}
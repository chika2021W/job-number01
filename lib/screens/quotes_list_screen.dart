// lib/screens/quotes_list_screen.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'pdf_preview_screen.dart';

/// A minimal model for one service line
class ServiceLine {
  final String description;
  final int    quantity;
  final double amount;
  ServiceLine({
    required this.description,
    required this.quantity,
    required this.amount,
  });
}

class QuotesListScreen extends StatelessWidget {
  const QuotesListScreen({Key? key}) : super(key: key);

  /// Builds a PDF from a Firestore quote document
  Future<Uint8List> _buildPdfFromData(
    PdfPageFormat format,
    Map<String, dynamic> data,
  ) async {
    final doc    = pw.Document();
    final date   = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('d MMM yyyy').format(date);

    // company info (hard‑coded or pull from constants)
    const companyName    = 'COMPANY NAME';
    const companyPhone   = '+00 133‑456‑789';
    const companyEmail   = 'info@company.com';
    const companyWebsite = 'www.company.com';
    const gstNumber      = '12‑345‑678';

    // client data
    final client = data['client'] as Map<String, dynamic>? ?? {};

    // service lines
    final servicesRaw = data['services'] as List<dynamic>? ?? [];
    final services = servicesRaw.map((s) {
      return ServiceLine(
        description: s['description'] as String? ?? '',
        quantity:   s['quantity']    as int?    ?? 1,
        amount:     (s['amount']     as num?)   ?.toDouble() ?? 0,
      );
    }).toList();

    // compute totals
    final subTotal = services.fold<double>(0, (sum, s) => sum + s.amount * s.quantity);
    final gstAmount = subTotal * 0.15;
    final total     = subTotal + gstAmount;

    // terms
    final validDays = data['validDays']   as int?    ?? 0;
    final payment   = data['paymentTerms'] as String? ?? '';

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ─── HEADER ─────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(dateStr),
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

            // ─── BILL TO ────────────────────────────
            pw.Text('Bill To:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (client['name']    != null) pw.Text(client['name']    as String),
            if (client['address'] != null) pw.Text(client['address'] as String),
            if (client['contact'] != null) pw.Text(client['contact'] as String),
            if (client['email']   != null) pw.Text(client['email']   as String),

            pw.SizedBox(height: 20),

            // ─── QUOTE TABLE ────────────────────────
            pw.Text('Quote',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Service', 'Qty', 'Amount'],
              data: services.map((s) => [
                s.description,
                s.quantity.toString(),
                s.amount.toStringAsFixed(2),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
              },
              columnWidths: {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(2),
              },
            ),

            pw.SizedBox(height: 10),

            // ─── GST & TOTAL ─────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('GST (15%): '),
                pw.Text('\$${gstAmount.toStringAsFixed(2)}'),
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

            // ─── TERMS & CONDITIONS ──────────────────
            pw.Text('Terms & Conditions',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Quote valid for $validDays days'),
            pw.Text('Payment: $payment'),

            pw.Spacer(),     // push footer to bottom
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotes & Invoices')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quotes')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError)    return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData)    return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)     return const Center(child: Text('No quotes yet'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data  = docs[i].data()! as Map<String, dynamic>;
              final ts    = data['date'] as Timestamp?;
              final date  = ts?.toDate() ?? DateTime.now();
              final total = (data['total'] as num?)?.toDouble() ?? 0.0;

              return ListTile(
                title: Text('Quote on ${DateFormat('d MMM yyyy').format(date)}'),
                trailing: Text('\$${total.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewScreen(
                        buildPdf: (fmt) => _buildPdfFromData(fmt, data),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
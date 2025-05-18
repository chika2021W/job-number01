// lib/screens/quote_generator_screen.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'quotes_list_screen.dart';
import 'pdf_preview_screen.dart';

/// Model for one line item
class Service {
  String description;
  int quantity;
  double amount;
  Service({
    required this.description,
    required this.quantity,
    required this.amount,
  });
}

class QuoteGeneratorScreen extends StatefulWidget {
  const QuoteGeneratorScreen({Key? key}) : super(key: key);

  @override
  _QuoteGeneratorScreenState createState() => _QuoteGeneratorScreenState();
}

class _QuoteGeneratorScreenState extends State<QuoteGeneratorScreen> {
  // ─── COMPANY INFO ─────────────────────────────────────────
  final _companyName    = 'COMPANY NAME';
  final _companyPhone   = '+00 133‑456‑789';
  final _companyEmail   = 'info@company.com';
  final _companyWebsite = 'www.company.com';
  final _gstNumber      = '12‑345‑678';

  // ─── BILL TO CONTROLLERS ───────────────────────────────────
  final _clientNameCtrl    = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientContactCtrl = TextEditingController();
  final _clientEmailCtrl   = TextEditingController();

  // ─── SERVICE LINES CONTROLLERS ────────────────────────────
  List<TextEditingController> _serviceCtrls  = [];
  List<TextEditingController> _quantityCtrls = [];
  List<TextEditingController> _priceCtrls    = [];

  // prevent double saving
  bool _hasSaved = false;

  // ─── TERMS & CONDITIONS ────────────────────────────────────
  final _validityOptions = [7, 14, 30, 60];
  int   _selectedValidity = 30;
  final _paymentOptions  = [
    '50% before start work',
    '50% before completion',
    '100% on completion',
  ];
  String _selectedPayment = '50% before start work';

  @override
  void initState() {
    super.initState();
    // initialize two empty rows
    _resetServiceRows();
  }

  void _resetServiceRows() {
    // Dispose old ones
    for (var c in _serviceCtrls) {
      c.dispose();
    }
    for (var c in _quantityCtrls) {
      c.dispose();
    }
    for (var c in _priceCtrls) {
      c.dispose();
    }

    // Rebuild exactly two entries
    _serviceCtrls  = [TextEditingController(), TextEditingController()];
    _quantityCtrls = [
      TextEditingController(text: '1'),
      TextEditingController(text: '1')
    ];
    _priceCtrls    = [TextEditingController(), TextEditingController()];
  }

  void _addServiceRow() {
    setState(() {
      _serviceCtrls .add(TextEditingController());
      _quantityCtrls.add(TextEditingController(text: '1'));
      _priceCtrls   .add(TextEditingController());
    });
  }

  // ─── LIVE TOTALS ──────────────────────────────────────────
  double get _subTotal {
    var sum = 0.0;
    for (var i = 0; i < _priceCtrls.length; i++) {
      final price = double.tryParse(_priceCtrls[i].text.replaceAll(',', '')) ?? 0;
      final qty   = int.tryParse(_quantityCtrls[i].text) ?? 1;
      sum += price * qty;
    }
    return sum;
  }
  double get _gstAmount => _subTotal * 0.15;
  double get _total     => _subTotal + _gstAmount;

  // Gather Service objects
  List<Service> get _servicesList {
    return List.generate(_serviceCtrls.length, (i) {
      return Service(
        description: _serviceCtrls[i].text,
        quantity:   int.tryParse(_quantityCtrls[i].text) ?? 1,
        amount:     double.tryParse(_priceCtrls[i].text.replaceAll(',', '')) ?? 0,
      );
    });
  }

  // ─── RESET EVERYTHING ─────────────────────────────────────
  void _resetForm() {
    setState(() {
      _hasSaved = false;

      // clear Bill‑To
      _clientNameCtrl.clear();
      _clientAddressCtrl.clear();
      _clientContactCtrl.clear();
      _clientEmailCtrl.clear();

      // reset service rows back to two blank
      _resetServiceRows();

      // reset T&C
      _selectedValidity = 30;
      _selectedPayment  = _paymentOptions.first;
    });
  }

  // ─── PDF BUILDER ───────────────────────────────────────────
  Future<Uint8List> _buildPdfDocument(
    PdfPageFormat format,
    List<Service> services,
    double gstRate,
    int validDays,
    String paymentTerms,
  ) async {
    final doc  = pw.Document();
    final date = DateFormat('d MMM yyyy').format(DateTime.now());

    doc.addPage(pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

          // HEADER
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(date),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text(_companyName,    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(_companyPhone),
              pw.Text(_companyEmail),
              pw.Text(_companyWebsite),
            ])),
            pw.SizedBox(width: 20),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('GST Number'),
              pw.Text(_gstNumber),
            ]),
          ]),

          pw.SizedBox(height: 24),

          // BILL TO
          pw.Text('Bill To:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(_clientNameCtrl.text),
          pw.Text(_clientAddressCtrl.text),
          pw.Text(_clientContactCtrl.text),
          pw.Text(_clientEmailCtrl.text),

          pw.SizedBox(height: 20),

          // QUOTE TABLE
          pw.Text('Quote', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Table.fromTextArray(
            headers: ['Service','Qty','Amount'],
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

          // GST & TOTAL
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('GST (${(gstRate*100).toInt()}%): '),
            pw.Text('\$${_gstAmount.toStringAsFixed(2)}'),
          ]),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('Total: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('\$${_total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ]),

          pw.SizedBox(height: 20),

          // TERMS & CONDITIONS
          pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Quote valid for $validDays days'),
          pw.Text('Payment: $paymentTerms'),

          pw.Spacer(), // push footer
          pw.Divider(),
          pw.Center(child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
        ],
      ),
    ));

    return doc.save();
  }

  @override
  void dispose() {
    // dispose all controllers
    _clientNameCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientContactCtrl.dispose();
    _clientEmailCtrl.dispose();
    for (var c in _serviceCtrls ) {
      c.dispose();
    }
    for (var c in _quantityCtrls) {
      c.dispose();
    }
    for (var c in _priceCtrls   ) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today   = DateFormat('dd MMM yyyy').format(DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Quote')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // DATE
          Text(today, style: TextStyle(color: primary.withOpacity(0.7))),
          const SizedBox(height: 16),

          // BILL TO FORM
          const Text('Bill To:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _clientNameCtrl,    decoration: const InputDecoration(labelText: 'Client Name',    border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _clientAddressCtrl, decoration: const InputDecoration(labelText: 'Address',        border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _clientContactCtrl, decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _clientEmailCtrl,   decoration: const InputDecoration(labelText: 'Email',          border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),

          const SizedBox(height: 24),

          // SERVICE LINES
          const Text('Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (var i = 0; i < _serviceCtrls.length; i++) ...[
            Row(children: [
              Expanded(flex: 4, child: TextField(controller: _serviceCtrls[i],
                decoration: const InputDecoration(labelText: 'Service Description', border: OutlineInputBorder()),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: TextField(controller: _quantityCtrls[i],
                decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState((){}),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: _priceCtrls[i],
                decoration: const InputDecoration(labelText: 'Unit \$', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState((){}),
              )),
            ]),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: _addServiceRow,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Service'),
          ),

          const SizedBox(height: 24),

          // TOTALS
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('GST (15%)'),
            Text('\$${_gstAmount.toStringAsFixed(2)}'),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),

          const Divider(height: 32),

          // TERMS & CONDITIONS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Terms & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(flex: 2, child: Text('Quote valid for')),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  value: _selectedValidity,
                  items: _validityOptions.map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                  onChanged: (v) => setState(() => _selectedValidity = v!),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(flex: 2, child: Text('Payment')),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  value: _selectedPayment,
                  items: _paymentOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedPayment = v!),
                )),
              ]),
            ]),
          ),

          const SizedBox(height: 24),

          // PREVIEW BUTTON
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(
                buildPdf: (fmt) => _buildPdfDocument(fmt, _servicesList, 0.15, _selectedValidity, _selectedPayment),
              ),
            )),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Generate Quote'),
          ),

          const SizedBox(height: 12),

          // ─── SAVE & RESET ────────────────────────────────────────────
          Row(children: [
            // Save
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _hasSaved
                  ? null
                  : () async {
                      // save to Firestore
                      await FirebaseFirestore.instance.collection('quotes').add({
                        'date': DateTime.now(),
                        'client': {
                          'name':    _clientNameCtrl.text,
                          'address': _clientAddressCtrl.text,
                          'contact': _clientContactCtrl.text,
                          'email':   _clientEmailCtrl.text,
                        },
                        'services': _servicesList.map((s) => {
                          'description': s.description,
                          'quantity':    s.quantity,
                          'amount':      s.amount,
                        }).toList(),
                        'subTotal':    _subTotal,
                        'gstAmount':   _gstAmount,
                        'total':       _total,
                        'validDays':   _selectedValidity,
                        'paymentTerms':_selectedPayment,
                        'createdBy':   FirebaseAuth.instance.currentUser?.uid,
                      });
                      setState(() => _hasSaved = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quote saved successfully!')),
                      );
                    },
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save Quote'),
              ),
            ),

            const SizedBox(width: 12),

            // Reset
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Reset'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
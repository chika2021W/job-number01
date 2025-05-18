// lib/screens/pdf_preview_screen.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// A full‑screen PDF preview that shows *only* Print & Share.
class PdfPreviewScreen extends StatelessWidget {
  /// Given a page format, returns the PDF bytes.
  final FutureOr<Uint8List> Function(PdfPageFormat) buildPdf;

  const PdfPreviewScreen({
    Key? key,
    required this.buildPdf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Quote'),
        leading: const BackButton(),
      ),
      body: PdfPreview(
        build: buildPdf,
        maxPageWidth: 700,

        // hide orientation & page‐format toggles
        canChangeOrientation: false,
        canChangePageFormat: false,

        // only show Print & Share
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.print_outlined),
            onPressed: (
              BuildContext context,
              FutureOr<Uint8List> Function(PdfPageFormat) build,
              PdfPageFormat format,
            ) {
              Printing.layoutPdf(onLayout: build);
            },
          ),
          PdfPreviewAction(
            icon: const Icon(Icons.share_outlined),
            onPressed: (
              BuildContext context,
              FutureOr<Uint8List> Function(PdfPageFormat) build,
              PdfPageFormat format,
            ) async {
              final data = await build(format);
              await Printing.sharePdf(bytes: data, filename: 'quote.pdf');
            },
          ),
        ],
      ),
    );
  }
}
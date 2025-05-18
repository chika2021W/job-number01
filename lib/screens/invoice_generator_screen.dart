import 'package:flutter/material.dart';

class InvoiceGeneratorScreen extends StatelessWidget {
  const InvoiceGeneratorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: const Center(child: Text('Your invoice generator UI here')),
    );
  }
}
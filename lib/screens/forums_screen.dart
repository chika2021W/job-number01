import 'package:flutter/material.dart';

class ForumsScreen extends StatelessWidget {
  const ForumsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forums')),
      body: const Center(child: Text('Your forums UI here')),
    );
  }
}
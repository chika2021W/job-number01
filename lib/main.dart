import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quote_generator_screen.dart';
import 'screens/invoice_generator_screen.dart';
import 'screens/quotes_list_screen.dart';
import 'screens/user_account_screen.dart';
import 'screens/forums_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on mobile and web
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'JobNumber',
      theme: theme,
      debugShowCheckedModeBanner: false,

      // Start at the login screen
      initialRoute: '/',

      // Named routes
      routes: {
        '/':            (_) => const LoginScreen(),
        '/register':    (_) => const RegisterScreen(),
        '/home':        (_) => const HomeScreen(),
        '/quote':       (_) => const QuoteGeneratorScreen(),
        '/invoice':     (_) => const InvoiceGeneratorScreen(),
        '/list':        (_) => const QuotesListScreen(),
        '/account':     (_) => const UserAccountScreen(),
        '/forums':      (_) => const ForumsScreen(),
      },
    );
  }
}
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// <- CORRECTED import:
import 'login_screen.dart';  // since login_screen.dart lives in the same screens/ folder

import 'quote_generator_screen.dart';
import 'invoice_generator_screen.dart';
import 'quotes_list_screen.dart';
import 'user_account_screen.dart';
import 'forums_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Replace the whole stack with LoginScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primary = const Color(0xFF0D1F44);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: primary),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontSize: 16, color: primary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0D1F44);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.logout, color: primary),
          tooltip: 'Log out',
          onPressed: () => _logout(context),
        ),
        title: Text(
          'Home',
          style: TextStyle(color: primary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Text(
                'Welcome, $userEmail!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: primary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    switch (i) {
                      case 0:
                        return _buildMenuItem(
                          context: context,
                          icon: Icons.post_add_outlined,
                          label: 'Create Quote',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QuoteGeneratorScreen()),
                          ),
                        );
                      case 1:
                        return _buildMenuItem(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Create Invoice',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InvoiceGeneratorScreen()),
                          ),
                        );
                      case 2:
                        return _buildMenuItem(
                          context: context,
                          icon: Icons.folder_open_outlined,
                          label: 'View Quotes / Invoices',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QuotesListScreen()),
                          ),
                        );
                      case 3:
                        return _buildMenuItem(
                          context: context,
                          icon: Icons.person_outline,
                          label: 'User Account',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserAccountScreen()),
                          ),
                        );
                      default:
                        return _buildMenuItem(
                          context: context,
                          icon: Icons.forum_outlined,
                          label: 'Forums',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForumsScreen()),
                          ),
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqItem('How do I generate an itinerary?'),
          _buildFaqItem('How can I save a place?'),
          _buildFaqItem('Are the AI responses accurate?'),
          const SizedBox(height: 32),
          const Text('Contact Us', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.surfaceElevated,
            child: ListTile(
              leading: const Icon(Icons.email, color: AppTheme.emerald),
              title: const Text('Email Support', style: TextStyle(color: Colors.white)),
              subtitle: const Text('support@ceylontrekker.com', style: TextStyle(color: Colors.white54)),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(color: Colors.white)),
      iconColor: AppTheme.emerald,
      collapsedIconColor: Colors.white54,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('This is a mock answer to the frequently asked question.', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

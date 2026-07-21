import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile('Push Notifications', true),
          _buildSwitchTile('Email Alerts', false),
          const Divider(color: Colors.white10),
          _buildListTile('Language', 'English'),
          _buildListTile('Currency', 'LKR'),
          const Divider(color: Colors.white10),
          _buildListTile('Privacy Policy', ''),
          _buildListTile('Terms of Service', ''),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (val) {},
      activeColor: AppTheme.emerald,
    );
  }

  Widget _buildListTile(String title, String trailingText) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
      onTap: () {},
    );
  }
}

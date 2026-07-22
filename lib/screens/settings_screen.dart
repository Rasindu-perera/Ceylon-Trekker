import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../app/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool isUploadingPic = false;
  final String imgbbApiKey = dotenv.env['IMGBB_API_KEY'] ?? '';

  Future<void> _updateProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          isUploadingPic = true;
        });

        final bytes = File(pickedFile.path).readAsBytesSync();
        final base64ImageString = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': imgbbApiKey,
            'image': base64ImageString,
          },
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 200 && responseData['success'] == true) {
          final imageUrl = responseData['data']['url'];
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
          }
        } else {
          throw Exception(responseData['error']?['message'] ?? 'Failed to upload image.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPic = false;
        });
      }
    }
  }

  Future<void> _changeEmail() async {
    final controller = TextEditingController();
    final newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Change Email', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New Email',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirm', style: TextStyle(color: AppTheme.emerald)),
          ),
        ],
      ),
    );

    if (newEmail != null && newEmail.isNotEmpty && mounted) {
      try {
        await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent to new address.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New Password',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm', style: TextStyle(color: AppTheme.emerald)),
          ),
        ],
      ),
    );

    if (newPassword != null && newPassword.isNotEmpty && mounted) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

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
          _buildSectionHeader('Account Settings'),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.white54),
            title: const Text('Change Email', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: _changeEmail,
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.white54),
            title: const Text('Change Password', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.white54),
            title: const Text('Update Profile Picture', style: TextStyle(color: Colors.white)),
            trailing: isUploadingPic
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.emerald, strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: isUploadingPic ? null : _updateProfilePicture,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('App Settings'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Colors.white54),
            title: const Text('Push Notifications', style: TextStyle(color: Colors.white)),
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() {
                notificationsEnabled = val;
              });
            },
            activeColor: AppTheme.emerald,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Information'),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.white54),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.white54),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Your privacy is important to us. This Privacy Policy outlines how we collect, use, and protect your information when you use Ceylon Trekker.\n\n'
          'Information Collection:\n'
          'We collect information you provide directly to us, such as when you create or modify your account, or contact customer support.\n\n'
          'Information Use:\n'
          'We use the information we collect to provide, maintain, and improve our services.\n\n'
          'Security:\n'
          'We implement security measures designed to protect your information from unauthorized access.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Welcome to Ceylon Trekker! By accessing or using our application, you agree to be bound by these Terms of Service.\n\n'
          'Use of the Service:\n'
          'You agree to use the service only for lawful purposes and in accordance with these Terms.\n\n'
          'User Accounts:\n'
          'You are responsible for safeguarding the password that you use to access the service and for any activities or actions under your password.\n\n'
          'Changes to Terms:\n'
          'We reserve the right, at our sole discretion, to modify or replace these Terms at any time.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}

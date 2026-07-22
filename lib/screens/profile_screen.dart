import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import 'settings_screen.dart';
import 'trip_history_screen.dart';
import 'saved_places_screen.dart';
import 'help_support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      initialData: FirebaseAuth.instance.currentUser,
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName ?? 'No Name Provided';
        final email = user?.email ?? 'No Email Provided';
        final photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surfaceElevated,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null 
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 32),
                _buildProfileOption(Icons.settings, 'Settings', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _buildProfileOption(Icons.history, 'Trip History', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
                }),
                _buildProfileOption(Icons.favorite, 'Saved Places', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()));
                }),
                _buildProfileOption(Icons.help_outline, 'Help & Support', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                }),
                const SizedBox(height: 24),
                _buildProfileOption(Icons.logout, 'Log Out', () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }, isDestructive: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.redAccent.withValues(alpha: 0.1) : AppTheme.emerald.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : AppTheme.emerald),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

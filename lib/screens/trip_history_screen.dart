import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Trip History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTripCard('Ella Explorer', 'Jun 10 - Jun 15, 2026', 'Completed'),
          _buildTripCard('Southern Beaches', 'Apr 2 - Apr 8, 2026', 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTripCard(String title, String dates, String status) {
    return Card(
      color: AppTheme.surfaceElevated,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.history, color: AppTheme.emerald),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(dates, style: const TextStyle(color: Colors.white54)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 12)),
        ),
      ),
    );
  }
}

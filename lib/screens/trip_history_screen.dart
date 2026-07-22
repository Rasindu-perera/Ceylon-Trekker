import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_theme.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  void _showPlanDetails(BuildContext context, Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Trip to ${trip['destination'] ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip['dates']} Days • ${trip['travelers']} • ${trip['travelStyle']}',
                  style: const TextStyle(color: AppTheme.emerald, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: trip['plan'] ?? 'No plan details available.',
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                        h2: const TextStyle(color: AppTheme.emerald, fontSize: 20, fontWeight: FontWeight.bold, height: 2.0),
                        h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.8),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        listBullet: const TextStyle(color: AppTheme.emerald, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Trip History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid == null
          ? const Center(
              child: Text('Please log in to view your trip history.', style: TextStyle(color: Colors.white70)),
            )
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
              ).ref('users/$uid/trip_history').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.emerald));
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading trips', style: TextStyle(color: Colors.redAccent)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, color: Colors.white54, size: 64),
                        SizedBox(height: 16),
                        Text('No trip history found.', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Generate a new trip using the AI Planner!', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }

                final map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final trips = <Map<String, dynamic>>[];
                map.forEach((key, value) {
                  final data = Map<String, dynamic>.from(value as Map);
                  data['id'] = key.toString();
                  trips.add(data);
                });

                // Sort by timestamp descending (newest first)
                trips.sort((a, b) {
                  final tA = a['timestamp'] ?? 0;
                  final tB = b['timestamp'] ?? 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(context, trip);
                  },
                );
              },
            ),
    );
  }

  Future<void> _startNavigation(BuildContext context, List<dynamic> places) async {
    final validPlaces = places.where((p) {
      final map = p as Map<dynamic, dynamic>?;
      return map != null && map['lat'] != null && map['lng'] != null;
    }).toList();

    if (validPlaces.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough valid places to navigate.')));
      return;
    }

    final first = validPlaces.first as Map<dynamic, dynamic>;
    final last = validPlaces.last as Map<dynamic, dynamic>;
    final origin = '${first['lat']},${first['lng']}';
    final destination = '${last['lat']},${last['lng']}';
    
    String waypointsStr = '';
    if (validPlaces.length > 2) {
      final waypoints = validPlaces.sublist(1, validPlaces.length - 1);
      waypointsStr = '&waypoints=' + waypoints.map((p) {
        final pm = p as Map<dynamic, dynamic>;
        return '${pm['lat']},${pm['lng']}';
      }).join('|');
    }

    final urlString = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination$waypointsStr&travelmode=driving';
    final uri = Uri.parse(urlString);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching navigation: $e')));
      }
    }
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final destination = trip['destination'] ?? 'Unknown Destination';
    final dates = trip['dates'] ?? '?';
    final travelers = trip['travelers'] ?? '?';
    
    return Card(
      color: AppTheme.surfaceElevated,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _showPlanDetails(context, trip),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.flight_takeoff, color: AppTheme.emerald),
              ),
              title: Text(
                'Trip to $destination', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '$dates Days • $travelers', 
                  style: const TextStyle(color: Colors.white54)
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('AI Plan', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: () {
                if (trip['places'] != null) {
                  _startNavigation(context, trip['places'] as List<dynamic>);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No route places found for this trip.')));
                }
              },
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text('Start Trip (Maps)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

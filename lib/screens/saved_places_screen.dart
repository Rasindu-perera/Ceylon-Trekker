import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../app/app_theme.dart';
import 'home_screen.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  Future<void> _removePlace(BuildContext context, String placeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
      ).ref('users/$uid/saved_places/$placeId');
      
      await ref.remove();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place removed from saved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Saved Places', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid == null
          ? const Center(
              child: Text('Please log in to view saved places.', style: TextStyle(color: Colors.white70)),
            )
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instanceFor(
                app: Firebase.app(),
                databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
              ).ref('users/$uid/saved_places').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.emerald));
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading saved places', style: TextStyle(color: Colors.redAccent)));
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, color: Colors.white54, size: 64),
                        SizedBox(height: 16),
                        Text('No saved places yet.', style: TextStyle(color: Colors.white70, fontSize: 18)),
                      ],
                    ),
                  );
                }

                final savedMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final List<Map<String, dynamic>> savedList = [];
                savedMap.forEach((key, value) {
                  final data = Map<String, dynamic>.from(value as Map);
                  data['id'] = key.toString();
                  savedList.add(data);
                });

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    final place = savedList[index];
                    return _buildSavedPlace(context, place);
                  },
                );
              },
            ),
    );
  }

  Widget _buildSavedPlace(BuildContext context, Map<String, dynamic> place) {
    final title = place['title'] ?? 'Unknown';
    final imagePath = place['image'] ?? '';
    final id = place['id'] as String;
    final heroTag = 'saved_place_$id';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(placeData: place, heroTag: heroTag),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imagePath.isNotEmpty 
                    ? Image.network(
                        imagePath, 
                        width: double.infinity, 
                        height: double.infinity, 
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.image, color: Colors.white54)),
                      ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                title, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removePlace(context, id),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

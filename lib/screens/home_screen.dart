import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../app/app_theme.dart';
import '../widgets/ai_chat_sheet.dart';
import 'profile_screen.dart';
import 'plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeFilter = 'All';
  final TextEditingController searchController = TextEditingController();
  
  String _currentLocation = "Locating...";

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.explore},
    {'label': 'Hiking', 'icon': Icons.hiking},
    {'label': 'Camping', 'icon': Icons.park},
    {'label': 'Waterfalls', 'icon': Icons.water_drop},
    {'label': 'Historical', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
    _fetchUserLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentLocation = "Location Disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentLocation = "Location Denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentLocation = "Location Denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        String countryCode = place.isoCountryCode ?? '';
        setState(() {
          _currentLocation = "$city, $countryCode".toUpperCase();
        });
      } else {
        setState(() => _currentLocation = "Unknown Location");
      }
    } catch (e) {
      setState(() => _currentLocation = "Location Error");
      debugPrint("Location error: $e");
    }
  }

  Future<void> _toggleSavePlace(String placeId, Map<String, dynamic> placeData, bool isCurrentlySaved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save places.')),
        );
      }
      return;
    }

    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/saved_places/$placeId');

    try {
      if (isCurrentlySaved) {
        await ref.remove();
      } else {
        await ref.set(placeData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update saved places: $e')),
        );
      }
    }
  }

  void _openAiGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: const AiChatSheet(),
        );
      },
    );
  }

  void _simulateVoiceSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 12),
            Text('Listening for destination...'),
          ],
        ),
        backgroundColor: AppTheme.emerald,
        duration: Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          activeFilter = 'All';
          searchController.text = 'Ella';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Search Bar
            _buildHeroSection(),
            
            const SizedBox(height: 0),
            
            // Recommended / Searched Places
            _buildSectionHeader(
              searchController.text.isNotEmpty || activeFilter != 'All' ? 'Search Results' : 'Recommended for You', 
              null, 
              icon: Icons.trending_up
            ),
            const SizedBox(height: 16),
            _buildRecommendations(),
            
            const SizedBox(height: 200),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FractionallySizedBox(
                heightFactor: 0.75,
                child: const AiChatSheet(),
              ),
            );
          },
          backgroundColor: AppTheme.emerald,
          icon: const Icon(Icons.smart_toy, color: Colors.white),
          label: const Text('AI Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        // Hero Image with Gradient Fade
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.6, 1.0],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/hero_sri_lanka.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        
        // Overlay Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Current Location)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: AppTheme.emerald),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT LOCATION', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('$_currentLocation ✈', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.emerald, width: 2),
                        ),
                        child: StreamBuilder<User?>(
                          initialData: FirebaseAuth.instance.currentUser,
                          stream: FirebaseAuth.instance.userChanges(),
                          builder: (context, snapshot) {
                            final photoUrl = snapshot.data?.photoURL;
                            return CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black45,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Hero Typography
                const Text(
                  'Where\nwill the\nisland\nlead you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Search Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.black87),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search destinations, experiences...',
                          hintStyle: const TextStyle(color: Colors.black45),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String? actionText, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (actionText != null)
            Text(
              '$actionText >',
              style: const TextStyle(
                color: AppTheme.emerald,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildRecommendations() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
      ).ref('places').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.emerald),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 250,
            child: Center(
              child: Text('Error loading places: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No places available in the database.');
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;

        // If no user is logged in, skip fetching saved places and pass an empty list
        if (uid == null) {
          return _renderFilteredPlaces(snapshot.data!.snapshot, []);
        }

        // Real-time listener for the user's saved places
        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
          ).ref('users/$uid/saved_places').onValue,
          builder: (context, savedSnapshot) {
            List<String> savedPlaceIds = [];
            if (savedSnapshot.hasData && savedSnapshot.data!.snapshot.value != null) {
              final savedMap = savedSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              savedPlaceIds = savedMap.keys.map((e) => e.toString()).toList();
            }
            
            return _renderFilteredPlaces(snapshot.data!.snapshot, savedPlaceIds);
          },
        );
      },
    );
  }

  Widget _renderFilteredPlaces(DataSnapshot placesSnapshot, List<String> savedPlaceIds) {
    // Firebase Realtime DB returns a Map of keys to values when listing items
    final Map<dynamic, dynamic> placesMap = placesSnapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> allFetchedPlaces = [];
    
    placesMap.forEach((key, value) {
      final placeData = Map<String, dynamic>.from(value as Map);
      placeData['id'] = key.toString(); // Keep track of the DB key for unique hero tags
      allFetchedPlaces.add(placeData);
    });

    final query = searchController.text.toLowerCase().trim();

    // Perform smart client-side filtering on the fetched data
    final filteredPlaces = allFetchedPlaces.where((data) {
      final category = data['category'] ?? '';
      final title = (data['title'] ?? '').toString().toLowerCase();
      final extract = (data['extract'] ?? '').toString().toLowerCase();
      
      final tagsList = data['tags'] as List<dynamic>? ?? [];
      final tags = tagsList.join(' ').toLowerCase();

      final matchesCategory = activeFilter == 'All' || category == activeFilter;
      final matchesSearch = query.isEmpty || 
                            title.contains(query) ||
                            extract.contains(query) ||
                            tags.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();

    if (filteredPlaces.isEmpty) {
      return _buildEmptyState('No destinations match your search.');
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filteredPlaces.length,
        itemBuilder: (context, index) {
          final doc = filteredPlaces[index];
          final isSaved = savedPlaceIds.contains(doc['id']);
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildRecCard(doc, isSaved),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white.withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  activeFilter = 'All';
                  searchController.clear();
                });
              },
              child: const Text('Clear Filters', style: TextStyle(color: AppTheme.emerald)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecCard(Map<String, dynamic> data, bool isSaved) {
    final title = data['title'] ?? 'Unknown Place';
    final description = data['extract'] ?? '';
    final imagePath = data['image'] ?? '';
    final String id = data['id'] ?? title.replaceAll(' ', '_');
    
    // Guaranteed unique hero tag using Firebase DB key
    final String heroTag = 'place_$id';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(placeData: data, heroTag: heroTag),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: imagePath.isNotEmpty 
                          ? Image.network(
                              imagePath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              headers: const {'User-Agent': 'CeylonTrekkerApp/1.0'},
                              errorBuilder: (ctx, error, stack) => Container(
                                color: Colors.grey.shade800,
                                child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 40)),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 40)),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleSavePlace(id, data, isSaved),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: isSaved ? Colors.redAccent : Colors.white,
                          size: 16
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final String heroTag;

  const PlaceDetailScreen({super.key, required this.placeData, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final title = placeData['title'] ?? 'Unknown Place';
    final description = placeData['extract'] ?? 'No description available.';
    final imagePath = placeData['image'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.background,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: imagePath.isNotEmpty
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'CeylonTrekkerApp/1.0'},
                        errorBuilder: (ctx, error, stack) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 64)),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
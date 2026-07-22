import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app/app_theme.dart';
import '../widgets/ai_chat_sheet.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'id': 'all', 'icon': Icons.explore},
    {'label': 'Hiking', 'id': 'hiking', 'icon': Icons.hiking},
    {'label': 'Camping', 'id': 'camping', 'icon': Icons.park},
    {'label': 'Waterfalls', 'id': 'waterfalls', 'icon': Icons.water_drop},
    {'label': 'Historical', 'id': 'historical', 'icon': Icons.account_balance},
  ];

  // Dynamic Wikipedia Data
  List<Map<String, dynamic>> recommendedPlaces = [];
  bool isLoadingPlaces = true;
  final List<String> placeTitles = ['Sigiriya', 'Ella,_Sri_Lanka', 'Yala_National_Park', 'Galle_Fort', 'Horton_Plains_National_Park'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    fetchPlacesData();
  }

  Future<void> fetchPlacesData() async {
    List<Map<String, dynamic>> fetchedPlaces = [];
    for (String title in placeTitles) {
      try {
        final response = await http.get(Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$title'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          fetchedPlaces.add({
            'title': data['title'],
            'extract': data['extract'],
            'image': data['thumbnail']?['source'] ?? '',
          });
        }
      } catch (e) {
        debugPrint('Failed to fetch $title: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        recommendedPlaces = fetchedPlaces;
        isLoadingPlaces = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _searchController.text = 'Ella';
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
            
            const SizedBox(height: 24),
            
            // Explore Categories
            _buildSectionHeader('Explore Categories', 'view all'),
            const SizedBox(height: 16),
            _buildCategoryChips(),
            
            const SizedBox(height: 32),
            
            // Recommended For You
            _buildSectionHeader('Recommended for You', null, icon: Icons.trending_up),
            const SizedBox(height: 16),
            _buildRecommendations(),
            
            const SizedBox(height: 32),
            
            // AI Planner Banner
            _buildAiPlannerBanner(),
            
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        // Hero Image with Gradient Fade
        ShaderMask(
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
            height: 450,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
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
                        const Text('COLOMBO, LK ✈', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                
                const SizedBox(height: 48),
                
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
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search destinations, experiences...',
                          hintStyle: const TextStyle(color: Colors.black45),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          suffixIcon: GestureDetector(
                            onTap: _simulateVoiceSearch,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic, color: AppTheme.emerald, size: 20),
                            ),
                          ),
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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat['id'] == _selectedCategoryId;
          return _buildChip(
            cat['label'], 
            cat['icon'], 
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategoryId = cat['id'];
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emerald : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.emerald : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (isLoadingPlaces) {
      return SizedBox(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.emerald),
                ),
              ),
            );
          },
        ),
      );
    }

    final filtered = recommendedPlaces.where((place) {
      final title = place['title'] as String;
      return title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text('No destinations found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildRecCard(
              title: item['title'] ?? '',
              description: item['extract'] ?? '',
              imagePath: item['image'] ?? '',
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecCard({required String title, required String description, required String imagePath}) {
    return Container(
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: imagePath.isNotEmpty 
                      ? Image.network(
                          imagePath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stack) => Container(color: Colors.grey.shade800),
                        )
                      : Container(color: Colors.grey.shade800),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 16),
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
    );
  }

  Widget _buildAiPlannerBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2C24), // Dark deep green matching mockup
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.5)),
            ),
            child: const Text('ai powered', style: TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready for a tailored\nisland escape?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate a custom 5-day itinerary based on your trekking speed and budget.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openAiGuideSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Start Planning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
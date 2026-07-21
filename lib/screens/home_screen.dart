import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../widgets/ai_chat_sheet.dart';
import 'profile_screen.dart';

class Recommendation {
  final String title;
  final String location;
  final String rating;
  final String imagePath;
  final String categoryId;

  Recommendation({
    required this.title,
    required this.location,
    required this.rating,
    required this.imagePath,
    required this.categoryId,
  });
}

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

  final List<Recommendation> _allRecommendations = [
    Recommendation(
      title: 'Ella Rock Peak Trail',
      location: 'Badulla district',
      rating: '4.9',
      imagePath: 'assets/images/ella_rock.png',
      categoryId: 'hiking',
    ),
    Recommendation(
      title: 'Ancient Ruins',
      location: 'North Central',
      rating: '4.8',
      imagePath: 'assets/images/ancient_ruins.png',
      categoryId: 'historical',
    ),
    Recommendation(
      title: 'Knuckles Mountain Range',
      location: 'Central Province',
      rating: '4.7',
      imagePath: 'assets/images/ella_rock.png', 
      categoryId: 'camping',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recommendation> get _filteredRecommendations {
    return _allRecommendations.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            item.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryId == 'all' || item.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
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
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black45,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
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
    final items = _filteredRecommendations;
    
    if (items.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Text('No destinations found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildRecCard(
              title: item.title,
              location: item.location,
              rating: item.rating,
              imagePath: item.imagePath,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecCard({required String title, required String location, required String rating, required String imagePath}) {
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
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_border, color: AppTheme.emerald, size: 14),
                        const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
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
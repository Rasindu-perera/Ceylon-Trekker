import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../app/app_theme.dart';
import '../widgets/ai_chat_sheet.dart';

class AroundScreen extends StatefulWidget {
  const AroundScreen({super.key});

  @override
  State<AroundScreen> createState() => _AroundScreenState();
}

class _AroundScreenState extends State<AroundScreen> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(6.8711, 81.0450); // Default to Ella
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  List<Marker> _markers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allFetchedElements = [];

  // Category Configuration
  final Map<String, String> _categories = {
    "Waterfalls": 'node["waterway"="waterfall"]',
    "Viewpoints": 'node["tourism"="viewpoint"]',
    "Camping": 'node["tourism"="camp_site"]',
    "Hotels/Stays": 'node["tourism"~"hotel|guest_house|hostel"]',
    "Restaurants": 'node["amenity"~"restaurant|cafe|fast_food"]',
    "Hospitals": 'node["amenity"~"hospital|clinic|doctors"]',
    "Fuel": 'node["amenity"="fuel"]',
    "ATMs": 'node["amenity"="atm"]',
  };

  // State Management for Chips
  final Set<String> _selectedCategories = {"Waterfalls", "Viewpoints"};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
      // Filter locally since we already fetched everything in bounding box for the selected categories
      _applyLocalFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndData() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fetchOverpassData();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fetchOverpassData();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fetchOverpassData();
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        timeLimit: const Duration(seconds: 5),
      );
      
      // Smart Fallback: If the user is outside Sri Lanka (e.g., Android Emulator defaults to California),
      // forcefully fallback to Ella, Sri Lanka so they can see actual tourism data!
      if (position.latitude < 5.0 || position.latitude > 10.0 || 
          position.longitude < 79.0 || position.longitude > 82.0) {
        _center = const LatLng(6.8711, 81.0450); // Ella, Sri Lanka
      } else {
        _center = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Geolocator Error: $e");
      // Fallback to default location
    }
    
    _mapController.move(_center, 13.0);
    _fetchOverpassData();
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locating...')));
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_center, 13.0);
      _fetchOverpassData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get current location.')));
      }
    }
  }

  void _applyLocalFilters() {
    if (_allFetchedElements.isEmpty) {
      setState(() {
        _markers = [_buildUserMarker()];
      });
      return;
    }

    final filtered = _allFetchedElements.where((el) {
      if (_searchQuery.isEmpty) return true;
      final tags = el['tags'] ?? {};
      final name = (tags['name'] ?? '').toString().toLowerCase();
      final type = (tags['tourism'] ?? tags['waterway'] ?? tags['natural'] ?? '').toString().toLowerCase();
      
      return name.contains(_searchQuery) || type.contains(_searchQuery);
    }).toList();

    final newMarkers = filtered.map((el) {
      final lat = el['lat'];
      final lon = el['lon'];
      final tags = el['tags'] ?? {};
      final name = tags['name'] ?? 'Unnamed Location';
      final type = tags['tourism'] ?? tags['waterway'] ?? tags['natural'] ?? tags['amenity'] ?? 'Place';

      IconData iconData;
      Color iconColor;

      switch (type) {
        case 'waterfall':
          iconData = Icons.water_drop;
          iconColor = Colors.lightBlueAccent;
          break;
        case 'viewpoint':
        case 'peak':
          iconData = Icons.landscape;
          iconColor = Colors.orangeAccent;
          break;
        case 'camp_site':
          iconData = Icons.park;
          iconColor = Colors.greenAccent;
          break;
        case 'hotel':
        case 'guest_house':
        case 'hostel':
          iconData = Icons.hotel;
          iconColor = Colors.deepPurpleAccent;
          break;
        case 'hospital':
        case 'clinic':
        case 'doctors':
          iconData = Icons.local_hospital;
          iconColor = Colors.redAccent;
          break;
        case 'restaurant':
        case 'cafe':
        case 'fast_food':
          iconData = Icons.restaurant;
          iconColor = Colors.orange;
          break;
        case 'fuel':
          iconData = Icons.local_gas_station;
          iconColor = Colors.blueGrey;
          break;
        case 'atm':
          iconData = Icons.local_atm;
          iconColor = Colors.green;
          break;
        default:
          iconData = Icons.location_on;
          iconColor = AppTheme.emerald;
      }

      return Marker(
        width: 44,
        height: 44,
        point: LatLng(lat, lon),
        child: GestureDetector(
          onTap: () => _showMarkerDetails(name, type, lat, lon),
          child: Container(
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
        ),
      );
    }).toList();

    setState(() {
      _markers = [_buildUserMarker(), ...newMarkers];
    });
  }

  Future<void> _fetchOverpassData() async {
    if (_selectedCategories.isEmpty) {
      setState(() {
        _markers = [
          _buildUserMarker(),
        ];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    double minLat = _center.latitude - 0.108;
    double maxLat = _center.latitude + 0.108;
    double minLon = _center.longitude - 0.108;
    double maxLon = _center.longitude + 0.108;

    // Dynamically build query based on selected categories
    String nodeQueries = '';
    for (String category in _selectedCategories) {
      String baseQuery = _categories[category]!;
      nodeQueries += '$baseQuery($minLat,$minLon,$maxLat,$maxLon);';
    }

    final query = '[out:json][timeout:25];($nodeQueries);out;';

    try {
      String encodedQuery = Uri.encodeQueryComponent(query);
      final response = await http.get(
        Uri.parse('https://overpass.openstreetmap.fr/api/interpreter?data=$encodedQuery'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'CeylonTrekkerApp/1.0',
        },
      );
      
      debugPrint("Overpass API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _allFetchedElements = data['elements'] as List;
        
        _applyLocalFilters();

        if (_allFetchedElements.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No places found nearby for these categories.')),
            );
          }
        }
      } else {
        debugPrint("Overpass Error: non-200 status code");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load nearby places. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Overpass API Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Marker _buildUserMarker() {
    return Marker(
      width: 80,
      height: 80,
      point: _center,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchRoute(double destLat, double destLon, String profile) async {
    final url = 'http://router.project-osrm.org/route/v1/$profile/${_center.longitude},${_center.latitude};$destLon,$destLat?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          List<LatLng> points = geometry.map((coord) {
            return LatLng(coord[1], coord[0]); // GeoJSON is [lon, lat]
          }).toList();
          
          return {
            'points': points,
            'distance': (route['distance'] as num).toDouble(), // meters
            'duration': (route['duration'] as num).toDouble(), // seconds
          };
        }
      }
    } catch (e) {
      debugPrint("OSRM Route Error: $e");
    }
    return null;
  }

  void _showMarkerDetails(String name, String type, double lat, double lon) {
    String selectedVehicle = 'foot'; // default
    bool isFetchingRoute = true;
    double routeDistanceKm = 0;
    String routeDurationText = '';
    List<LatLng> currentRoutePoints = [];

    // Helper inside the function to fetch and update state
    Future<void> loadRoute(StateSetter setStateSheet, String vehicle) async {
      setStateSheet(() => isFetchingRoute = true);
      final result = await _fetchRoute(lat, lon, vehicle);
      if (result != null) {
        setStateSheet(() {
          currentRoutePoints = result['points'];
          routeDistanceKm = result['distance'] / 1000.0;
          
          double durationSecs = result['duration'];
          if (durationSecs < 60) {
            routeDurationText = '< 1 min';
          } else {
            int totalMins = (durationSecs / 60.0).round();
            if (totalMins >= 60) {
              int hrs = totalMins ~/ 60;
              int mins = totalMins % 60;
              routeDurationText = '$hrs hr ${mins} mins';
            } else {
              routeDurationText = '$totalMins mins';
            }
          }
          
          isFetchingRoute = false;
        });
      } else {
        setStateSheet(() => isFetchingRoute = false);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            // Initial load
            if (currentRoutePoints.isEmpty && isFetchingRoute) {
              loadRoute(setStateSheet, selectedVehicle);
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      type.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Vehicle',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildVehicleButton('foot', Icons.directions_walk, 'Walk', selectedVehicle, (v) {
                          setStateSheet(() => selectedVehicle = v);
                          loadRoute(setStateSheet, v);
                        }),
                        _buildVehicleButton('bike', Icons.pedal_bike, 'Bike', selectedVehicle, (v) {
                          setStateSheet(() => selectedVehicle = v);
                          loadRoute(setStateSheet, v);
                        }),
                        _buildVehicleButton('driving', Icons.directions_car, 'Car/Tuk', selectedVehicle, (v) {
                          setStateSheet(() => selectedVehicle = v);
                          loadRoute(setStateSheet, v);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isFetchingRoute)
                    const Center(child: CircularProgressIndicator(color: AppTheme.emerald))
                  else
                    Row(
                      children: [
                        const Icon(Icons.route, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${routeDistanceKm.toStringAsFixed(1)} km | ~$routeDurationText',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isFetchingRoute ? null : () {
                        Navigator.pop(context);
                        setState(() {
                          _routePoints = currentRoutePoints;
                        });
                      },
                      icon: const Icon(Icons.rocket_launch, color: Colors.white),
                      label: const Text('Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleButton(String mode, IconData icon, String label, String selectedMode, Function(String) onTap) {
    bool isSelected = mode == selectedMode;
    return GestureDetector(
      onTap: () => onTap(mode),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emerald : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.emerald : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ceylon_trekker',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: AppTheme.background.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.emerald),
              ),
            ),

          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      String searchStr = value.toLowerCase().trim();
                      
                      // Check if it's a category keyword
                      bool isCategory = false;
                      if (searchStr.contains('hospital') || searchStr.contains('clinic')) {
                        _selectedCategories.add('Hospitals');
                        isCategory = true;
                      } else if (searchStr.contains('restaurant') || searchStr.contains('food')) {
                        _selectedCategories.add('Restaurants');
                        isCategory = true;
                      } else if (searchStr.contains('fuel') || searchStr.contains('gas')) {
                        _selectedCategories.add('Fuel');
                        isCategory = true;
                      } else if (searchStr.contains('atm') || searchStr.contains('bank')) {
                        _selectedCategories.add('ATMs');
                        isCategory = true;
                      } else if (searchStr.contains('waterfall')) {
                        _selectedCategories.add('Waterfalls');
                        isCategory = true;
                      } else if (searchStr.contains('camp')) {
                        _selectedCategories.add('Camping');
                        isCategory = true;
                      } else if (searchStr.contains('hotel') || searchStr.contains('stay')) {
                        _selectedCategories.add('Hotels/Stays');
                        isCategory = true;
                      }

                      if (isCategory) {
                        _fetchOverpassData();
                        return; // Stop here, no need to geocode
                      }

                      // Otherwise, treat it as a city search and geocode it
                      try {
                        List<Location> locations = await locationFromAddress(value);
                        if (locations.isNotEmpty) {
                          final loc = locations.first;
                          setState(() {
                            _center = LatLng(loc.latitude, loc.longitude);
                            _mapController.move(_center, 13.0);
                          });
                          _fetchOverpassData();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found. Try a city name or category.')));
                        }
                      }
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search places nearby...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                  ),
                ),
                
                // Category Filters
                Container(
                  height: 60,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _categories.keys.map((String cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                            _fetchOverpassData();
                          },
                          backgroundColor: AppTheme.surfaceElevated,
                          selectedColor: AppTheme.emerald,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppTheme.emerald : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          if (_routePoints.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 140.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _routePoints.clear();
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Cancel Navigation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
            ),
            
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 140.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.emerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_markers.length > 0 ? _markers.length - 1 : 0} spots found nearby',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'my_location_btn',
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppTheme.emerald),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'refresh_btn',
              onPressed: () {
                if (!_isLoading) {
                  _fetchOverpassData();
                }
              },
              backgroundColor: AppTheme.emerald,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
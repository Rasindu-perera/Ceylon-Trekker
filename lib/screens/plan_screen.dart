import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_theme.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  // 1. Store generated trip places in a mutable list
  List<Map<String, dynamic>> itineraryPlaces = [
    {'title': 'Sigiriya Rock Fortress', 'type': 'Historical', 'lat': 7.9541, 'lng': 80.7583},
    {'title': 'Temple of the Tooth', 'type': 'Historical', 'lat': 7.2936, 'lng': 80.6413},
    {'title': 'Royal Botanical Gardens', 'type': 'Nature', 'lat': 7.2718, 'lng': 80.5966},
    {'title': 'Ella Rock', 'type': 'Hiking', 'lat': 6.8625, 'lng': 81.0456},
    {'title': 'Nine Arches Bridge', 'type': 'Sightseeing', 'lat': 6.8767, 'lng': 81.0607},
  ];

  // Map and Routing State
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _validPlaces = [];
  double _calculatedDistance = 0.0; // km
  bool _isRouting = false;

  // Trip Settings
  int _numPeople = 2;
  int _numDays = 3;
  double _vehicleEfficiency = 12.0; // km/L
  double _fuelPrice = 350.0; // Rs/L
  double _baseDailyBudget = 5000.0; // Rs/person/day

  // Cost Variables
  double _estimatedFuelCost = 0.0;
  double _estimatedFoodStayCost = 0.0;
  double _totalEstimatedCost = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateRouteAndDistance();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    final double distance = _calculatedDistance; 
    
    _estimatedFuelCost = 0.0;
    if (_vehicleEfficiency > 0) {
      _estimatedFuelCost = (distance / _vehicleEfficiency) * _fuelPrice;
    }
    
    _estimatedFoodStayCost = (_numPeople * _numDays * _baseDailyBudget).toDouble();
    
    setState(() {
      _totalEstimatedCost = _estimatedFuelCost + _estimatedFoodStayCost;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _calculateRouteAndDistance() async {
    if (itineraryPlaces.isEmpty) {
      setState(() {
        _validPlaces = [];
        _routePoints = [];
        _calculatedDistance = 0.0;
        _calculateCost();
      });
      return;
    }

    setState(() {
      _isRouting = true;
    });

    List<Map<String, dynamic>> valid = [];
    
    // We already have lat/lng from dummy data or AI
    for (var place in itineraryPlaces) {
      if (place['lat'] != null && place['lng'] != null) {
        valid.add(place);
      }
    }

    // Point-to-Point Straight Line Distance using latlong2
    const distanceObj = Distance();
    for (int i = 0; i < valid.length; i++) {
      if (i == 0) {
        valid[i]['distanceFromPrevious'] = 0.0;
      } else {
        final p1 = LatLng(valid[i-1]['lat'], valid[i-1]['lng']);
        final p2 = LatLng(valid[i]['lat'], valid[i]['lng']);
        valid[i]['distanceFromPrevious'] = distanceObj.as(LengthUnit.Kilometer, p1, p2);
      }
    }

    if (valid.length < 2) {
      setState(() {
        _validPlaces = valid;
        _routePoints = [];
        _calculatedDistance = 0.0;
        _isRouting = false;
        _calculateCost();
      });
      if (valid.isNotEmpty) {
        try {
          _mapController.move(LatLng(valid.first['lat'], valid.first['lng']), 12);
        } catch (_) {}
      }
      return;
    }

    // OSRM Routing
    final coordinates = valid.map((p) => '${p['lng']},${p['lat']}').join(';');
    final url = 'http://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distanceMeters = (route['distance'] as num).toDouble();
          final encodedGeometry = route['geometry'] as String;

          final decodedRoute = _decodePolyline(encodedGeometry);

          setState(() {
            _validPlaces = valid;
            _routePoints = decodedRoute;
            _calculatedDistance = distanceMeters / 1000.0; // km
            _isRouting = false;
            _calculateCost();
          });

          // Fit map bounds
          if (decodedRoute.isNotEmpty) {
            try {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(decodedRoute),
                  padding: const EdgeInsets.all(48),
                ),
              );
            } catch (_) {}
          }
        }
      } else {
        throw Exception('Failed to route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OSRM Error: $e');
      setState(() {
        _validPlaces = valid;
        _routePoints = [];
        _calculatedDistance = 0.0;
        _isRouting = false;
        _calculateCost();
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = itineraryPlaces.removeAt(oldIndex);
      itineraryPlaces.insert(newIndex, item);
    });
    _calculateRouteAndDistance();
  }

  void _removePlace(int index) {
    setState(() {
      itineraryPlaces.removeAt(index);
    });
    _calculateRouteAndDistance();
  }

  Future<void> _saveTrip() async {
    if (itineraryPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one place.')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save your trip.')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('## Your Itinerary Route');
    for (var i = 0; i < itineraryPlaces.length; i++) {
      buffer.writeln('${i+1}. **${itineraryPlaces[i]['title']}** (${itineraryPlaces[i]['type']})');
    }
    buffer.writeln('\\n## Budget Breakdown');
    buffer.writeln('- Route Distance: **${_calculatedDistance.toStringAsFixed(1)} km**');
    buffer.writeln('- Fuel Cost: **Rs ${_estimatedFuelCost.toStringAsFixed(0)}**');
    buffer.writeln('- Food & Stay Cost: **Rs ${_estimatedFoodStayCost.toStringAsFixed(0)}**');
    buffer.writeln('- Estimated Total: **Rs ${_totalEstimatedCost.toStringAsFixed(0)}**');

    final tripData = {
      'createdAt': DateTime.now().toIso8601String(),
      'timestamp': ServerValue.timestamp, 
      'places': itineraryPlaces,
      'routeDistanceKm': _calculatedDistance,
      'fuelCost': _estimatedFuelCost,
      'foodStayCost': _estimatedFoodStayCost,
      'totalEstimatedCost': _totalEstimatedCost,
      'vehicleEfficiency': _vehicleEfficiency,
      'fuelPrice': _fuelPrice,
      'baseDailyBudget': _baseDailyBudget,
      'numPeople': _numPeople,
      'numDays': _numDays,
      'destination': itineraryPlaces.first['title'],
      'dates': itineraryPlaces.length.toString(), 
      'travelers': _numPeople.toString(),
      'plan': buffer.toString(),
    };

    try {
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
      ).ref('users/$uid/trip_history');
      
      await ref.push().set(tripData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip saved to history!')));
        setState(() {
          itineraryPlaces.clear();
          _routePoints.clear();
          _validPlaces.clear();
          _calculatedDistance = 0.0;
          _calculateCost();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save trip: $e')));
      }
    }
  }

  Future<void> _startNavigation() async {
    final valid = _validPlaces;
    if (valid.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 2 valid places to navigate.')));
      return;
    }

    final origin = '${valid.first['lat']},${valid.first['lng']}';
    final destination = '${valid.last['lat']},${valid.last['lng']}';
    
    String waypointsStr = '';
    if (valid.length > 2) {
      final waypoints = valid.sublist(1, valid.length - 1);
      waypointsStr = '&waypoints=' + waypoints.map((p) => '${p['lat']},${p['lng']}').join('|');
    }

    final urlString = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination$waypointsStr&travelmode=driving';
    final uri = Uri.parse(urlString);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching navigation: $e')));
      }
    }
  }

  void _openTripSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripSettingsSheet(
        initialPeople: _numPeople,
        initialDays: _numDays,
        initialEfficiency: _vehicleEfficiency,
        initialFuelPrice: _fuelPrice,
        initialDailyBudget: _baseDailyBudget,
        onSave: (people, days, eff, fuel, budget) {
          setState(() {
            _numPeople = people;
            _numDays = days;
            _vehicleEfficiency = eff;
            _fuelPrice = fuel;
            _baseDailyBudget = budget;
          });
          _calculateCost();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Trip Plan', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Trip Settings & Budget',
            onPressed: _openTripSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top: Map View
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(7.8731, 80.7718),
                      initialZoom: 7.0,
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
                              color: AppTheme.emerald,
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: _validPlaces.map((p) {
                          return Marker(
                            point: LatLng(p['lat'], p['lng']),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (_isRouting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.emerald),
                      ),
                    ),
                ],
              ),
            ),
            
            // Middle: Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                boxShadow: [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 8),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trip Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Distance:', style: TextStyle(color: Colors.white70)),
                      Text('${_calculatedDistance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Est. Fuel Cost:', style: TextStyle(color: Colors.white70)),
                      Text('Rs ${_estimatedFuelCost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Food & Stay:', style: TextStyle(color: Colors.white70)),
                      Text('Rs ${_estimatedFoodStayCost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Cost', style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                      Text('Rs ${_totalEstimatedCost.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.emerald, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom: Reorderable List
            Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: itineraryPlaces.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final place = itineraryPlaces[index];
                  // Calculate straight line distance text
                  String subtitleText = place['type'] ?? '';
                  if (place['distanceFromPrevious'] != null && place['distanceFromPrevious'] > 0) {
                    subtitleText += ' • ${place['distanceFromPrevious'].toStringAsFixed(1)} km from previous';
                  }

                  return Dismissible(
                    key: ValueKey('${place['title']}_$index'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _removePlace(index),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
                    ),
                    child: Card(
                      key: ValueKey('card_${place['title']}_$index'),
                      color: AppTheme.surfaceElevated,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.drag_indicator, color: Colors.white54),
                        title: Text(place['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitleText, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                          onPressed: () => _removePlace(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Action Buttons moved from bottomNavigationBar
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: AppTheme.surfaceElevated,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AiSmartSearchSheet(
                          onAddPlaces: (newPlaces) {
                            setState(() {
                              itineraryPlaces.addAll(newPlaces);
                            });
                            _calculateRouteAndDistance();
                          },
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.emerald, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Place', style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text('Start Trip (Maps)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// TRIP SETTINGS BOTTOM SHEET
// ---------------------------------------------------------
class TripSettingsSheet extends StatefulWidget {
  final int initialPeople;
  final int initialDays;
  final double initialEfficiency;
  final double initialFuelPrice;
  final double initialDailyBudget;
  final Function(int, int, double, double, double) onSave;

  const TripSettingsSheet({
    super.key,
    required this.initialPeople,
    required this.initialDays,
    required this.initialEfficiency,
    required this.initialFuelPrice,
    required this.initialDailyBudget,
    required this.onSave,
  });

  @override
  State<TripSettingsSheet> createState() => _TripSettingsSheetState();
}

class _TripSettingsSheetState extends State<TripSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _peopleCtrl;
  late final TextEditingController _daysCtrl;
  late final TextEditingController _effCtrl;
  late final TextEditingController _fuelCtrl;
  late final TextEditingController _budgetCtrl;

  @override
  void initState() {
    super.initState();
    _peopleCtrl = TextEditingController(text: widget.initialPeople.toString());
    _daysCtrl = TextEditingController(text: widget.initialDays.toString());
    _effCtrl = TextEditingController(text: widget.initialEfficiency.toString());
    _fuelCtrl = TextEditingController(text: widget.initialFuelPrice.toString());
    _budgetCtrl = TextEditingController(text: widget.initialDailyBudget.toString());
  }

  @override
  void dispose() {
    _peopleCtrl.dispose();
    _daysCtrl.dispose();
    _effCtrl.dispose();
    _fuelCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Trip Settings & Budget', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Number of People', _peopleCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Number of Days', _daysCtrl)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Efficiency (km/L)', _effCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Fuel Price (Rs/1L)', _fuelCtrl)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Base Daily Budget per Person (Food & Stay)', _budgetCtrl),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave(
                        int.tryParse(_peopleCtrl.text) ?? widget.initialPeople,
                        int.tryParse(_daysCtrl.text) ?? widget.initialDays,
                        double.tryParse(_effCtrl.text) ?? widget.initialEfficiency,
                        double.tryParse(_fuelCtrl.text) ?? widget.initialFuelPrice,
                        double.tryParse(_budgetCtrl.text) ?? widget.initialDailyBudget,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}

// ---------------------------------------------------------
// AI SMART SEARCH BOTTOM SHEET
// ---------------------------------------------------------
class AiSmartSearchSheet extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onAddPlaces;
  const AiSmartSearchSheet({super.key, required this.onAddPlaces});

  @override
  State<AiSmartSearchSheet> createState() => _AiSmartSearchSheetState();
}

class _AiSmartSearchSheetState extends State<AiSmartSearchSheet> {
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showResults = false;
  List<Map<String, dynamic>> _suggestions = [];
  List<bool> _checkedState = [];

  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<void> _getGroqSuggestions() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    final prompt = """
User query: "${_searchCtrl.text}"
If the user input is a specific place, return just that place. If it's a tag/category + location, suggest 3 suitable places in Sri Lanka.
Return ONLY a valid JSON array of objects without any markdown formatting.
Each object MUST have: "title" (string), "category" (string), "extract" (string), "image" (use a valid Unsplash seed URL like 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=500' if unknown), "tags" (array), "lat" (number), and "lng" (number).
""".trim();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", 
          "messages": [
            {
              "role": "system",
              "content": "You are a helpful travel assistant. You only output strict, raw, unformatted JSON arrays. Never output conversational text. Never wrap json in backticks."
            },
            {
              "role": "user",
              "content": prompt
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].toString().trim();
        
        if (content.startsWith('```json')) content = content.substring(7);
        if (content.startsWith('```')) content = content.substring(3);
        if (content.endsWith('```')) content = content.substring(0, content.length - 3);
        content = content.trim();

        final List<dynamic> parsed = jsonDecode(content);
        
        setState(() {
          _suggestions = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _checkedState = List<bool>.filled(_suggestions.length, true);
          _showResults = true;
          _isLoading = false;
        });
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search: $e')));
      }
    }
  }

  void _addSelected() {
    List<Map<String, dynamic>> selected = [];
    for (int i = 0; i < _suggestions.length; i++) {
      if (_checkedState[i]) {
        selected.add({
          'title': _suggestions[i]['title'] ?? 'Unknown',
          'type': _suggestions[i]['category'] ?? 'General',
          'lat': _suggestions[i]['lat'],
          'lng': _suggestions[i]['lng'],
        });
      }
    }
    widget.onAddPlaces(selected);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.emerald),
                    SizedBox(height: 16),
                    Text('AI is searching coordinates...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            )
          : _showResults
              ? _buildResultsView()
              : _buildSearchView(),
    );
  }

  Widget _buildSearchView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Search', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: "Search Location or Tags (e.g. 'Sigiriya' or 'Camping')",
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _getGroqSuggestions,
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('Search places', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Search Results', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final place = _suggestions[index];
              return CheckboxListTile(
                value: _checkedState[index],
                onChanged: (val) {
                  if (val != null) setState(() => _checkedState[index] = val);
                },
                title: Text(place['title'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                subtitle: Text(place['category'] ?? 'General', style: const TextStyle(color: Colors.white54)),
                activeColor: AppTheme.emerald,
                checkColor: Colors.white,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showResults = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _addSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Selected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }
}
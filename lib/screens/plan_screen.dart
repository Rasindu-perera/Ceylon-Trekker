import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../app/app_theme.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _datesController = TextEditingController();
  final TextEditingController _travelersController = TextEditingController();
  String _travelStyle = 'Adventure';
  
  bool _isLoading = false;
  String? _generatedPlan;

  String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<void> _generatePlan() async {
    final dest = _destinationController.text.trim();
    final dates = _datesController.text.trim();
    final travelers = _travelersController.text.trim();

    if (dest.isEmpty || dates.isEmpty || travelers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields to generate a plan.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedPlan = null;
    });

    final prompt = "Create a highly detailed, strict $dates-day travel itinerary for $travelers people visiting $dest. The travel style is $_travelStyle. CRITICAL INSTRUCTION: You MUST provide exactly $dates days. Do not exceed $dates days under any circumstances. Format the output using Markdown with ## Day headers.";

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
              "content": "You are 'Ceylon Trekker AI', an expert and premium travel guide for Sri Lanka. ALWAYS respond in clear, professional, and natural ENGLISH. Structure your answers clearly using bullet points and bold text for place names. Keep answers concise, highly relevant, and practical."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        setState(() {
          _generatedPlan = content;
        });

        // Save to Firebase Realtime Database
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            final ref = FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app'
            ).ref('users/$uid/trip_history');
            
            await ref.push().set({
              'destination': dest,
              'dates': dates,
              'travelers': travelers,
              'travelStyle': _travelStyle,
              'plan': content,
              'timestamp': ServerValue.timestamp,
            });
          } catch (e) {
            debugPrint('Failed to save trip history: $e');
          }
        }
      } else {
        setState(() {
          _generatedPlan = "Error connecting to Groq API (Code: ${response.statusCode})\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _generatedPlan = "Network error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Text(
                'AI Trip Planner',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crafting your perfect island escape.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('DESTINATION'),
                    _buildTextField(_destinationController, 'e.g., Ella, Central Province', Icons.location_on_outlined),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('DATES'),
                              _buildTextField(_datesController, 'e.g., 3 Days', Icons.calendar_today_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('TRAVELERS'),
                              _buildTextField(_travelersController, 'e.g., 2 Explorers', Icons.people_outline),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildInputLabel('TRAVEL STYLE'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _travelStyle,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceElevated,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _travelStyle = newValue;
                              });
                            }
                          },
                          items: <String>['Adventure', 'Relaxing', 'Cultural', 'Budget']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generatePlan,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20, height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Optimizing Plan...' : 'Create Optimized Plan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          disabledBackgroundColor: AppTheme.emerald.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Result Area
              if (_generatedPlan != null) ...[
                Row(
                  children: [
                    const Icon(Icons.explore_outlined, color: AppTheme.emerald),
                    const SizedBox(width: 8),
                    Text(
                      'AI Suggestions',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: MarkdownBody(
                    data: _generatedPlan!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                      h2: const TextStyle(color: AppTheme.emerald, fontSize: 20, fontWeight: FontWeight.bold, height: 2.0),
                      h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.8),
                      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: AppTheme.emerald, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
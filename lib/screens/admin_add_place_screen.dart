import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../app/app_theme.dart';

class AdminAddPlaceScreen extends StatefulWidget {
  const AdminAddPlaceScreen({super.key});

  @override
  State<AdminAddPlaceScreen> createState() => _AdminAddPlaceScreenState();
}

class _AdminAddPlaceScreenState extends State<AdminAddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _extractController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _editingKey;
  
  String _bulkJsonData = '''[]''';
  late final DatabaseReference _dbRef;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://ceylon-trekker-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('places');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _extractController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final file = File(pickedFile.path);
        final fileName = 'place_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref('place_images/$fileName');
        
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        setState(() {
          _imageUrlController.text = downloadUrl;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: AppTheme.emerald),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tagsList = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final placeData = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'extract': _extractController.text.trim(),
        'image': _imageUrlController.text.trim(),
        'tags': tagsList,
        'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
      };

      if (_editingKey == null) {
        await _dbRef.push().set(placeData);
      } else {
        await _dbRef.child(_editingKey!).update(placeData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingKey == null ? 'Place added successfully!' : 'Place updated successfully!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save place: $e'),
            backgroundColor: Colors.redAccent,
          ),
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

  void _clearForm() {
    _titleController.clear();
    _categoryController.clear();
    _extractController.clear();
    _imageUrlController.clear();
    _tagsController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    setState(() {
      _editingKey = null;
    });
  }

  Future<void> _bulkUploadPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> parsedList = jsonDecode(_bulkJsonData);

      for (var item in parsedList) {
        if (item is Map<String, dynamic>) {
          item['createdAt'] = DateTime.now().toIso8601String();
          await _dbRef.push().set(item);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulk upload complete!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed bulk upload: $e'),
            backgroundColor: Colors.redAccent,
          ),
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

  void _editPlace(String key, Map<dynamic, dynamic> data) {
    setState(() {
      _editingKey = key;
      _titleController.text = data['title'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _extractController.text = data['extract'] ?? '';
      _imageUrlController.text = data['image'] ?? '';
      
      final tagsList = data['tags'] as List<dynamic>? ?? [];
      _tagsController.text = tagsList.join(', ');
      
      _latitudeController.text = (data['latitude'] ?? 0.0).toString();
      _longitudeController.text = (data['longitude'] ?? 0.0).toString();
    });
  }

  Future<void> _deletePlace(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Delete Place', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this place?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbRef.child(key).remove();
        if (_editingKey == key) {
          _clearForm();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Place deleted.'), backgroundColor: AppTheme.emerald),
          );
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_titleController, 'Title', 'Enter place title'),
                    const SizedBox(height: 16),
                    _buildTextField(_categoryController, 'Category', 'e.g., Hiking, Waterfalls'),
                    const SizedBox(height: 16),
                    _buildTextField(_extractController, 'Description', 'Enter short extract/description', maxLines: 3),
                    const SizedBox(height: 16),
                    
                    // Image Upload Row
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_imageUrlController, 'Image URL', 'Enter image network URL')),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: _isUploadingImage 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.emerald, strokeWidth: 2))
                                : const Icon(Icons.image, color: AppTheme.emerald),
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            tooltip: 'Upload Image',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(_tagsController, 'Tags', 'Comma separated tags'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_latitudeController, 'Latitude', 'e.g., 6.9271', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_longitudeController, 'Longitude', 'e.g., 79.8612', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePlace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _editingKey == null ? 'Save to Firebase' : 'Update Place',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    if (_editingKey != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearForm,
                        child: const Text('Cancel Edit', style: TextStyle(color: Colors.white54)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Places List StreamBuilder
          Expanded(
            flex: 4,
            child: _buildPlacesList(),
          ),
          /* Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _bulkUploadPlaces,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Bulk Upload from JSON',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ), */
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.emerald));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading places.', style: TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No places found.', style: TextStyle(color: Colors.white54)));
        }

        final Map<dynamic, dynamic> placesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final List<MapEntry<dynamic, dynamic>> placesList = placesMap.entries.toList();

        return ListView.builder(
          itemCount: placesList.length,
          itemBuilder: (context, index) {
            final entry = placesList[index];
            final key = entry.key.toString();
            final data = Map<String, dynamic>.from(entry.value as Map);
            
            final title = data['title'] ?? 'Unknown';
            final category = data['category'] ?? '';
            final imageUrl = data['image'] ?? '';

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.white54))
                    : const Icon(Icons.image, color: Colors.white54, size: 50),
              ),
              title: Text(title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(category, style: const TextStyle(color: Colors.white54)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.emerald),
                    onPressed: () => _editPlace(key, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deletePlace(key),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.emerald, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

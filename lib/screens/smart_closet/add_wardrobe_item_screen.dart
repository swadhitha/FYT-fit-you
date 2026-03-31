import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../services/local_storage_service.dart';
import '../../models/wardrobe_item_model.dart';

class AddWardrobeItemScreen extends StatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  State<AddWardrobeItemScreen> createState() => _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends State<AddWardrobeItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Dropdown selections
  String? _selectedCategory;
  String? _selectedPattern;
  String? _selectedFabric;
  
  // Multi-select lists
  List<String> _selectedSeasons = [];
  List<String> _selectedOccasionTags = [];
  
  // Image
  File? _selectedImage;
  bool _isSaving = false;

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Shoes',
    'Accessories',
    'Outerwear',
    'Ethnic',
    'Formal',
    'Casual',
    'Sportswear'
  ];

  final List<String> _patterns = [
    'Solid',
    'Striped',
    'Floral',
    'Checkered',
    'Printed',
    'Plain',
    'Abstract'
  ];

  final List<String> _fabrics = [
    'Cotton',
    'Polyester',
    'Silk',
    'Denim',
    'Linen',
    'Wool',
    'Synthetic',
    'Blend'
  ];

  final List<String> _seasons = [
    'Summer',
    'Winter',
    'Monsoon',
    'Spring',
    'All Season'
  ];

  final List<String> _occasionTags = [
    'Casual',
    'Formal',
    'Party',
    'Work',
    'Wedding',
    'Festive',
    'Sports',
    'Beach',
    'Date'
  ];

  final List<String> _colorChips = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow',
    'Pink', 'Purple', 'Brown', 'Grey', 'Beige', 'Navy', 'Orange'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Add Wardrobe Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                _buildImageSection(),
                
                const SizedBox(height: 24),
                
                // Basic Information
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildColorSection(),
                
                const SizedBox(height: 24),
                
                // Details
                _buildSectionTitle('Details'),
                const SizedBox(height: 16),
                _buildPatternDropdown(),
                const SizedBox(height: 16),
                _buildFabricDropdown(),
                
                const SizedBox(height: 24),
                
                // Tags
                _buildSectionTitle('Season & Occasion'),
                const SizedBox(height: 16),
                _buildSeasonChips(),
                const SizedBox(height: 16),
                _buildOccasionChips(),
                
                const SizedBox(height: 24),
                
                // Notes
                _buildSectionTitle('Notes (Optional)'),
                const SizedBox(height: 16),
                _buildNotesField(),
                
                const SizedBox(height: 32),
                
                // Save Button
                _buildSaveButton(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add Photo',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Item Name *',
        hintText: 'Enter item name',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter item name';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category *',
        hintText: 'Select category',
        border: OutlineInputBorder(),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color *'),
        const SizedBox(height: 8),
        // Color chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorChips.map((color) {
            final isSelected = _colorController.text == color;
            return FilterChip(
              label: Text(color),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  _colorController.text = selected ? color : '';
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Custom color input
        TextFormField(
          controller: _colorController,
          decoration: const InputDecoration(
            labelText: 'Custom Color',
            hintText: 'Enter custom color name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select or enter a color';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPatternDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPattern,
      decoration: const InputDecoration(
        labelText: 'Pattern',
        hintText: 'Select pattern',
        border: OutlineInputBorder(),
      ),
      items: _patterns.map((pattern) {
        return DropdownMenuItem(
          value: pattern,
          child: Text(pattern),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPattern = value;
        });
      },
    );
  }

  Widget _buildFabricDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFabric,
      decoration: const InputDecoration(
        labelText: 'Fabric',
        hintText: 'Select fabric',
        border: OutlineInputBorder(),
      ),
      items: _fabrics.map((fabric) {
        return DropdownMenuItem(
          value: fabric,
          child: Text(fabric),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedFabric = value;
        });
      },
    );
  }

  Widget _buildSeasonChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Season'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _seasons.map((season) {
            final isSelected = _selectedSeasons.contains(season);
            return FilterChip(
              label: Text(season),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSeasons.add(season);
                  } else {
                    _selectedSeasons.remove(season);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOccasionChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Occasion Tags'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _occasionTags.map((occasion) {
            final isSelected = _selectedOccasionTags.contains(occasion);
            return FilterChip(
              label: Text(occasion),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedOccasionTags.add(occasion);
                  } else {
                    _selectedOccasionTags.remove(occasion);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveItem,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Saving...'),
                ],
              )
            : const Text('Save Item'),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save image to local storage
      final fileName = '${const Uuid().v4()}.jpg';
      final savedImagePath = await LocalStorageService.saveImageToLocal(_selectedImage!, fileName);

      // Create wardrobe item
      final wardrobeItem = WardrobeItem(
        id: const Uuid().v4(),
        userId: 'demo_user', // For demo purposes
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        color: _colorController.text.trim(),
        pattern: _selectedPattern,
        fabric: _selectedFabric,
        seasons: _selectedSeasons,
        occasionTags: _selectedOccasionTags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        imagePath: savedImagePath,
        isFavorite: false,
        dateAdded: DateTime.now(),
      );

      // Save to local storage
      await LocalStorageService.saveWardrobeItem(wardrobeItem);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

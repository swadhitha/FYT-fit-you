import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/design/app_colors.dart';
import 'package:my_flutter_app/widgets/fyt_button.dart';
import 'package:my_flutter_app/providers/user_provider.dart';
import 'package:my_flutter_app/providers/wardrobe_provider.dart';

class AddWardrobeItemScreen extends StatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  State<AddWardrobeItemScreen> createState() => _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends State<AddWardrobeItemScreen> {
  final _nameCtrl = TextEditingController();
  String _category = 'Top';
  String _color = 'Black';
  String _fabric = 'Cotton';
  String _formality = 'Casual';
  File? _image;

  final _categories = ['Top', 'Bottom', 'Dress', 'Outerwear', 'Footwear', 'Accessory'];
  final _colors = [
    'Black', 'White', 'Grey', 'Navy', 'Blue', 'Light Blue',
    'Beige', 'Cream', 'Khaki', 'Maroon', 'Brown',
    'Olive', 'Pink', 'Red', 'Mustard', 'Purple',
  ];
  final _fabrics = ['Cotton', 'Linen', 'Polyester', 'Denim', 'Wool', 'Silk', 'Rayon', 'Leather'];
  final _formalities = ['Casual', 'Smart Casual', 'Semi-Formal', 'Formal'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    }
  }

  Future<void> _save() async {
    final userId = context.read<UserProvider>().userId;
    final wardrobe = context.read<WardrobeProvider>();

    final success = await wardrobe.addItem(
      userId: userId,
      category: _category,
      color: _color,
      formality: _formality,
      name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      fabric: _fabric,
      imageFile: _image,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to your closet!')),
        );
        Navigator.pop(context);
      } else if (wardrobe.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wardrobe.error!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<WardrobeProvider>().loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add photo of your clothes'),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Name field
              Text('Item Name (optional)', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. White Oxford Shirt',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _dropdown(context, 'Category', _categories, _category,
                  (v) => setState(() => _category = v!)),
              const SizedBox(height: AppSpacing.md),

              // Color selector as chips
              Text('Color', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: _color == c,
                          selectedColor:
                              AppColors.accentLavender.withOpacity(0.4),
                          onSelected: (_) => setState(() => _color = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              _dropdown(context, 'Fabric', _fabrics, _fabric,
                  (v) => setState(() => _fabric = v!)),
              const SizedBox(height: AppSpacing.md),

              _dropdown(context, 'Formality', _formalities, _formality,
                  (v) => setState(() => _formality = v!)),
              const SizedBox(height: AppSpacing.xl),

              if (loading)
                const Center(child: CircularProgressIndicator())
              else
                FytButton(label: 'Save to Closet', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(BuildContext context, String label, List<String> options,
      String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label(context)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(),
          value: value,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
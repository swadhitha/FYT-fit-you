import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../services/local_storage_service.dart';
import '../../models/body_profile_model.dart';
import 'body_scan_screen.dart';

class BodyBlueprintScreen extends StatefulWidget {
  const BodyBlueprintScreen({super.key});

  @override
  State<BodyBlueprintScreen> createState() => _BodyBlueprintScreenState();
}

class _BodyBlueprintScreenState extends State<BodyBlueprintScreen> {
  BodyProfile? _bodyProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBodyProfile();
  }

  Future<void> _loadBodyProfile() async {
    try {
      // For demo purposes, use a fixed user ID
      const userId = 'demo_user';
      final profile = await LocalStorageService.getBodyProfile(userId);
      setState(() {
        _bodyProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Body Blueprint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_bodyProfile == null) {
      return _buildEmptyState();
    }
    return _buildProfileView();
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 60,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No Body Profile Yet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Scan your body to get personalized recommendations',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BodyScanScreen()),
            );
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Scan Body'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showManualEntryDialog,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Manually'),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Body Blueprint',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.edit),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BodyScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Body silhouette card
        _buildBodySilhouetteCard(),
        
        const SizedBox(height: 24),
        
        // Measurements grid
        _buildMeasurementsGrid(),
        
        const SizedBox(height: 24),
        
        // Body type card
        _buildBodyTypeCard(),
        
        const SizedBox(height: 24),
        
        // Last scanned info
        _buildLastScannedInfo(),
      ],
    );
  }

  Widget _buildBodySilhouetteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Simple body silhouette
          CustomPaint(
            size: const Size(200, 300),
            painter: BodySilhouettePainter(_bodyProfile!),
          ),
          const SizedBox(height: 16),
          Text(
            'Body Type: ${_bodyProfile!.bodyType ?? 'Unknown'}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsGrid() {
    final measurements = [
      {'label': 'Shoulder Width', 'value': '${_bodyProfile!.shoulderWidth?.toStringAsFixed(1) ?? 'N/A'} cm'},
      {'label': 'Hip Width', 'value': '${_bodyProfile!.hipWidth?.toStringAsFixed(1) ?? 'N/A'} cm'},
      {'label': 'Torso Length', 'value': '${_bodyProfile!.torsoLength?.toStringAsFixed(1) ?? 'N/A'} cm'},
      {'label': 'Leg Length', 'value': '${_bodyProfile!.legLength?.toStringAsFixed(1) ?? 'N/A'} cm'},
      {'label': 'Arm Length', 'value': '${_bodyProfile!.armLength?.toStringAsFixed(1) ?? 'N/A'} cm'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Measurements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      measurement['label']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      measurement['value']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeCard() {
    final bodyType = _bodyProfile!.bodyType ?? 'Unknown';
    final description = _getBodyTypeDescription(bodyType);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Type Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bodyType,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScannedInfo() {
    final scannedDate = _bodyProfile!.analyzedAt;
    final formattedDate = '${scannedDate.day}/${scannedDate.month}/${scannedDate.year}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last scanned on $formattedDate at ${scannedDate.hour.toString().padLeft(2, '0')}:${scannedDate.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBodyTypeDescription(String bodyType) {
    switch (bodyType) {
      case 'Inverted Triangle':
        return 'Your shoulders are broader than your hips. Consider balancing proportions with bottoms that add volume to your lower body.';
      case 'Pear':
        return 'Your hips are wider than your shoulders. Enhance your upper body with structured tops and shoulder pads.';
      case 'Apple':
        return 'You have a fuller midsection. Choose fabrics that drape well and avoid tight-fitting clothes around the waist.';
      case 'Rectangle':
        return 'Your shoulders and hips are roughly the same width. Create curves with layered clothing and different textures.';
      default:
        return 'Your body type helps us recommend the best fitting clothes for your unique shape.';
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        onSave: (profile) async {
          try {
            const userId = 'demo_user';
            await LocalStorageService.saveBodyProfile(userId, profile);
            await _loadBodyProfile();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.primary,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: ${e.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        initialProfile: _bodyProfile,
      ),
    );
  }
}

class _ManualEntryDialog extends StatefulWidget {
  final Function(BodyProfile) onSave;
  final BodyProfile? initialProfile;

  const _ManualEntryDialog({
    required this.onSave,
    this.initialProfile,
  });

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _shoulderWidthController = TextEditingController();
  final _hipWidthController = TextEditingController();
  final _torsoLengthController = TextEditingController();
  final _legLengthController = TextEditingController();
  final _armLengthController = TextEditingController();
  String _selectedBodyType = 'Rectangle';

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _shoulderWidthController.text = widget.initialProfile!.shoulderWidth?.toString() ?? '';
      _hipWidthController.text = widget.initialProfile!.hipWidth?.toString() ?? '';
      _torsoLengthController.text = widget.initialProfile!.torsoLength?.toString() ?? '';
      _legLengthController.text = widget.initialProfile!.legLength?.toString() ?? '';
      _armLengthController.text = widget.initialProfile!.armLength?.toString() ?? '';
      _selectedBodyType = widget.initialProfile!.bodyType ?? 'Rectangle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Body Measurements'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _shoulderWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Shoulder Width (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hipWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Hip Width (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _torsoLengthController,
                  decoration: const InputDecoration(
                    labelText: 'Torso Length (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _legLengthController,
                  decoration: const InputDecoration(
                    labelText: 'Leg Length (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _armLengthController,
                  decoration: const InputDecoration(
                    labelText: 'Arm Length (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedBodyType,
                  decoration: const InputDecoration(
                    labelText: 'Body Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Rectangle', child: Text('Rectangle')),
                    DropdownMenuItem(value: 'Inverted Triangle', child: Text('Inverted Triangle')),
                    DropdownMenuItem(value: 'Pear', child: Text('Pear')),
                    DropdownMenuItem(value: 'Apple', child: Text('Apple')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBodyType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveProfile,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = BodyProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shoulderWidth: double.tryParse(_shoulderWidthController.text),
        hipWidth: double.tryParse(_hipWidthController.text),
        torsoLength: double.tryParse(_torsoLengthController.text),
        legLength: double.tryParse(_legLengthController.text),
        armLength: double.tryParse(_armLengthController.text),
        bodyType: _selectedBodyType,
        analyzedAt: DateTime.now(),
      );
      widget.onSave(profile);
    }
  }
}

class BodySilhouettePainter extends CustomPainter {
  final BodyProfile profile;

  BodySilhouettePainter(this.profile);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    const topY = 20.0;

    // Draw simple body silhouette based on body type
    final path = Path();
    
    // Head
    path.addOval(Rect.fromCenter(center: Offset(centerX, topY), width: 30, height: 35));
    
    // Neck
    path.addRect(Rect.fromCenter(center: Offset(centerX, topY + 25), width: 15, height: 15));
    
    // Shoulders (adjusted for body type)
    final shoulderWidth = profile.shoulderWidth ?? 42;
    final shoulderScale = shoulderWidth / 42;
    final shoulderLeft = centerX - 25 * shoulderScale;
    final shoulderRight = centerX + 25 * shoulderScale;
    
    // Torso
    final hipWidth = profile.hipWidth ?? 36;
    final hipScale = hipWidth / 36;
    final hipLeft = centerX - 20 * hipScale;
    final hipRight = centerX + 20 * hipScale;
    
    path.moveTo(shoulderLeft, topY + 35);
    path.lineTo(shoulderRight, topY + 35);
    path.lineTo(hipRight, topY + 120);
    path.lineTo(hipLeft, topY + 120);
    path.close();
    
    // Legs
    path.addRect(Rect.fromCenter(center: Offset(centerX - 10, topY + 160), width: 15, height: 80));
    path.addRect(Rect.fromCenter(center: Offset(centerX + 10, topY + 160), width: 15, height: 80));
    
    // Arms
    path.addRect(Rect.fromCenter(center: Offset(shoulderLeft - 15, topY + 80), width: 12, height: 60));
    path.addRect(Rect.fromCenter(center: Offset(shoulderRight + 15, topY + 80), width: 12, height: 60));

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

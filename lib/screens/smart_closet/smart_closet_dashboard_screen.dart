import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/app_colors.dart';
import '../../design/responsive.dart';
import '../../widgets/fyt_card.dart';
import '../../routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../models/api_models.dart';

class SmartClosetDashboardScreen extends StatefulWidget {
  const SmartClosetDashboardScreen({super.key});

  @override
  State<SmartClosetDashboardScreen> createState() =>
      _SmartClosetDashboardScreenState();
}

class _SmartClosetDashboardScreenState
    extends State<SmartClosetDashboardScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().userId;
      context.read<WardrobeProvider>().loadWardrobe(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeProvider = context.watch<WardrobeProvider>();
    final items = wardrobeProvider.items;
    final loading = wardrobeProvider.loading;
    final filters = ['All', 'Top', 'Bottom', 'Outerwear', 'Dress'];

    List<WardrobeItem> filtered = items;
    if (_filter != 'All') {
      filtered = items.where((i) => i.category == _filter).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Closet')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${items.length} items in your wardrobe',
                  style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.md),
              // Filters
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filters
                      .map((f) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.xs),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: _filter == f,
                              selectedColor:
                                  AppColors.accentLavender.withOpacity(0.4),
                              onSelected: (_) =>
                                  setState(() => _filter = f),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Items grid
              if (loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checkroom_outlined,
                            size: 64, color: AppColors.textSub),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _filter == 'All'
                              ? 'Your closet is empty'
                              : 'No ${_filter.toLowerCase()} items',
                          style: AppTypography.subheading(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Tap + to add your clothes',
                            style: AppTypography.body(context)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          Responsive.sizeOf(context) == DeviceSize.tablet
                              ? 3
                              : 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _WardrobeCard(
                        item: item,
                        onDelete: () async {
                          final ok = await wardrobeProvider
                              .deleteItem(item.id);
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Item removed')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLavender,
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addWardrobeItem);
          // Refresh list when returning
          if (mounted) {
            final userId = context.read<UserProvider>().userId;
            context.read<WardrobeProvider>().loadWardrobe(userId);
          }
        },
        child:
            const Icon(Icons.add_rounded, color: AppColors.textPrimary),
      ),
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback onDelete;

  const _WardrobeCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FytCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.accentLavender.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.category == 'Top'
                  ? Icons.dry_cleaning_rounded
                  : item.category == 'Bottom'
                      ? Icons.straighten_rounded
                      : item.category == 'Outerwear'
                          ? Icons.layers_rounded
                          : Icons.checkroom_rounded,
              size: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.name ?? item.category,
              style: AppTypography.body(context)
                  .copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('${item.color} • ${item.formality}',
              style: AppTypography.label(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
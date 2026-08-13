import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/farmer_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'crop_detail_screen.dart';
import 'recommendation_detail_screen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({super.key});

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  int _currentTab = 0;
  String _query = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() => _currentTab = _tabController.index);
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FarmerProvider>();
      provider.loadFarms();
      provider.loadCrops();
      provider.loadRecommendations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentTab() async {
    final provider = context.read<FarmerProvider>();
    switch (_currentTab) {
      case 0:
        await provider.loadFarms(force: true);
        break;
      case 1:
        await provider.loadCrops(force: true);
        break;
      case 2:
        await provider.loadRecommendations(force: true);
        break;
    }
  }

  Future<void> _openFarmForm({Farm? farm}) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FarmFormSheet(initialFarm: farm),
    );

    if (!mounted || payload == null) return;

    final provider = context.read<FarmerProvider>();

    try {
      if (farm == null) {
        await provider.createFarm(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm record created successfully.')),
        );
      } else {
        await provider.updateFarm(farm.id, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm record updated successfully.')),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the farm record.')),
      );
    }
  }

  Future<void> _deleteFarm(Farm farm) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete farm record?'),
            content: Text(
              'This will remove ${farm.name} from the farmer account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    try {
      await context.read<FarmerProvider>().deleteFarm(farm.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm record deleted.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the farm record.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Farm Workspace',
        actions: [
          IconButton(
            onPressed: _refreshCurrentTab,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: null,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'My Farms'),
                Tab(text: 'Crop Library'),
                Tab(text: 'Recommendations'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FarmsTab(
                  onAddFarm: () => _openFarmForm(),
                  onEditFarm: (farm) => _openFarmForm(farm: farm),
                  onDeleteFarm: _deleteFarm,
                ),
                _CropLibraryTab(
                  query: _query,
                  selectedCategory: _selectedCategory,
                  searchController: _searchController,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onCategoryChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
                const _RecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmsTab extends StatelessWidget {
  final VoidCallback onAddFarm;
  final ValueChanged<Farm> onEditFarm;
  final ValueChanged<Farm> onDeleteFarm;

  const _FarmsTab({
    required this.onAddFarm,
    required this.onEditFarm,
    required this.onDeleteFarm,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.farmsLoading && provider.farms.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.farmsError != null && provider.farms.isEmpty) {
          return _AsyncMessageState(
            icon: Icons.cloud_off,
            title: 'Unable to load farm records',
            message: provider.farmsError!,
            actionLabel: 'Retry',
            onAction: () => provider.loadFarms(force: true),
          );
        }

        final farms = provider.farms;
        final totalAcres = farms.fold<double>(
          0,
          (sum, farm) => sum + farm.sizeAcres,
        );
        final soilTypes = farms.map((farm) => farm.soilType).toSet().length;

        return RefreshIndicator(
          onRefresh: () => provider.loadFarms(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Farm records',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                 const Text(
                                   'Each farm is assigned automatically to the advisor responsible for the matching EPA based on its location.',
                                   style: TextStyle(
                                     color: AppColors.textSecondary,
                                     height: 1.4,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: onAddFarm,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Farm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatPill(
                            label: '${farms.length} farm${farms.length == 1 ? '' : 's'}',
                            icon: Icons.agriculture,
                          ),
                          _StatPill(
                            label: '${_formatNumber(totalAcres)} acres tracked',
                            icon: Icons.square_foot,
                          ),
                          _StatPill(
                            label: '$soilTypes soil profile${soilTypes == 1 ? '' : 's'}',
                            icon: Icons.layers,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 260.ms),
              const SizedBox(height: 14),
              if (farms.isEmpty)
                _EmptyCardState(
                  icon: Icons.agriculture,
                   title: 'No farm records yet',
                   message:
                       'Add your first farm so the system can match it to the correct EPA advisor.',
                   actionLabel: 'Add Farm',
                   onAction: onAddFarm,
                 )
              else
                ...farms.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FarmCard(
                          farm: entry.value,
                          onEdit: () => onEditFarm(entry.value),
                          onDelete: () => onDeleteFarm(entry.value),
                        )
                            .animate(
                              delay: Duration(milliseconds: 70 * entry.key),
                            )
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: 0.04, end: 0),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _CropLibraryTab extends StatelessWidget {
  final String query;
  final String selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategoryChanged;

  const _CropLibraryTab({
    required this.query,
    required this.selectedCategory,
    required this.searchController,
    required this.onQueryChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.cropsLoading && provider.crops.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.cropsError != null && provider.crops.isEmpty) {
          return _AsyncMessageState(
            icon: Icons.cloud_off,
            title: 'Unable to load crop library',
            message: provider.cropsError!,
            actionLabel: 'Retry',
            onAction: () => provider.loadCrops(force: true),
          );
        }

        final categories = [
          'All',
          ...provider.crops
              .map((crop) => crop.category.trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
        ];

        final filtered = provider.crops.where((crop) {
          final matchesQuery =
              crop.name.toLowerCase().contains(query.toLowerCase()) ||
                  crop.category.toLowerCase().contains(query.toLowerCase()) ||
                  crop.description.toLowerCase().contains(query.toLowerCase());
          final matchesCategory = selectedCategory == 'All' ||
              crop.category == selectedCategory;
          return matchesQuery && matchesCategory;
        }).toList();

        return RefreshIndicator(
          onRefresh: () => provider.loadCrops(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search crops, categories, or descriptions',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    final selected = category == selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) => onCategoryChanged(category),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filtered.length} crop${filtered.length == 1 ? '' : 's'} available to farmers',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _EmptyCardState(
                  icon: Icons.eco_outlined,
                  title: 'No crops match this search',
                  message:
                      'Try a different search term or category filter to explore the published crop library.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (_, index) => _CropGridCard(crop: filtered[index])
                      .animate(
                        delay: Duration(milliseconds: 60 * index),
                      )
                      .fadeIn(duration: 260.ms)
                      .scale(
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1, 1),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.recsLoading && provider.recommendations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.recsError != null && provider.recommendations.isEmpty) {
          return _AsyncMessageState(
            icon: Icons.cloud_off,
            title: 'Unable to load recommendations',
            message: provider.recsError!,
            actionLabel: 'Retry',
            onAction: () => provider.loadRecommendations(force: true),
          );
        }

        final recommendations = provider.recommendations;
        if (recommendations.isEmpty) {
          return _EmptyCardState(
            icon: Icons.recommend_outlined,
            title: 'No recommendations yet',
            message:
                'Recommendations will appear here after an advisor submits farm conditions and the backend queue processes the AI job.',
            actionLabel: 'Refresh',
            onAction: () => provider.loadRecommendations(force: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRecommendations(force: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecommendationDetailScreen(rec: recommendation),
                  ),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _recommendationEmoji(recommendation.cropName),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recommendation.cropName.isEmpty
                                        ? 'Pending recommendation'
                                        : recommendation.cropName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${recommendation.advisorName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: recommendation.status,
                              color: _recommendationStatusColor(
                                recommendation.status,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recommendation.reason.isEmpty
                              ? 'The recommendation job is still waiting for the backend worker to finish.'
                              : recommendation.reason,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RecTag(
                              icon: Icons.layers,
                              label: recommendation.soilType,
                            ),
                            _RecTag(
                              icon: Icons.wb_sunny,
                              label: recommendation.season,
                            ),
                            _RecTag(
                              icon: Icons.water_drop,
                              label: recommendation.rainfall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(
                delay: Duration(milliseconds: 70 * index),
              ).fadeIn(duration: 260.ms);
            },
          ),
        );
      },
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FarmCard({
    required this.farm,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              farm.location,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _ReadOnlyChip(
                  label: farm.extensionPlanningAreaName.isEmpty
                      ? 'Assigning...'
                      : 'EPA Assigned',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (farm.extensionPlanningAreaName.isNotEmpty)
                  StatusBadge(
                    label: farm.extensionPlanningAreaName,
                    color: AppColors.success,
                  ),
                if (farm.advisorName.isNotEmpty)
                  StatusBadge(
                    label: farm.advisorName,
                    color: AppColors.warning,
                  ),
                StatusBadge(label: farm.soilType, color: AppColors.primary),
                StatusBadge(
                  label: '${_formatNumber(farm.sizeAcres)} acres',
                  color: AppColors.accent,
                ),
                StatusBadge(
                  label: 'pH ${_formatNumber(farm.soilPh)}',
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Nitrogen',
                    value: farm.nitrogen.isEmpty ? 'Not set' : farm.nitrogen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniMetric(
                    label: 'Phosphorus',
                    value: farm.phosphorus.isEmpty
                        ? 'Not set'
                        : farm.phosphorus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Potassium',
                    value: farm.potassium.isEmpty ? 'Not set' : farm.potassium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniMetric(
                    label: 'Rainfall / Temp',
                    value:
                        '${farm.rainfall.isEmpty ? 'Not set' : farm.rainfall} | ${farm.temperature.isEmpty ? 'Not set' : farm.temperature}',
                  ),
                ),
              ],
            ),
            if (farm.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  farm.notes,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _AssignmentHint(farm: farm),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  final String label;

  const _ReadOnlyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AssignmentHint extends StatelessWidget {
  final Farm farm;

  const _AssignmentHint({required this.farm});

  @override
  Widget build(BuildContext context) {
    final assignmentText = farm.extensionPlanningAreaName.isEmpty
        ? 'This farm is waiting for an EPA match. Update the location if the assignment does not appear.'
        : farm.advisorName.isEmpty
            ? 'This farm is matched to ${farm.extensionPlanningAreaName}.'
            : 'This farm is matched to ${farm.advisorName} through ${farm.extensionPlanningAreaName}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        assignmentText,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _CropGridCard extends StatelessWidget {
  final Crop crop;

  const _CropGridCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    crop.imageEmoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                crop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: crop.category, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                crop.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      crop.rainfall.isEmpty ? 'Seasonal' : crop.rainfall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.thermostat,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      crop.temperature.isEmpty ? crop.climate : crop.temperature,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmFormSheet extends StatefulWidget {
  final Farm? initialFarm;

  const _FarmFormSheet({this.initialFarm});

  @override
  State<_FarmFormSheet> createState() => _FarmFormSheetState();
}

class _FarmFormSheetState extends State<_FarmFormSheet> {
  static const _soilTypes = [
    'Loamy',
    'Sandy Loam',
    'Clay Loam',
    'Clay',
    'Silty',
    'Volcanic',
    'Mixed',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _sizeController;
  late final TextEditingController _soilPhController;
  late final TextEditingController _nitrogenController;
  late final TextEditingController _phosphorusController;
  late final TextEditingController _potassiumController;
  late final TextEditingController _rainfallController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _notesController;

  String _soilType = _soilTypes.first;

  @override
  void initState() {
    super.initState();
    final farm = widget.initialFarm;
    _soilType = farm?.soilType.isNotEmpty == true &&
            _soilTypes.contains(farm!.soilType)
        ? farm.soilType
        : _soilTypes.first;
    _nameController = TextEditingController(text: farm?.name ?? '');
    _locationController = TextEditingController(text: farm?.location ?? '');
    _latController =
        TextEditingController(text: _formatNumber(farm?.lat ?? 0));
    _lngController =
        TextEditingController(text: _formatNumber(farm?.lng ?? 0));
    _sizeController =
        TextEditingController(text: _formatNumber(farm?.sizeAcres ?? 0));
    _soilPhController =
        TextEditingController(text: _formatNumber(farm?.soilPh ?? 6.5));
    _nitrogenController =
        TextEditingController(text: farm?.nitrogen ?? '45 ppm');
    _phosphorusController =
        TextEditingController(text: farm?.phosphorus ?? '30 ppm');
    _potassiumController =
        TextEditingController(text: farm?.potassium ?? '180 ppm');
    _rainfallController =
        TextEditingController(text: farm?.rainfall ?? '800 mm');
    _temperatureController =
        TextEditingController(text: farm?.temperature ?? '27 C');
    _notesController = TextEditingController(text: farm?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _sizeController.dispose();
    _soilPhController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'name': _nameController.text.trim(),
      'location_text': _locationController.text.trim(),
      'lat': double.parse(_latController.text.trim()),
      'lng': double.parse(_lngController.text.trim()),
      'size_acres': double.parse(_sizeController.text.trim()),
      'soil_type': _soilType,
      'soil_ph': double.parse(_soilPhController.text.trim()),
      'nitrogen': _nitrogenController.text.trim(),
      'phosphorus': _phosphorusController.text.trim(),
      'potassium': _potassiumController.text.trim(),
      'rainfall': _rainfallController.text.trim(),
      'temperature': _temperatureController.text.trim(),
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.initialFarm == null
                      ? 'Add Farm Record'
                      : 'Edit Farm Record',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The farm location drives automatic EPA/advisor assignment. The stored field values are then used for recommendations.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _LabeledField(
                  label: 'Farm Name',
                  child: TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    validator: _requiredText,
                    decoration:
                        const InputDecoration(hintText: 'Main Farm Plot'),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Farm Location',
                  child: TextFormField(
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
                    validator: _requiredText,
                    decoration: const InputDecoration(
                      hintText: 'Village, district, or landmark used for EPA assignment',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Soil Type',
                  child: DropdownButtonFormField<String>(
                    value: _soilType,
                    items: _soilTypes
                        .map(
                          (soilType) => DropdownMenuItem<String>(
                            value: soilType,
                            child: Text(soilType),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _soilType = value);
                      }
                    },
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Coordinates',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: _requiredNumber,
                          decoration:
                              const InputDecoration(labelText: 'Latitude'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: _requiredNumber,
                          decoration:
                              const InputDecoration(labelText: 'Longitude'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Farm Size and Soil pH',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _requiredNumber,
                          decoration:
                              const InputDecoration(labelText: 'Size (acres)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _soilPhController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _requiredNumber,
                          decoration:
                              const InputDecoration(labelText: 'Soil pH'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Nutrient Profile',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nitrogenController,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Nitrogen',
                          hintText: '45 ppm',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phosphorusController,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Phosphorus',
                          hintText: '30 ppm',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _potassiumController,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Potassium',
                          hintText: '180 ppm',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Climate Conditions',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _rainfallController,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Rainfall',
                          hintText: '800 mm',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _temperatureController,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Temperature',
                          hintText: '27 C',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Notes',
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Drainage, previous crops, irrigation, or advisor observations',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('Save Farm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a number.';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number.';
    }
    return null;
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label.isEmpty ? 'Pending' : label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AsyncMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _AsyncMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCardState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _recommendationEmoji(String cropName) {
  final value = cropName.toLowerCase();
  if (value.contains('maize') || value.contains('corn')) return '🌽';
  if (value.contains('rice')) return '🌾';
  if (value.contains('tomato')) return '🍅';
  if (value.contains('cassava')) return '🥔';
  if (value.contains('groundnut')) return '🥜';
  return '🌱';
}

Color _recommendationStatusColor(String status) {
  switch (status) {
    case 'published':
      return AppColors.success;
    case 'generated':
      return AppColors.info;
    case 'pending':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

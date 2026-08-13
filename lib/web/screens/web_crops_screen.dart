import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebCropsScreen extends StatefulWidget {
  const WebCropsScreen({super.key});

  @override
  State<WebCropsScreen> createState() => _WebCropsScreenState();
}

class _WebCropsScreenState extends State<WebCropsScreen> {
  bool _loading = true;
  bool _editing = false;
  String? _error;
  String _query = '';

  List<Crop> _crops = const [];
  Crop? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final crops = await ApiService.advisorCrops();
      crops.sort((left, right) => left.name.compareTo(right.name));
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _selected = crops.isEmpty ? null : _selectedFor(crops, _selected?.id);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _crops = const [];
        _selected = null;
        _loading = false;
        _error = 'Unable to load crop records from the backend.';
      });
    }
  }

  Crop? _selectedFor(List<Crop> crops, String? cropId) {
    if (cropId == null) return crops.isNotEmpty ? crops.first : null;
    for (final crop in crops) {
      if (crop.id == cropId) return crop;
    }
    return crops.isNotEmpty ? crops.first : null;
  }

  Future<void> _saveCrop(Map<String, dynamic> payload) async {
    final creating = _selected == null;
    try {
      final crop = creating
          ? await ApiService.createAdvisorCrop(payload)
          : await ApiService.updateAdvisorCrop(_selected!.id, payload);

      final next = [
        crop,
        ..._crops.where((item) => item.id != crop.id),
      ]..sort((left, right) => left.name.compareTo(right.name));

      if (!mounted) return;
      setState(() {
        _crops = next;
        _selected = crop;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creating
                ? 'Crop created successfully.'
                : 'Crop updated successfully.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the crop record.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final crop = _selected;
    if (crop == null) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete crop?'),
            content: Text(
              'This will remove ${crop.name} from the advisor catalog.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await ApiService.deleteAdvisorCrop(crop.id);
      final next = _crops.where((item) => item.id != crop.id).toList();
      if (!mounted) return;
      setState(() {
        _crops = next;
        _selected = next.isNotEmpty ? next.first : null;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop deleted successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the crop record.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _crops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 40,
                color: WebColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: WebColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              WebButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _crops.where((crop) {
      final query = _query.toLowerCase();
      return crop.name.toLowerCase().contains(query) ||
          crop.category.toLowerCase().contains(query) ||
          crop.description.toLowerCase().contains(query);
    }).toList();

    final detail = _editing
        ? _CropEditorCard(
            crop: _selected,
            onCancel: () => setState(() => _editing = false),
            onSubmit: _saveCrop,
          )
        : _selected != null
            ? _CropDetailCard(
                crop: _selected!,
                onEdit: () => setState(() => _editing = true),
                onDelete: _deleteSelected,
              )
            : const _WebPlaceholderCard(
                title: 'No crop selected',
                message:
                    'Create a crop profile so advisors can build a published catalog for farmers.',
                icon: Icons.eco_outlined,
              );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Crops',
            subtitle:
                'Manage the published crop catalog used by the farmer app and recommendation engine.',
            action: Row(
              children: [
                WebButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
                const SizedBox(width: 10),
                WebButton(
                  label: 'New Crop',
                  icon: Icons.add,
                  onPressed: () => setState(() {
                    _selected = null;
                    _editing = true;
                  }),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth > 980;
              final list = _CropListCard(
                crops: filtered,
                selected: _selected,
                onQueryChanged: (value) => setState(() => _query = value),
                onSelect: (crop) => setState(() {
                  _selected = crop;
                  _editing = false;
                }),
              );

              if (!isWide) {
                return Column(
                  children: [
                    list,
                    const SizedBox(height: 20),
                    detail,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: list),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: detail),
                ],
              );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 280.ms),
        ],
      ),
    );
  }
}

class _CropListCard extends StatelessWidget {
  final List<Crop> crops;
  final Crop? selected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Crop> onSelect;

  const _CropListCard({
    required this.crops,
    required this.selected,
    required this.onQueryChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: 'Crop Catalog',
      titleAction: WebBadge(
        label: '${crops.length} entries',
        color: WebColors.primary,
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: WebSearchBar(
              hint: 'Search crops or categories',
              onChanged: onQueryChanged,
            ),
          ),
          if (crops.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: const _WebPlaceholderCard(
                title: 'No crops found',
                message:
                    'Create a crop entry or adjust the search term to see the advisor catalog.',
                icon: Icons.search_off,
                compact: true,
              ),
            )
          else
            ...crops.map((crop) {
              final isSelected = crop.id == selected?.id;
              return GestureDetector(
                onTap: () => onSelect(crop),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WebColors.primary.withValues(alpha: 0.05)
                        : Colors.white,
                    border: Border(
                      bottom: const BorderSide(color: WebColors.divider),
                      left: isSelected
                          ? const BorderSide(color: WebColors.primary, width: 3)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: WebColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            crop.imageEmoji,
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
                              crop.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              crop.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: WebColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              crop.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: WebColors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      WebBadge(
                        label: crop.status,
                        color: _cropStatusColor(crop.status),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CropDetailCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CropDetailCard({
    required this.crop,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: crop.name,
      titleAction: Row(
        children: [
          WebButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            outlined: true,
            onPressed: onEdit,
          ),
          const SizedBox(width: 10),
          WebButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: WebColors.danger,
            onPressed: onDelete,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              WebBadge(label: crop.category, color: WebColors.primary),
              if (crop.season.isNotEmpty)
                WebBadge(label: crop.season, color: WebColors.info),
              WebBadge(label: crop.status, color: _cropStatusColor(crop.status)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            crop.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.55,
              color: WebColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Soil Requirements',
                  value: crop.soilType.isEmpty ? 'Not set' : crop.soilType,
                  icon: Icons.layers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Climate Requirements',
                  value: crop.climate.isEmpty ? 'Not set' : crop.climate,
                  icon: Icons.wb_sunny,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TextSection(
            title: 'Planting Steps',
            items: crop.plantingSteps,
          ),
          const SizedBox(height: 16),
          _TextSection(
            title: 'Maintenance Tips',
            items: crop.maintenanceTips,
          ),
        ],
      ),
    );
  }
}

class _CropEditorCard extends StatefulWidget {
  final Crop? crop;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const _CropEditorCard({
    required this.crop,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_CropEditorCard> createState() => _CropEditorCardState();
}

class _CropEditorCardState extends State<_CropEditorCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _soilController;
  late final TextEditingController _climateController;
  late final TextEditingController _stepsController;
  late final TextEditingController _tipsController;
  late final TextEditingController _seasonController;
  String _status = 'published';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final crop = widget.crop;
    _nameController = TextEditingController(text: crop?.name ?? '');
    _categoryController = TextEditingController(text: crop?.category ?? '');
    _descriptionController =
        TextEditingController(text: crop?.description ?? '');
    _soilController = TextEditingController(text: crop?.soilType ?? '');
    _climateController = TextEditingController(text: crop?.climate ?? '');
    _stepsController =
        TextEditingController(text: crop?.plantingSteps.join('\n') ?? '');
    _tipsController =
        TextEditingController(text: crop?.maintenanceTips.join('\n') ?? '');
    _seasonController = TextEditingController(text: crop?.season ?? '');
    _status = crop?.status ?? 'published';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _soilController.dispose();
    _climateController.dispose();
    _stepsController.dispose();
    _tipsController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await widget.onSubmit({
      'name': _nameController.text.trim(),
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
      'soil_requirements': _soilController.text.trim(),
      'climate_requirements': _climateController.text.trim(),
      'planting_steps': _stepsController.text.trim(),
      'maintenance_tips': _tipsController.text.trim(),
      'season': _seasonController.text.trim(),
      'status': _status,
    });
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: widget.crop == null ? 'New Crop' : 'Edit Crop',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _WebField(
                    label: 'Crop Name',
                    child: TextFormField(
                      controller: _nameController,
                      validator: _required,
                      decoration: const InputDecoration(hintText: 'Maize'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WebField(
                    label: 'Category',
                    child: TextFormField(
                      controller: _categoryController,
                      validator: _required,
                      decoration:
                          const InputDecoration(hintText: 'Cereals'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _WebField(
              label: 'Description',
              child: TextFormField(
                controller: _descriptionController,
                validator: _required,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe where and why this crop performs well.',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WebField(
                    label: 'Soil Requirements',
                    child: TextFormField(
                      controller: _soilController,
                      validator: _required,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Loamy soils with good drainage',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WebField(
                    label: 'Climate Requirements',
                    child: TextFormField(
                      controller: _climateController,
                      validator: _required,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Warm temperatures with moderate rainfall',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WebField(
                    label: 'Season Label',
                    child: TextFormField(
                      controller: _seasonController,
                      decoration: const InputDecoration(
                        hintText: 'Major rainy season',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WebField(
                    label: 'Status',
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Draft'),
                        ),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                        DropdownMenuItem(
                          value: 'archived',
                          child: Text('Archived'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                      decoration: const InputDecoration(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _WebField(
              label: 'Planting Steps',
              child: TextFormField(
                controller: _stepsController,
                validator: _required,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Use one step per line.',
                ),
              ),
            ),
            const SizedBox(height: 14),
            _WebField(
              label: 'Maintenance Tips',
              child: TextFormField(
                controller: _tipsController,
                validator: _required,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Use one tip per line.',
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WebButton(
                  label: 'Cancel',
                  outlined: true,
                  onPressed: widget.onCancel,
                ),
                const SizedBox(width: 10),
                WebButton(
                  label: _submitting ? 'Saving...' : 'Save Crop',
                  icon: Icons.save_outlined,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }
}

class _WebField extends StatelessWidget {
  final String label;
  final Widget child;

  const _WebField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WebColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _TextSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            'No content provided yet.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: WebColors.textMuted,
            ),
          )
        else
          ...items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: WebColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: WebColors.textSecondary,
                            height: 1.45,
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
}

class _WebPlaceholderCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool compact;

  const _WebPlaceholderCard({
    required this.title,
    required this.message,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 48),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 52 : 68,
            height: compact ? 52 : 68,
            decoration: BoxDecoration(
              color: WebColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: WebColors.primary, size: compact ? 26 : 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w600,
              color: WebColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: WebColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Color _cropStatusColor(String status) {
  switch (status) {
    case 'published':
      return WebColors.primary;
    case 'draft':
      return WebColors.warning;
    case 'archived':
      return WebColors.textMuted;
    default:
      return WebColors.info;
  }
}

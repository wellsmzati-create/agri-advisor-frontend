import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebTipsScreen extends StatefulWidget {
  const WebTipsScreen({super.key});

  @override
  State<WebTipsScreen> createState() => _WebTipsScreenState();
}

class _WebTipsScreenState extends State<WebTipsScreen> {
  bool _loading = true;
  bool _editing = false;
  String? _error;
  String _query = '';

  List<FarmingTip> _tips = const [];
  FarmingTip? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tips = await ApiService.advisorTips();
      tips.sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
      if (!mounted) return;
      setState(() {
        _tips = tips;
        _selected = _selectedFor(tips, _selected?.id);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tips = const [];
        _selected = null;
        _loading = false;
        _error = 'Unable to load farming tips from the backend.';
      });
    }
  }

  FarmingTip? _selectedFor(List<FarmingTip> tips, String? tipId) {
    if (tipId == null) return tips.isNotEmpty ? tips.first : null;
    for (final tip in tips) {
      if (tip.id == tipId) return tip;
    }
    return tips.isNotEmpty ? tips.first : null;
  }

  Future<void> _saveTip(Map<String, dynamic> payload) async {
    final creating = _selected == null;
    try {
      final tip = creating
          ? await ApiService.createAdvisorTip(payload)
          : await ApiService.updateAdvisorTip(_selected!.id, payload);

      final next = [
        tip,
        ..._tips.where((item) => item.id != tip.id),
      ]..sort((left, right) => right.publishedAt.compareTo(left.publishedAt));

      if (!mounted) return;
      setState(() {
        _tips = next;
        _selected = tip;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creating
                ? 'Farming tip published successfully.'
                : 'Farming tip updated successfully.',
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
        const SnackBar(content: Text('Unable to save the farming tip.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final tip = _selected;
    if (tip == null) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete farming tip?'),
            content: Text('This will remove "${tip.title}" from the system.'),
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
      await ApiService.deleteAdvisorTip(tip.id);
      final next = _tips.where((item) => item.id != tip.id).toList();
      if (!mounted) return;
      setState(() {
        _tips = next;
        _selected = next.isNotEmpty ? next.first : null;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farming tip deleted successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the farming tip.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tips.isEmpty) {
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

    final filtered = _tips.where((tip) {
      final query = _query.toLowerCase();
      return tip.title.toLowerCase().contains(query) ||
          tip.category.toLowerCase().contains(query) ||
          tip.content.toLowerCase().contains(query);
    }).toList();

    final detail = _editing
        ? _TipEditorCard(
            tip: _selected,
            onCancel: () => setState(() => _editing = false),
            onSubmit: _saveTip,
          )
        : _selected != null
            ? _TipDetailCard(
                tip: _selected!,
                onEdit: () => setState(() => _editing = true),
                onDelete: _deleteSelected,
              )
            : const _TipPlaceholderCard(
                title: 'No tip selected',
                message:
                    'Create farming tips so the farmer app has live advisory content to display.',
                icon: Icons.lightbulb_outline,
              );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Farming Tips',
            subtitle:
                'Publish advisory content that farmers can read from the mobile app.',
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
                  label: 'New Tip',
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
              final list = _TipListCard(
                tips: filtered,
                selected: _selected,
                onQueryChanged: (value) => setState(() => _query = value),
                onSelect: (tip) => setState(() {
                  _selected = tip;
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

class _TipListCard extends StatelessWidget {
  final List<FarmingTip> tips;
  final FarmingTip? selected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FarmingTip> onSelect;

  const _TipListCard({
    required this.tips,
    required this.selected,
    required this.onQueryChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: 'Published Tips',
      titleAction: WebBadge(
        label: '${tips.length} items',
        color: WebColors.primary,
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: WebSearchBar(
              hint: 'Search tips, categories, or text',
              onChanged: onQueryChanged,
            ),
          ),
          if (tips.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: _TipPlaceholderCard(
                title: 'No farming tips found',
                message:
                    'Create a tip or change the search term to see advisory content.',
                icon: Icons.search_off,
                compact: true,
              ),
            )
          else
            ...tips.map((tip) {
              final isSelected = tip.id == selected?.id;
              return GestureDetector(
                onTap: () => onSelect(tip),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: WebColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: WebColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tip.category} • ${tip.season}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: WebColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tip.content,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          WebBadge(
                            label: tip.status,
                            color: _tipStatusColor(tip.status),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('MMM d').format(tip.publishedAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: WebColors.textMuted,
                            ),
                          ),
                        ],
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

class _TipDetailCard extends StatelessWidget {
  final FarmingTip tip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TipDetailCard({
    required this.tip,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: tip.title,
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
              WebBadge(label: tip.category, color: WebColors.primary),
              WebBadge(label: tip.season, color: WebColors.info),
              WebBadge(
                label: tip.status,
                color: _tipStatusColor(tip.status),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Author',
                  value: tip.authorName,
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Published',
                  value: DateFormat('MMM d, yyyy').format(tip.publishedAt),
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            tip.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.65,
              color: WebColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipEditorCard extends StatefulWidget {
  final FarmingTip? tip;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const _TipEditorCard({
    required this.tip,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_TipEditorCard> createState() => _TipEditorCardState();
}

class _TipEditorCardState extends State<_TipEditorCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _seasonController;
  late final TextEditingController _contentController;
  String _status = 'published';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final tip = widget.tip;
    _titleController = TextEditingController(text: tip?.title ?? '');
    _categoryController = TextEditingController(text: tip?.category ?? '');
    _seasonController = TextEditingController(text: tip?.season ?? '');
    _contentController = TextEditingController(text: tip?.content ?? '');
    _status = tip?.status ?? 'published';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _seasonController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await widget.onSubmit({
      'title': _titleController.text.trim(),
      'category': _categoryController.text.trim(),
      'season': _seasonController.text.trim(),
      'content': _contentController.text.trim(),
      'status': _status,
    });
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: widget.tip == null ? 'New Farming Tip' : 'Edit Farming Tip',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipField(
              label: 'Title',
              child: TextFormField(
                controller: _titleController,
                validator: _required,
                decoration: const InputDecoration(
                  hintText: 'How to prepare soils before planting',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TipField(
                    label: 'Category',
                    child: TextFormField(
                      controller: _categoryController,
                      validator: _required,
                      decoration: const InputDecoration(
                        hintText: 'Soil Health',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TipField(
                    label: 'Season',
                    child: TextFormField(
                      controller: _seasonController,
                      validator: _required,
                      decoration: const InputDecoration(
                        hintText: 'Major rainy season',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TipField(
              label: 'Status',
              child: DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
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
            const SizedBox(height: 14),
            _TipField(
              label: 'Content',
              child: TextFormField(
                controller: _contentController,
                validator: _required,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Write the full farming tip here.',
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
                  label: _submitting ? 'Saving...' : 'Save Tip',
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

class _TipField extends StatelessWidget {
  final String label;
  final Widget child;

  const _TipField({
    required this.label,
    required this.child,
  });

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

class _TipPlaceholderCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool compact;

  const _TipPlaceholderCard({
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
              color: WebColors.warning.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: WebColors.warning, size: compact ? 26 : 32),
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

Color _tipStatusColor(String status) {
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

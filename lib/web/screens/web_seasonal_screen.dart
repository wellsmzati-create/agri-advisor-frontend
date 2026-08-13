import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebSeasonalScreen extends StatefulWidget {
  const WebSeasonalScreen({super.key});

  @override
  State<WebSeasonalScreen> createState() => _WebSeasonalScreenState();
}

class _WebSeasonalScreenState extends State<WebSeasonalScreen> {
  bool _loading = true;
  bool _editing = false;
  String _query = '';
  String? _error;

  List<SeasonalNoticeItem> _notices = const [];
  SeasonalNoticeItem? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notices = await ApiService.advisorSeasonalNotices();
      notices.sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
      if (!mounted) return;
      setState(() {
        _notices = notices;
        _selected = _selectedFor(notices, _selected?.id);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notices = const [];
        _selected = null;
        _loading = false;
        _error = 'Unable to load seasonal notices from the backend.';
      });
    }
  }

  SeasonalNoticeItem? _selectedFor(List<SeasonalNoticeItem> notices, String? id) {
    if (id == null) return notices.isNotEmpty ? notices.first : null;
    for (final notice in notices) {
      if (notice.id == id) return notice;
    }
    return notices.isNotEmpty ? notices.first : null;
  }

  Future<void> _saveNotice(Map<String, dynamic> payload) async {
    final creating = _selected == null;
    try {
      final notice = creating
          ? await ApiService.createAdvisorSeasonalNotice(payload)
          : await ApiService.updateAdvisorSeasonalNotice(_selected!.id, payload);
      final next = [
        notice,
        ..._notices.where((item) => item.id != notice.id),
      ]..sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
      if (!mounted) return;
      setState(() {
        _notices = next;
        _selected = notice;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creating
                ? 'Seasonal notice saved successfully.'
                : 'Seasonal notice updated successfully.',
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
        const SnackBar(content: Text('Unable to save the seasonal notice.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final notice = _selected;
    if (notice == null) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete seasonal notice?'),
            content: Text('This will remove "${notice.title}" from the system.'),
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
      await ApiService.deleteAdvisorSeasonalNotice(notice.id);
      final next = _notices.where((item) => item.id != notice.id).toList();
      if (!mounted) return;
      setState(() {
        _notices = next;
        _selected = next.isNotEmpty ? next.first : null;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seasonal notice deleted successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the seasonal notice.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _notices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: WebColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary),
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

    final filtered = _notices.where((notice) {
      final query = _query.toLowerCase();
      return notice.title.toLowerCase().contains(query) ||
          notice.category.toLowerCase().contains(query) ||
          notice.season.toLowerCase().contains(query) ||
          notice.summary.toLowerCase().contains(query);
    }).toList();

    final detail = _editing
        ? _SeasonalEditorCard(
            notice: _selected,
            onCancel: () => setState(() => _editing = false),
            onSubmit: _saveNotice,
          )
        : _selected != null
            ? _SeasonalDetailCard(
                notice: _selected!,
                onEdit: () => setState(() => _editing = true),
                onDelete: _deleteSelected,
              )
            : const _SeasonalPlaceholderCard(
                title: 'No notice selected',
                message:
                    'Create seasonal notices so farmers see live advisories on mobile.',
                icon: Icons.campaign_outlined,
              );

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Seasonal Notices',
            subtitle: 'Publish seasonal advisories and alerts for farmer mobile users',
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
                  label: 'New Notice',
                  icon: Icons.add,
                  onPressed: () => setState(() {
                    _selected = null;
                    _editing = true;
                  }),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth > 1020;
                final list = _SeasonalListCard(
                  notices: filtered,
                  selected: _selected,
                  query: _query,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onSelect: (notice) => setState(() {
                    _selected = notice;
                    _editing = false;
                  }),
                );
                return isWide
                    ? Row(
                        children: [
                          SizedBox(width: 360, child: list),
                          const SizedBox(width: 20),
                          Expanded(child: detail),
                        ],
                      )
                    : ListView(
                        children: [
                          list,
                          const SizedBox(height: 20),
                          detail,
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalListCard extends StatelessWidget {
  final List<SeasonalNoticeItem> notices;
  final SeasonalNoticeItem? selected;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SeasonalNoticeItem> onSelect;

  const _SeasonalListCard({
    required this.notices,
    required this.selected,
    required this.query,
    required this.onQueryChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: WebSearchBar(
              hint: 'Search notices...',
              onChanged: onQueryChanged,
            ),
          ),
          const Divider(height: 1, color: WebColors.divider),
          if (notices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'No seasonal notices match the current search.',
                style: GoogleFonts.inter(color: WebColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...notices.map((notice) {
              final isSelected = selected?.id == notice.id;
              return InkWell(
                onTap: () => onSelect(notice),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: WebColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          WebBadge(
                            label: _labelizeStatus(notice.status),
                            color: _statusColor(notice.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          WebBadge(label: notice.category, color: _categoryColor(notice.category)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(notice.publishedAt),
                            style: GoogleFonts.inter(fontSize: 11, color: WebColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: WebColors.textSecondary,
                          height: 1.4,
                        ),
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

class _SeasonalDetailCard extends StatelessWidget {
  final SeasonalNoticeItem notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SeasonalDetailCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notice.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: WebColors.textPrimary,
                  ),
                ),
              ),
              WebBadge(
                label: _labelizeStatus(notice.status),
                color: _statusColor(notice.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WebBadge(label: notice.category, color: _categoryColor(notice.category)),
              WebBadge(label: notice.season, color: WebColors.info),
              WebBadge(label: notice.targetRegion, color: WebColors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Published ${DateFormat('EEEE, MMM d, yyyy').format(notice.publishedAt)} by ${notice.authorName}',
            style: GoogleFonts.inter(fontSize: 12, color: WebColors.textSecondary),
          ),
          const Divider(height: 24, color: WebColors.divider),
          Text(
            notice.summary,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: WebColors.textPrimary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              WebButton(label: 'Edit Notice', icon: Icons.edit, onPressed: onEdit),
              const SizedBox(width: 10),
              WebButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                outlined: true,
                color: WebColors.danger,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonalEditorCard extends StatefulWidget {
  final SeasonalNoticeItem? notice;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const _SeasonalEditorCard({
    required this.notice,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_SeasonalEditorCard> createState() => _SeasonalEditorCardState();
}

class _SeasonalEditorCardState extends State<_SeasonalEditorCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _regionController;
  String _category = 'Seasonal Advisory';
  String _season = 'Major Rainy Season';
  String _status = 'published';

  @override
  void initState() {
    super.initState();
    final notice = widget.notice;
    _titleController = TextEditingController(text: notice?.title ?? '');
    _summaryController = TextEditingController(text: notice?.summary ?? '');
    _regionController = TextEditingController(text: notice?.targetRegion ?? 'All Regions');
    _category = notice?.category ?? 'Seasonal Advisory';
    _season = notice?.season.isNotEmpty == true ? notice!.season : 'Major Rainy Season';
    _status = notice?.status ?? 'published';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'title': _titleController.text.trim(),
      'category': _category,
      'season': _season,
      'summary': _summaryController.text.trim(),
      'target_region': _regionController.text.trim(),
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: widget.notice == null ? 'Create Seasonal Notice' : 'Edit Seasonal Notice',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeasonalField(
              label: 'Title',
              child: TextFormField(
                controller: _titleController,
                validator: _required,
                decoration: const InputDecoration(
                  hintText: 'e.g. Rainfall preparation advisory',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SeasonalDropdown(
                    label: 'Category',
                    value: _category,
                    items: const [
                      'Seasonal Advisory',
                      'Pest Alert',
                      'Government Notice',
                      'Research Update',
                      'Weather Alert',
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SeasonalDropdown(
                    label: 'Season',
                    value: _season,
                    items: const [
                      'Major Rainy Season',
                      'Minor Season',
                      'Dry Season',
                      'Harvest Season',
                      'Year-round',
                    ],
                    onChanged: (value) => setState(() => _season = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SeasonalField(
              label: 'Summary',
              child: TextFormField(
                controller: _summaryController,
                validator: _required,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Write the advisory or notice content here...',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SeasonalField(
                    label: 'Target Region',
                    child: TextFormField(
                      controller: _regionController,
                      validator: _required,
                      decoration: const InputDecoration(hintText: 'All Regions'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SeasonalDropdown(
                    label: 'Status',
                    value: _status,
                    items: const ['draft', 'published', 'archived'],
                    onChanged: (value) => setState(() => _status = value),
                    itemLabel: _labelizeStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  label: 'Save Notice',
                  icon: Icons.save_outlined,
                  onPressed: _submit,
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

class _SeasonalField extends StatelessWidget {
  final String label;
  final Widget child;

  const _SeasonalField({
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

class _SeasonalDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String Function(String value) itemLabel;

  const _SeasonalDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel = _identity,
  });

  @override
  Widget build(BuildContext context) {
    return _SeasonalField(
      label: label,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(itemLabel(item), style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
        decoration: const InputDecoration(),
      ),
    );
  }
}

class _SeasonalPlaceholderCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _SeasonalPlaceholderCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: WebColors.primary),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: WebColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'published':
      return WebColors.primary;
    case 'archived':
      return WebColors.textSecondary;
    default:
      return WebColors.warning;
  }
}

Color _categoryColor(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('pest')) return WebColors.danger;
  if (normalized.contains('weather')) return WebColors.info;
  if (normalized.contains('government')) return WebColors.purple;
  return WebColors.primary;
}

String _labelizeStatus(String value) {
  if (value.isEmpty) return 'Draft';
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _identity(String value) => value;

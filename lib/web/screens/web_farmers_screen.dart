import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_mock_data.dart';
import 'web_messages_screen.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebFarmersScreen extends StatefulWidget {
  const WebFarmersScreen({super.key});

  @override
  State<WebFarmersScreen> createState() => _WebFarmersScreenState();
}

class _WebFarmersScreenState extends State<WebFarmersScreen> {
  String _search = '';
  String _statusFilter = 'All';
  WebFarmer? _selected;
  List<WebFarmer> _farmers = const [];
  bool _loading = true;
  bool _mutating = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers({String? selectFarmerId}) async {
    try {
      final farmers = await ApiService.advisorFarmers();
      if (!mounted) return;

      final mappedFarmers = farmers.map(WebFarmer.fromJson).toList();
      final selectedId = selectFarmerId ?? _selected?.id;

      setState(() {
        _farmers = mappedFarmers;
        _selected = selectedId == null
            ? null
            : _findFarmerById(mappedFarmers, selectedId);
        _loadError = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _farmers = const [];
        _selected = null;
        _loadError = 'Unable to load farmers from the backend API.';
        _loading = false;
      });
    }
  }

  Future<void> _refreshSelectedFarmer() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _loading = true);
      await _loadFarmers();
      return;
    }

    try {
      final raw = await ApiService.advisorFarmer(selected.id);
      if (!mounted) return;

      final refreshed = WebFarmer.fromJson(raw);
      setState(() {
        _farmers = _farmers
            .map((farmer) => farmer.id == refreshed.id ? refreshed : farmer)
            .toList();
        _selected = refreshed;
        _loadError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to refresh this farmer profile.', error: true);
    }
  }

  Future<void> _openConversation(WebFarmer farmer) async {
    try {
      final conversation = await ApiService.ensureAdvisorConversation(farmer.id);
      if (!mounted) return;
      await showAdvisorConversationDialog(
        context,
        conversationId: conversation.id,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Unable to open the farmer conversation.',
        error: true,
      );
    }
  }

  Future<void> _saveFarm(
    WebFarmer farmer, {
    Map<String, dynamic>? existingFarm,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FarmEditorDialog(
        farmerName: farmer.name,
        farm: existingFarm,
      ),
    );
    if (payload == null) return;

    await _runMutation(() async {
      if (existingFarm == null) {
        await ApiService.createAdvisorFarm(farmer.id, payload);
      } else {
        await ApiService.updateAdvisorFarm(_text(existingFarm['id']), payload);
      }
      await _loadFarmers(selectFarmerId: farmer.id);
    }, successMessage: existingFarm == null ? 'Farm created.' : 'Farm updated.');
  }

  Future<void> _saveFarmRecord(
    WebFarmer farmer,
    Map<String, dynamic> farm, {
    Map<String, dynamic>? record,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FieldRecordDialog(
        farmName: _text(farm['name'], fallback: 'Farm'),
        farmSnapshot: farm,
        record: record,
      ),
    );
    if (payload == null) return;

    await _runMutation(() async {
      if (record == null) {
        await ApiService.createAdvisorFarmRecord(_text(farm['id']), payload);
      } else {
        await ApiService.updateAdvisorFarmRecord(_text(record['id']), payload);
      }
      await _loadFarmers(selectFarmerId: farmer.id);
    }, successMessage: record == null ? 'Field reading saved.' : 'Field reading updated.');
  }

  Future<void> _deleteFarm(WebFarmer farmer, Map<String, dynamic> farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete farm'),
        content: Text(
          'Delete ${_text(farm['name'], fallback: 'this farm')} for ${farmer.name}? '
          'The farmer mobile app will lose this farm snapshot on the next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runMutation(() async {
      await ApiService.deleteAdvisorFarm(_text(farm['id']));
      await _loadFarmers(selectFarmerId: farmer.id);
    }, successMessage: 'Farm deleted.');
  }

  Future<void> _runMutation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _mutating = true);
    try {
      await action();
      if (!mounted) return;
      _showSnackBar(successMessage);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('The backend request could not be completed.', error: true);
    } finally {
      if (mounted) {
        setState(() => _mutating = false);
      }
    }
  }

  void _showSnackBar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? WebColors.danger : WebColors.primary,
        content: Text(message),
      ),
    );
  }

  WebFarmer? _findFarmerById(List<WebFarmer> farmers, String id) {
    for (final farmer in farmers) {
      if (farmer.id == id) return farmer;
    }
    return null;
  }

  List<WebFarmer> get _filtered => _farmers.where((farmer) {
    final query = _search.toLowerCase();
    final matchSearch =
        farmer.name.toLowerCase().contains(query) ||
        farmer.location.toLowerCase().contains(query) ||
        farmer.email.toLowerCase().contains(query);
    final matchStatus =
        _statusFilter == 'All' || farmer.status == _statusFilter;
    return matchSearch && matchStatus;
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading && _farmers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          flex: _selected != null ? 3 : 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebPageHeader(
                  title: 'Farmers',
                  subtitle:
                      '${_farmers.length} farmers currently available from the backend',
                  action: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_mutating)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Saving...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: WebColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      WebButton(
                        label: 'Refresh',
                        icon: Icons.refresh,
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadFarmers();
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                if (_loadError != null) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    message: _loadError!,
                    actionLabel: 'Retry',
                    onPressed: () {
                      setState(() => _loading = true);
                      _loadFarmers();
                    },
                  ),
                ],
                const SizedBox(height: 20),
                _FilterBar(
                  search: _search,
                  statusFilter: _statusFilter,
                  onSearch: (value) => setState(() {
                    _search = value;
                    if (_selected != null &&
                        !_filtered.any((farmer) => farmer.id == _selected!.id)) {
                      _selected = null;
                    }
                  }),
                  onFilter: (value) => setState(() {
                    _statusFilter = value;
                    if (_selected != null &&
                        !_filtered.any((farmer) => farmer.id == _selected!.id)) {
                      _selected = null;
                    }
                  }),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 16),
                _FarmerTable(
                  farmers: _filtered,
                  selected: _selected,
                  onSelect: (farmer) => setState(() {
                    _selected = _selected?.id == farmer.id ? null : farmer;
                  }),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
        if (_selected != null) ...[
          const VerticalDivider(width: 1, color: WebColors.divider),
          SizedBox(
            width: 420,
            child: _FarmerDetailPanel(
              farmer: _selected!,
              busy: _mutating,
              onClose: () => setState(() => _selected = null),
              onRefreshFarmer: _refreshSelectedFarmer,
              onMessageFarmer: () => _openConversation(_selected!),
              onCreateFarm: () => _saveFarm(_selected!),
              onEditFarm: (farm) => _saveFarm(_selected!, existingFarm: farm),
              onDeleteFarm: (farm) => _deleteFarm(_selected!, farm),
              onAddFarmRecord: (farm) => _saveFarmRecord(_selected!, farm),
              onEditFarmRecord: (farm, record) =>
                  _saveFarmRecord(_selected!, farm, record: record),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
          ),
        ],
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String search;
  final String statusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;

  const _FilterBar({
    required this.search,
    required this.statusFilter,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 920;

        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'All',
              selected: statusFilter == 'All',
              onTap: () => onFilter('All'),
            ),
            _FilterChip(
              label: 'Active',
              selected: statusFilter == 'Active',
              color: WebColors.primary,
              onTap: () => onFilter('Active'),
            ),
            _FilterChip(
              label: 'Inactive',
              selected: statusFilter == 'Inactive',
              color: WebColors.textSecondary,
              onTap: () => onFilter('Inactive'),
            ),
            _FilterChip(
              label: 'Pending',
              selected: statusFilter == 'Pending',
              color: WebColors.warning,
              onTap: () => onFilter('Pending'),
            ),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebSearchBar(
                hint: 'Search by name, email, or location...',
                onChanged: onSearch,
              ),
              const SizedBox(height: 12),
              chips,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: WebSearchBar(
                hint: 'Search by name, email, or location...',
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 12),
            chips,
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? WebColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.1)
              : WebColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? chipColor : WebColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? chipColor : WebColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FarmerTable extends StatelessWidget {
  final List<WebFarmer> farmers;
  final WebFarmer? selected;
  final ValueChanged<WebFarmer> onSelect;

  const _FarmerTable({
    required this.farmers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: WebColors.divider)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                'FARMER',
                'LOCATION',
                'FARM SIZE',
                'SOIL TYPE',
                'RECS',
                'LAST ACTIVE',
                'STATUS',
                '',
              ]
                  .map(
                    (heading) => Expanded(
                      child: Text(
                        heading,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WebColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (farmers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No farmers match the current filters.',
                  style: GoogleFonts.inter(color: WebColors.textMuted),
                ),
              ),
            )
          else
            ...farmers.asMap().entries.map((entry) {
              final farmer = entry.value;
              final isSelected = selected?.id == farmer.id;

              return GestureDetector(
                onTap: () => onSelect(farmer),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WebColors.primary.withValues(alpha: 0.05)
                        : (entry.key.isEven
                            ? Colors.white
                            : const Color(0xFFFAFBFC)),
                    border: Border(
                      bottom: const BorderSide(color: WebColors.divider),
                      left: isSelected
                          ? const BorderSide(
                              color: WebColors.primary,
                              width: 3,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            WebAvatar(
                              initials: farmer.avatarInitials,
                              size: 32,
                              color: _avatarColor(farmer.id),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmer.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: WebColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    farmer.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: WebColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          farmer.location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: WebColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${farmer.farmSizeAcres} acres',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: WebColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          farmer.soilType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: WebColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: WebColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${farmer.recommendationCount}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: WebColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d').format(farmer.lastActivity),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: WebColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: WebBadge(
                          label: farmer.status,
                          color: _farmerStatusColor(farmer.status),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          color: WebColors.textSecondary,
                          onPressed: () => onSelect(farmer),
                          tooltip: 'View profile',
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

class _FarmerDetailPanel extends StatelessWidget {
  final WebFarmer farmer;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onRefreshFarmer;
  final VoidCallback onMessageFarmer;
  final VoidCallback onCreateFarm;
  final ValueChanged<Map<String, dynamic>> onEditFarm;
  final ValueChanged<Map<String, dynamic>> onDeleteFarm;
  final ValueChanged<Map<String, dynamic>> onAddFarmRecord;
  final void Function(Map<String, dynamic>, Map<String, dynamic>) onEditFarmRecord;

  const _FarmerDetailPanel({
    required this.farmer,
    required this.busy,
    required this.onClose,
    required this.onRefreshFarmer,
    required this.onMessageFarmer,
    required this.onCreateFarm,
    required this.onEditFarm,
    required this.onDeleteFarm,
    required this.onAddFarmRecord,
    required this.onEditFarmRecord,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = [...farmer.recommendations]
      ..sort((a, b) => b.date.compareTo(a.date));
    final reports = [...farmer.reports]
      ..sort(
        (a, b) => _dateValue(b['created_at']).compareTo(_dateValue(a['created_at'])),
      );

    return Container(
      color: WebColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Farmer Profile',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: WebColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  color: WebColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: WebColors.gradientGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  WebAvatar(
                    initials: farmer.avatarInitials,
                    size: 52,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          farmer.location,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        WebBadge(
                          label: farmer.status,
                          color: Colors.white,
                          filled: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(
                  label: 'Farm Size',
                  value: '${farmer.farmSizeAcres} ac',
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Recommendations',
                  value: '${farmer.recommendationCount}',
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Soil Type',
                  value: farmer.soilType.isEmpty ? 'Unknown' : farmer.soilType,
                ),
              ],
            ),
            const SizedBox(height: 16),
            WebCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: WebColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  WebInfoField(
                    label: 'Phone',
                    value: farmer.phone.isEmpty ? 'Not provided' : farmer.phone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 8),
                  WebInfoField(
                    label: 'Email',
                    value: farmer.email.isEmpty ? 'Not provided' : farmer.email,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 8),
                  WebInfoField(
                    label: 'Registered',
                    value: DateFormat('MMM d, yyyy').format(
                      farmer.registeredDate,
                    ),
                    icon: Icons.calendar_today,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WebCard(
              title: 'Quick Actions',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  WebButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline,
                    onPressed: busy ? null : onMessageFarmer,
                  ),
                  WebButton(
                    label: 'Add Farm',
                    icon: Icons.add_business_outlined,
                    outlined: true,
                    onPressed: busy ? null : onCreateFarm,
                  ),
                  WebButton(
                    label: 'Refresh',
                    icon: Icons.refresh,
                    outlined: true,
                    onPressed: busy ? null : onRefreshFarmer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WebCard(
              title: 'Farm Records',
              titleAction: WebBadge(
                label: '${farmer.farms.length} farms',
                color: WebColors.primary,
              ),
              child: farmer.farms.isEmpty
                  ? Text(
                      'No farm records were returned for this farmer. Add the first farm here so the farmer app and AI recommendations have data to work from.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WebColors.textSecondary,
                        height: 1.45,
                      ),
                    )
                  : Column(
                      children: farmer.farms.map((farm) {
                        final records = _mapList(farm['records'])
                          ..sort(
                            (left, right) => _dateValue(right['recorded_at'])
                                .compareTo(_dateValue(left['recorded_at'])),
                          );
                        final latestRecord = records.isNotEmpty ? records.first : null;
                        final name = _text(farm['name'], fallback: 'Farm');
                        final location = _text(
                          farm['location_text'],
                          fallback: _text(farm['location']),
                        );
                        final soilType = _text(
                          farm['soil_type'],
                          fallback: 'Unknown soil',
                        );
                        final size =
                            double.tryParse(farm['size_acres']?.toString() ?? '') ?? 0;
                        final soilPh =
                            double.tryParse(farm['soil_ph']?.toString() ?? '') ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: WebColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: WebColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            location.isEmpty
                                                ? 'Location not provided'
                                                : location,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: WebColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    WebBadge(
                                      label: '${records.length} readings',
                                      color: WebColors.info,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: WebInfoField(
                                        label: 'Soil',
                                        value: soilType,
                                        icon: Icons.layers_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: WebInfoField(
                                        label: 'Size',
                                        value: '${size.toStringAsFixed(1)} acres',
                                        icon: Icons.square_foot_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: WebInfoField(
                                        label: 'Soil pH',
                                        value: soilPh == 0
                                            ? 'Not set'
                                            : soilPh.toStringAsFixed(1),
                                        icon: Icons.science_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: WebInfoField(
                                        label: 'Climate',
                                        value:
                                            '${_text(farm['rainfall'], fallback: 'Rainfall not set')} | ${_text(farm['temperature'], fallback: 'Temp not set')}',
                                        icon: Icons.cloud_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_text(farm['notes']).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _text(farm['notes']),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: WebColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _PanelAction(
                                      label: 'Edit Farm',
                                      icon: Icons.edit_outlined,
                                      onPressed: busy ? null : () => onEditFarm(farm),
                                    ),
                                    _PanelAction(
                                      label: 'Log Field Reading',
                                      icon: Icons.monitor_heart_outlined,
                                      onPressed: busy
                                          ? null
                                          : () => onAddFarmRecord(farm),
                                    ),
                                    _PanelAction(
                                      label: 'Delete',
                                      icon: Icons.delete_outline,
                                      color: WebColors.danger,
                                      onPressed: busy
                                          ? null
                                          : () => onDeleteFarm(farm),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (latestRecord == null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: WebColors.divider),
                                    ),
                                    child: Text(
                                      'No field readings logged yet. Add one so the recommendation engine uses current soil and climate values.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: WebColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Latest Reading',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: WebColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...records.take(3).map(
                                        (record) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: WebColors.divider,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        DateFormat('MMM d, yyyy - h:mm a')
                                                            .format(
                                                          _dateValue(
                                                            record['recorded_at'],
                                                          ),
                                                        ),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              WebColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed: busy
                                                          ? null
                                                          : () => onEditFarmRecord(
                                                                farm,
                                                                record,
                                                              ),
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 14,
                                                      ),
                                                      label: const Text('Edit'),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${_text(record['soil_type'], fallback: soilType)} - pH ${_numberString(record['soil_ph'], fallback: soilPh == 0 ? 'not set' : soilPh.toStringAsFixed(1))}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color:
                                                        WebColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'N ${_text(record['nitrogen'], fallback: 'n/a')} | P ${_text(record['phosphorus'], fallback: 'n/a')} | K ${_text(record['potassium'], fallback: 'n/a')}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color:
                                                        WebColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rainfall ${_text(record['rainfall'], fallback: 'n/a')} | Temperature ${_text(record['temperature'], fallback: 'n/a')}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color:
                                                        WebColors.textSecondary,
                                                  ),
                                                ),
                                                if (_text(record['notes']).isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _text(record['notes']),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: WebColors.textMuted,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            WebCard(
              title: 'Recent Farmer Reports',
              child: reports.isEmpty
                  ? Text(
                      'No farmer reports were returned for this profile yet.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WebColors.textSecondary,
                      ),
                    )
                  : Column(
                      children: reports.take(4).map((report) {
                        final farmName = _text(
                          _mapValue(report['farm'])?['name'],
                          fallback: 'Farm report',
                        );
                        final excerpt = _text(
                          report['summary'],
                          fallback: _text(
                            report['content'],
                            fallback: _text(
                              report['notes'],
                              fallback: _text(report['title'], fallback: farmName),
                            ),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: WebColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        farmName,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: WebColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d').format(
                                        _dateValue(report['created_at']),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: WebColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  excerpt,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: WebColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            WebCard(
              title: 'Recommendation History',
              child: recommendations.isEmpty
                  ? Text(
                      'No recommendation records were returned for this farmer.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WebColors.textSecondary,
                      ),
                    )
                  : Column(
                      children: recommendations.take(6).map((recommendation) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _recommendationStatusColor(
                                    recommendation.status,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.eco_outlined,
                                  color: WebColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recommendation.cropName.isEmpty
                                          ? 'Pending recommendation'
                                          : recommendation.cropName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(
                                        recommendation.date,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: WebColors.textMuted,
                                      ),
                                    ),
                                    if (recommendation.reason.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        recommendation.reason,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: WebColors.textSecondary,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              WebBadge(
                                label: recommendation.status,
                                color: _recommendationStatusColor(
                                  recommendation.status,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            WebCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: WebColors.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Farm data, field readings, farmer reports, and generated recommendations shown here are now the source of truth for the farmer mobile app. The mobile shell refreshes from the backend on a short timer while it is open.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WebColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  const _PanelAction({
    required this.label,
    required this.icon,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? WebColors.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: actionColor,
        side: BorderSide(color: actionColor.withValues(alpha: 0.35)),
        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FarmEditorDialog extends StatefulWidget {
  final String farmerName;
  final Map<String, dynamic>? farm;

  const _FarmEditorDialog({
    required this.farmerName,
    this.farm,
  });

  @override
  State<_FarmEditorDialog> createState() => _FarmEditorDialogState();
}

class _FarmEditorDialogState extends State<_FarmEditorDialog> {
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
    final farm = widget.farm;
    final soilType = _text(farm?['soil_type']);
    _soilType = _soilTypes.contains(soilType) ? soilType : _soilTypes.first;
    _nameController = TextEditingController(text: _text(farm?['name']));
    _locationController =
        TextEditingController(text: _text(farm?['location_text'], fallback: _text(farm?['location'])));
    _latController = TextEditingController(
      text: _numberString(farm?['lat'], fallback: '0'),
    );
    _lngController = TextEditingController(
      text: _numberString(farm?['lng'], fallback: '0'),
    );
    _sizeController = TextEditingController(
      text: _numberString(farm?['size_acres'], fallback: '0'),
    );
    _soilPhController = TextEditingController(
      text: _numberString(farm?['soil_ph'], fallback: '6.5'),
    );
    _nitrogenController =
        TextEditingController(text: _text(farm?['nitrogen'], fallback: '45 ppm'));
    _phosphorusController = TextEditingController(
      text: _text(farm?['phosphorus'], fallback: '30 ppm'),
    );
    _potassiumController = TextEditingController(
      text: _text(farm?['potassium'], fallback: '180 ppm'),
    );
    _rainfallController = TextEditingController(
      text: _text(farm?['rainfall'], fallback: '800 mm'),
    );
    _temperatureController = TextEditingController(
      text: _text(farm?['temperature'], fallback: '27 C'),
    );
    _notesController = TextEditingController(text: _text(farm?['notes']));
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
    final isEditing = widget.farm != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Farm' : 'Add Farm'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.farmerName} will immediately see this farm data in the mobile app after the next sync.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _DialogLabel(label: 'Farm Name'),
                TextFormField(
                  controller: _nameController,
                  validator: _requiredText,
                  decoration: const InputDecoration(hintText: 'Main Farm Plot'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Location'),
                TextFormField(
                  controller: _locationController,
                  validator: _requiredText,
                  decoration: const InputDecoration(
                    hintText: 'Village, district, or landmark',
                  ),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Soil Type'),
                DropdownButtonFormField<String>(
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
                const SizedBox(height: 12),
                _DialogLabel(label: 'Coordinates'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        validator: _requiredNumber,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        validator: _requiredNumber,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Farm Size and Soil pH'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        validator: _requiredNumber,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Size (acres)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _soilPhController,
                        validator: _requiredNumber,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Soil pH'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Nutrient Profile'),
                TextFormField(
                  controller: _nitrogenController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Nitrogen'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phosphorusController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Phosphorus'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _potassiumController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Potassium'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Climate Conditions'),
                TextFormField(
                  controller: _rainfallController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Rainfall'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _temperatureController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Temperature'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Notes'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Drainage, current crops, irrigation, or advisor observations',
                  ),
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Farm' : 'Create Farm'),
        ),
      ],
    );
  }
}

class _FieldRecordDialog extends StatefulWidget {
  final String farmName;
  final Map<String, dynamic> farmSnapshot;
  final Map<String, dynamic>? record;

  const _FieldRecordDialog({
    required this.farmName,
    required this.farmSnapshot,
    this.record,
  });

  @override
  State<_FieldRecordDialog> createState() => _FieldRecordDialogState();
}

class _FieldRecordDialogState extends State<_FieldRecordDialog> {
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
    final record = widget.record;
    final farm = widget.farmSnapshot;
    final soilType = _text(
      record?['soil_type'],
      fallback: _text(farm['soil_type']),
    );
    _soilType = _soilTypes.contains(soilType) ? soilType : _soilTypes.first;
    _soilPhController = TextEditingController(
      text: _numberString(
        record?['soil_ph'],
        fallback: _numberString(farm['soil_ph'], fallback: '6.5'),
      ),
    );
    _nitrogenController = TextEditingController(
      text: _text(record?['nitrogen'], fallback: _text(farm['nitrogen'])),
    );
    _phosphorusController = TextEditingController(
      text: _text(record?['phosphorus'], fallback: _text(farm['phosphorus'])),
    );
    _potassiumController = TextEditingController(
      text: _text(record?['potassium'], fallback: _text(farm['potassium'])),
    );
    _rainfallController = TextEditingController(
      text: _text(record?['rainfall'], fallback: _text(farm['rainfall'])),
    );
    _temperatureController = TextEditingController(
      text: _text(record?['temperature'], fallback: _text(farm['temperature'])),
    );
    _notesController = TextEditingController(
      text: _text(record?['notes'], fallback: _text(farm['notes'])),
    );
  }

  @override
  void dispose() {
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
    final isEditing = widget.record != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Field Reading' : 'Log Field Reading'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'These values become the latest field snapshot for ${widget.farmName} and are used by the recommendation engine.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _DialogLabel(label: 'Soil Type'),
                DropdownButtonFormField<String>(
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
                const SizedBox(height: 12),
                _DialogLabel(label: 'Soil pH'),
                TextFormField(
                  controller: _soilPhController,
                  validator: _requiredNumber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: '6.5'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Nutrients'),
                TextFormField(
                  controller: _nitrogenController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Nitrogen'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phosphorusController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Phosphorus'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _potassiumController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Potassium'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Climate Snapshot'),
                TextFormField(
                  controller: _rainfallController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Rainfall'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _temperatureController,
                  validator: _requiredText,
                  decoration: const InputDecoration(labelText: 'Temperature'),
                ),
                const SizedBox(height: 12),
                _DialogLabel(label: 'Advisor Notes'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Field observations, stress signs, rainfall notes, or expected planting constraints',
                  ),
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Reading' : 'Create Reading'),
        ),
      ],
    );
  }
}

class _DialogLabel extends StatelessWidget {
  final String label;

  const _DialogLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: WebColors.textSecondary,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: WebColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WebColors.divider),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: WebColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _InlineNotice({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: WebColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: WebColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: WebColors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String? _requiredNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return double.tryParse(value.trim()) == null ? 'Enter a number' : null;
}

Color _farmerStatusColor(String status) => switch (status) {
      'Active' => WebColors.primary,
      'Inactive' => WebColors.textSecondary,
      'Pending' => WebColors.warning,
      _ => WebColors.textMuted,
    };

Color _recommendationStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'published':
    case 'active':
      return WebColors.primary;
    case 'generated':
      return WebColors.info;
    case 'pending':
      return WebColors.warning;
    case 'archived':
    case 'completed':
      return WebColors.textSecondary;
    default:
      return WebColors.textMuted;
  }
}

Color _avatarColor(String id) {
  final colors = [
    WebColors.primary,
    WebColors.info,
    WebColors.warning,
    WebColors.purple,
    WebColors.accent,
  ];
  return colors[id.hashCode % colors.length];
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

DateTime _dateValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String _numberString(dynamic value, {String fallback = ''}) {
  if (value is num) {
    final doubleValue = value.toDouble();
    return doubleValue == doubleValue.roundToDouble()
        ? doubleValue.toStringAsFixed(0)
        : doubleValue.toStringAsFixed(1);
  }
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

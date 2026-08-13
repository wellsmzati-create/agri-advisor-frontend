import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebRecommendationsScreen extends StatefulWidget {
  const WebRecommendationsScreen({super.key});

  @override
  State<WebRecommendationsScreen> createState() =>
      _WebRecommendationsScreenState();
}

class _WebRecommendationsScreenState extends State<WebRecommendationsScreen> {
  final TextEditingController _currentCropsController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _tab = 0;
  bool _loading = true;
  String? _error;

  List<CropRecommendation> _recommendations = const [];
  List<Map<String, dynamic>> _farmers = const [];
  List<_FarmChoice> _farmChoices = const [];
  CropRecommendation? _selected;

  String _selectedFarmId = '';
  String _selectedSeason = 'Major Rainy Season';
  bool _generating = false;
  CropRecommendation? _generatedRec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _currentCropsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.advisorRecommendations(),
        ApiService.advisorFarmers(),
      ]);
      if (!mounted) return;

      final farmers = (results[1] as List).cast<Map<String, dynamic>>();
      final farmChoices = _buildFarmChoices(farmers);
      final nextFarmId = farmChoices.any((choice) => choice.id == _selectedFarmId)
          ? _selectedFarmId
          : (farmChoices.isNotEmpty ? farmChoices.first.id : '');

      setState(() {
        _recommendations = results[0] as List<CropRecommendation>;
        _farmers = farmers;
        _farmChoices = farmChoices;
        _selectedFarmId = nextFarmId;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recommendations = const [];
        _farmers = const [];
        _farmChoices = const [];
        _error = 'Unable to load recommendation data from the backend.';
        _loading = false;
      });
    }
  }

  Future<void> _generate() async {
    if (_selectedFarmId.isEmpty) return;

    setState(() {
      _generating = true;
      _generatedRec = null;
    });

    try {
      final created = await ApiService.createRecommendation(
        farmId: _selectedFarmId,
        season: _selectedSeason,
        currentCrops: _parseCurrentCrops(_currentCropsController.text),
        notes: _notesController.text.trim(),
      );

      CropRecommendation current = created;
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        current = await ApiService.getRecommendation(created.id);
        if (current.status == 'generated' || current.status == 'published') {
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _generatedRec = current;
        _generating = false;
        _recommendations = [
          current,
          ..._recommendations.where((rec) => rec.id != current.id),
        ];
        _selected = current;
        _tab = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recommendation generation failed. Please check the backend queue and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _recommendations.isEmpty && _farmers.isEmpty) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Recommendations',
            subtitle:
                'Generate advice from advisor-managed farm data and review backend recommendations',
            action: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                _TabButton(
                  label: 'All Recommendations',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _TabButton(
                  label: 'Generate New',
                  selected: _tab == 1,
                  primary: true,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _InlineError(
              message: _error!,
              onRetry: () {
                setState(() => _loading = true);
                _load();
              },
            ),
          ],
          const SizedBox(height: 24),
          if (_tab == 0)
            _RecommendationsPanel(
              recommendations: _recommendations,
              selected: _selected,
              onSelect: (recommendation) {
                setState(() {
                  _selected =
                      _selected?.id == recommendation.id ? null : recommendation;
                });
              },
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms)
          else
            _GeneratePanel(
              farmChoices: _farmChoices,
              selectedFarmId: _selectedFarmId,
              selectedSeason: _selectedSeason,
              currentCropsController: _currentCropsController,
              notesController: _notesController,
              generating: _generating,
              generatedRec: _generatedRec,
              onFarmChanged: (farmId) => setState(() => _selectedFarmId = farmId),
              onSeasonChanged: (season) =>
                  setState(() => _selectedSeason = season),
              onGenerate: _generate,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? (primary
            ? WebColors.primary
            : WebColors.primary.withValues(alpha: 0.1))
        : WebColors.cardBg;
    final foreground = selected
        ? (primary ? Colors.white : WebColors.primary)
        : WebColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? WebColors.primary : WebColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _RecommendationsPanel extends StatelessWidget {
  final List<CropRecommendation> recommendations;
  final CropRecommendation? selected;
  final ValueChanged<CropRecommendation> onSelect;

  const _RecommendationsPanel({
    required this.recommendations,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth > 860;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _RecommendationList(
                      recommendations: recommendations,
                      selected: selected,
                      onSelect: onSelect,
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _RecommendationDetail(rec: selected!)),
                  ],
                ],
              )
            : _RecommendationList(
                recommendations: recommendations,
                selected: selected,
                onSelect: onSelect,
              );
      },
    );
  }
}

class _RecommendationList extends StatelessWidget {
  final List<CropRecommendation> recommendations;
  final CropRecommendation? selected;
  final ValueChanged<CropRecommendation> onSelect;

  const _RecommendationList({
    required this.recommendations,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return WebCard(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No recommendations have been generated yet.',
              style: GoogleFonts.inter(color: WebColors.textMuted),
            ),
          ),
        ),
      );
    }

    return WebCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: recommendations.map((rec) {
          final isSelected = selected?.id == rec.id;
          final statusColor = _statusColor(rec.status);

          return GestureDetector(
            onTap: () => onSelect(rec),
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.eco, color: WebColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.cropName.isEmpty
                              ? 'Pending recommendation'
                              : rec.cropName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rec.advisorName.isEmpty
                              ? 'By Advisor'
                              : 'By ${rec.advisorName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: WebColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat('MMM d, yyyy').format(rec.date),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: WebColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  WebBadge(label: rec.status, color: statusColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecommendationDetail extends StatelessWidget {
  final CropRecommendation rec;

  const _RecommendationDetail({required this.rec});

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: rec.cropName.isEmpty ? 'Recommendation Details' : rec.cropName,
      titleAction: WebBadge(label: rec.status, color: _statusColor(rec.status)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rec.advisorName.isEmpty
                ? 'Prepared by Advisor'
                : 'Prepared by ${rec.advisorName}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: WebColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          WebInfoField(
            label: 'Reason',
            value: rec.reason.isEmpty
                ? 'Waiting for generated explanation.'
                : rec.reason,
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Soil Type',
                  value: rec.soilType.isEmpty ? 'Pending' : rec.soilType,
                  icon: Icons.layers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Season',
                  value: rec.season.isEmpty ? 'Pending' : rec.season,
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          WebInfoField(
            label: 'Rainfall',
            value: rec.rainfall.isEmpty ? 'Pending' : rec.rainfall,
            icon: Icons.water_drop,
          ),
          const SizedBox(height: 16),
          Text(
            'Steps',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (rec.steps.isEmpty)
            Text(
              'No generated steps yet. If this recommendation is still pending, check the backend queue worker.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: WebColors.textSecondary,
                height: 1.45,
              ),
            )
          else
            ...rec.steps.asMap().entries.map(
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
                          color: WebColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneratePanel extends StatelessWidget {
  final List<_FarmChoice> farmChoices;
  final String selectedFarmId;
  final String selectedSeason;
  final TextEditingController currentCropsController;
  final TextEditingController notesController;
  final bool generating;
  final CropRecommendation? generatedRec;
  final ValueChanged<String> onFarmChanged;
  final ValueChanged<String> onSeasonChanged;
  final VoidCallback onGenerate;

  const _GeneratePanel({
    required this.farmChoices,
    required this.selectedFarmId,
    required this.selectedSeason,
    required this.currentCropsController,
    required this.notesController,
    required this.generating,
    required this.generatedRec,
    required this.onFarmChanged,
    required this.onSeasonChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final selectedChoice = farmChoices.firstWhere(
      (choice) => choice.id == selectedFarmId,
      orElse: () => farmChoices.isNotEmpty ? farmChoices.first : _FarmChoice.empty,
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth > 860;
        final form = _GenerateForm(
          farmChoices: farmChoices,
          selectedFarmId: selectedFarmId,
          selectedSeason: selectedSeason,
          currentCropsController: currentCropsController,
          notesController: notesController,
          generating: generating,
          onFarmChanged: onFarmChanged,
          onSeasonChanged: onSeasonChanged,
          onGenerate: onGenerate,
        );
        final rightPane = generatedRec != null
            ? _RecommendationDetail(rec: generatedRec!)
            : selectedChoice.id.isEmpty
                ? const _GenerationPlaceholder()
                : _StoredFarmContext(choice: selectedChoice);

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: form),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: rightPane),
                ],
              )
            : Column(
                children: [
                  form,
                  const SizedBox(height: 20),
                  rightPane,
                ],
              );
      },
    );
  }
}

class _GenerateForm extends StatelessWidget {
  final List<_FarmChoice> farmChoices;
  final String selectedFarmId;
  final String selectedSeason;
  final TextEditingController currentCropsController;
  final TextEditingController notesController;
  final bool generating;
  final ValueChanged<String> onFarmChanged;
  final ValueChanged<String> onSeasonChanged;
  final VoidCallback onGenerate;

  const _GenerateForm({
    required this.farmChoices,
    required this.selectedFarmId,
    required this.selectedSeason,
    required this.currentCropsController,
    required this.notesController,
    required this.generating,
    required this.onFarmChanged,
    required this.onSeasonChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: 'Recommendation Inputs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (farmChoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WebColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: WebColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'No advisor-managed farms are available yet. Add farm and field data from the Farmers screen first.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: WebColors.warning,
                ),
              ),
            )
          else ...[
            _DropdownField(
              label: 'Select Farmer Farm',
              items: farmChoices.map((choice) => choice.label).toList(),
              value: farmChoices
                  .firstWhere(
                    (choice) => choice.id == selectedFarmId,
                    orElse: () => farmChoices.first,
                  )
                  .label,
              onChanged: (label) {
                final match = farmChoices.firstWhere(
                  (choice) => choice.label == label,
                  orElse: () => farmChoices.first,
                );
                onFarmChanged(match.id);
              },
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Target Season',
              items: const [
                'Major Rainy Season',
                'Minor Season',
                'Dry Season',
                'Year-round',
              ],
              value: selectedSeason,
              onChanged: onSeasonChanged,
            ),
            const SizedBox(height: 12),
            _TextAreaField(
              label: 'Current Crops',
              controller: currentCropsController,
              hint:
                  'Optional. Example: maize, beans, cassava. Separate multiple crops with commas or new lines.',
            ),
            const SizedBox(height: 12),
            _TextAreaField(
              label: 'Advisor Notes',
              controller: notesController,
              hint:
                  'Optional extra context for the AI service, such as disease pressure, irrigation access, or field visit observations.',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WebColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: WebColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Soil, nutrients, rainfall, temperature, seasonal notices, and farmer reports now come from stored backend data. This form only adds season and advisor context.',
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: generating || selectedFarmId.isEmpty ? null : onGenerate,
              icon: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                generating ? 'Generating...' : 'Generate Recommendation',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: WebColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoredFarmContext extends StatelessWidget {
  final _FarmChoice choice;

  const _StoredFarmContext({required this.choice});

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: 'Stored Farm Context',
      titleAction: WebBadge(
        label: choice.records.isEmpty ? 'Farm snapshot' : 'Latest field data',
        color: choice.records.isEmpty ? WebColors.warning : WebColors.info,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${choice.farmerName} - ${choice.farmName}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: WebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            choice.location.isEmpty ? 'Location not provided' : choice.location,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: WebColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Soil Type',
                  value: choice.soilType.isEmpty ? 'Not set' : choice.soilType,
                  icon: Icons.layers_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Soil pH',
                  value: choice.soilPh == 0
                      ? 'Not set'
                      : choice.soilPh.toStringAsFixed(1),
                  icon: Icons.science_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Rainfall',
                  value: choice.rainfall.isEmpty ? 'Not set' : choice.rainfall,
                  icon: Icons.water_drop_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Temperature',
                  value: choice.temperature.isEmpty
                      ? 'Not set'
                      : choice.temperature,
                  icon: Icons.thermostat_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WebInfoField(
                  label: 'Nitrogen',
                  value: choice.nitrogen.isEmpty ? 'Not set' : choice.nitrogen,
                  icon: Icons.grass_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebInfoField(
                  label: 'Phosphorus',
                  value: choice.phosphorus.isEmpty
                      ? 'Not set'
                      : choice.phosphorus,
                  icon: Icons.scatter_plot_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          WebInfoField(
            label: 'Potassium',
            value: choice.potassium.isEmpty ? 'Not set' : choice.potassium,
            icon: Icons.bubble_chart_outlined,
          ),
          if (choice.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Advisor/Farm Notes',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              choice.notes,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: WebColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (choice.latestRecordedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last field reading: ${DateFormat('MMM d, yyyy - h:mm a').format(choice.latestRecordedAt!)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: WebColors.textMuted,
              ),
            ),
          ],
          if (choice.reportExcerpts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent Farmer Reports',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...choice.reportExcerpts.take(3).map(
              (excerpt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WebColors.divider),
                  ),
                  child: Text(
                    excerpt,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: WebColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
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
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.isNotEmpty ? items.first : null,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.inter(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: items.isEmpty
              ? null
              : (selected) {
                  if (selected != null) onChanged(selected);
                },
          decoration: const InputDecoration(),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: WebColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TextAreaField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _TextAreaField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 3,
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
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _GenerationPlaceholder extends StatelessWidget {
  const _GenerationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: WebColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: WebColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Backend-generated recommendations',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WebColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a farmer farm to preview the stored field context and generate a recommendation.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: WebColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: WebColors.warning),
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
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _FarmChoice {
  final String id;
  final String label;
  final String farmerName;
  final String farmName;
  final String location;
  final String soilType;
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String rainfall;
  final String temperature;
  final String notes;
  final double soilPh;
  final List<Map<String, dynamic>> records;
  final List<String> reportExcerpts;
  final DateTime? latestRecordedAt;

  const _FarmChoice({
    required this.id,
    required this.label,
    required this.farmerName,
    required this.farmName,
    required this.location,
    required this.soilType,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.rainfall,
    required this.temperature,
    required this.notes,
    required this.soilPh,
    required this.records,
    required this.reportExcerpts,
    required this.latestRecordedAt,
  });

  static const empty = _FarmChoice(
    id: '',
    label: '',
    farmerName: '',
    farmName: '',
    location: '',
    soilType: '',
    nitrogen: '',
    phosphorus: '',
    potassium: '',
    rainfall: '',
    temperature: '',
    notes: '',
    soilPh: 0,
    records: [],
    reportExcerpts: [],
    latestRecordedAt: null,
  );
}

List<_FarmChoice> _buildFarmChoices(List<Map<String, dynamic>> farmers) {
  final choices = <_FarmChoice>[];

  for (final farmer in farmers) {
    final farmerName = _text(farmer['name'], fallback: 'Farmer');
    final reports = _mapList(farmer['reports']);
    final reportExcerpts = reports
        .map(
          (report) => _text(
            report['summary'],
            fallback: _text(
              report['content'],
              fallback: _text(
                report['notes'],
                fallback: _text(report['title']),
              ),
            ),
          ),
        )
        .where((excerpt) => excerpt.isNotEmpty)
        .toList();

    for (final farm in _mapList(farmer['farms'])) {
      final records = _mapList(farm['records'])
        ..sort(
          (left, right) => _dateValue(right['recorded_at'])
              .compareTo(_dateValue(left['recorded_at'])),
        );
      final latestRecord = records.isNotEmpty ? records.first : null;

      choices.add(
        _FarmChoice(
          id: _text(farm['id']),
          label:
              '$farmerName - ${_text(farm['name'], fallback: 'Farm')}',
          farmerName: farmerName,
          farmName: _text(farm['name'], fallback: 'Farm'),
          location: _text(
            farm['location_text'],
            fallback: _text(farm['location']),
          ),
          soilType: _text(
            latestRecord?['soil_type'],
            fallback: _text(farm['soil_type']),
          ),
          nitrogen: _text(
            latestRecord?['nitrogen'],
            fallback: _text(farm['nitrogen']),
          ),
          phosphorus: _text(
            latestRecord?['phosphorus'],
            fallback: _text(farm['phosphorus']),
          ),
          potassium: _text(
            latestRecord?['potassium'],
            fallback: _text(farm['potassium']),
          ),
          rainfall: _text(
            latestRecord?['rainfall'],
            fallback: _text(farm['rainfall']),
          ),
          temperature: _text(
            latestRecord?['temperature'],
            fallback: _text(farm['temperature']),
          ),
          notes: _text(
            latestRecord?['notes'],
            fallback: _text(farm['notes']),
          ),
          soilPh: _doubleValue(
            latestRecord?['soil_ph'],
            fallback: _doubleValue(farm['soil_ph']),
          ),
          records: records,
          reportExcerpts: reportExcerpts,
          latestRecordedAt: latestRecord == null
              ? null
              : _dateValue(latestRecord['recorded_at']),
        ),
      );
    }
  }

  return choices;
}

List<String> _parseCurrentCrops(String value) {
  return value
      .split(RegExp(r'[\n,]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _dateValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

Color _statusColor(String status) => switch (status) {
      'published' => WebColors.primary,
      'generated' => WebColors.info,
      'pending' => WebColors.warning,
      'archived' => WebColors.textMuted,
      _ => WebColors.textMuted,
    };

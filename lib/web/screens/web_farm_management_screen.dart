import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../web_theme.dart';
import '../web_mock_data.dart';
import '../widgets/web_widgets.dart';

class WebFarmManagementScreen extends StatefulWidget {
  const WebFarmManagementScreen({super.key});

  @override
  State<WebFarmManagementScreen> createState() => _WebFarmManagementScreenState();
}

class _WebFarmManagementScreenState extends State<WebFarmManagementScreen> {
  String? _selectedFarmerId;
  bool _showForm = false;
  String _soilType = 'Loamy';
  double _soilPh = 6.5;
  double _nitrogen = 45;
  double _phosphorus = 30;
  double _potassium = 180;
  double _rainfall = 800;
  double _temperature = 27;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Farm Information Management',
            subtitle: 'Record and manage soil, environmental, and farm data',
            action: WebButton(label: 'New Farm Record', icon: Icons.add, onPressed: () => setState(() => _showForm = true)),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (_, c) {
            final isWide = c.maxWidth > 800;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _RecordsPanel(records: WebMockData.farmRecords, selectedId: _selectedFarmerId, onSelect: (id) => setState(() => _selectedFarmerId = id))),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _showForm ? _FarmDataForm(
                        soilType: _soilType, soilPh: _soilPh,
                        nitrogen: _nitrogen, phosphorus: _phosphorus, potassium: _potassium,
                        rainfall: _rainfall, temperature: _temperature,
                        onSoilType: (v) => setState(() => _soilType = v),
                        onPh: (v) => setState(() => _soilPh = v),
                        onNitrogen: (v) => setState(() => _nitrogen = v),
                        onPhosphorus: (v) => setState(() => _phosphorus = v),
                        onPotassium: (v) => setState(() => _potassium = v),
                        onRainfall: (v) => setState(() => _rainfall = v),
                        onTemperature: (v) => setState(() => _temperature = v),
                        onSave: () => setState(() => _showForm = false),
                        onCancel: () => setState(() => _showForm = false),
                      ) : _selectedFarmerId != null
                          ? _FarmRecordDetail(record: WebMockData.farmRecords.firstWhere((r) => r.farmerId == _selectedFarmerId, orElse: () => WebMockData.farmRecords.first))
                          : _EmptyState()),
                    ],
                  )
                : Column(children: [
                    _RecordsPanel(records: WebMockData.farmRecords, selectedId: _selectedFarmerId, onSelect: (id) => setState(() => _selectedFarmerId = id)),
                    const SizedBox(height: 20),
                    if (_showForm) _FarmDataForm(
                      soilType: _soilType, soilPh: _soilPh,
                      nitrogen: _nitrogen, phosphorus: _phosphorus, potassium: _potassium,
                      rainfall: _rainfall, temperature: _temperature,
                      onSoilType: (v) => setState(() => _soilType = v),
                      onPh: (v) => setState(() => _soilPh = v),
                      onNitrogen: (v) => setState(() => _nitrogen = v),
                      onPhosphorus: (v) => setState(() => _phosphorus = v),
                      onPotassium: (v) => setState(() => _potassium = v),
                      onRainfall: (v) => setState(() => _rainfall = v),
                      onTemperature: (v) => setState(() => _temperature = v),
                      onSave: () => setState(() => _showForm = false),
                      onCancel: () => setState(() => _showForm = false),
                    ),
                  ]);
          }).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _RecordsPanel extends StatelessWidget {
  final List<FarmRecord> records;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _RecordsPanel({required this.records, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final farmers = WebMockData.farmers;
    return WebCard(
      title: 'Farm Records',
      titleAction: Text('${records.length} records', style: GoogleFonts.inter(fontSize: 12, color: WebColors.textSecondary)),
      padding: EdgeInsets.zero,
      child: Column(
        children: records.map((r) {
          final farmer = farmers.firstWhere((f) => f.id == r.farmerId, orElse: () => farmers.first);
          final isSelected = selectedId == r.farmerId;
          return GestureDetector(
            onTap: () => onSelect(r.farmerId),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? WebColors.primary.withValues(alpha: 0.05) : Colors.white,
                border: Border(
                  bottom: const BorderSide(color: WebColors.divider),
                  left: isSelected ? const BorderSide(color: WebColors.primary, width: 3) : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  WebAvatar(initials: farmer.avatarInitials, size: 36, color: WebColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farmer.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(r.location, style: GoogleFonts.inter(fontSize: 11, color: WebColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            WebBadge(label: r.soilType, color: const Color(0xFF795548)),
                            const SizedBox(width: 6),
                            WebBadge(label: 'pH ${r.soilPh}', color: WebColors.info),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(DateFormat('MMM d').format(r.recordedAt), style: GoogleFonts.inter(fontSize: 11, color: WebColors.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FarmRecordDetail extends StatelessWidget {
  final FarmRecord record;
  const _FarmRecordDetail({required this.record});

  @override
  Widget build(BuildContext context) {
    final farmer = WebMockData.farmers.firstWhere((f) => f.id == record.farmerId, orElse: () => WebMockData.farmers.first);
    return WebCard(
      title: 'Farm Record — ${farmer.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Soil Information'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: WebInfoField(label: 'Soil Type', value: record.soilType, icon: Icons.layers)),
            const SizedBox(width: 12),
            Expanded(child: WebInfoField(label: 'Soil pH', value: record.soilPh, icon: Icons.science)),
          ]),
          const SizedBox(height: 12),
          _SectionLabel('Nutrient Levels'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: WebInfoField(label: 'Nitrogen (N)', value: record.nitrogenLevel)),
            const SizedBox(width: 12),
            Expanded(child: WebInfoField(label: 'Phosphorus (P)', value: record.phosphorusLevel)),
          ]),
          const SizedBox(height: 8),
          WebInfoField(label: 'Potassium (K)', value: record.potassiumLevel),
          const SizedBox(height: 12),
          _SectionLabel('Environmental Conditions'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: WebInfoField(label: 'Annual Rainfall', value: '${record.rainfallMm} mm', icon: Icons.water_drop)),
            const SizedBox(width: 12),
            Expanded(child: WebInfoField(label: 'Avg Temperature', value: '${record.avgTempC}°C', icon: Icons.thermostat)),
          ]),
          const SizedBox(height: 12),
          WebInfoField(label: 'Farm Location', value: record.location, icon: Icons.location_on),
          const SizedBox(height: 12),
          WebInfoField(label: 'Advisor Notes', value: record.notes),
          const SizedBox(height: 16),
          Row(children: [
            WebButton(label: 'Edit Record', icon: Icons.edit, onPressed: () {}),
            const SizedBox(width: 10),
            WebButton(label: 'Generate Recommendation', icon: Icons.recommend, outlined: true, onPressed: () {}),
          ]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: WebColors.textSecondary, letterSpacing: 0.5));
  }
}

class _FarmDataForm extends StatelessWidget {
  final String soilType;
  final double soilPh, nitrogen, phosphorus, potassium, rainfall, temperature;
  final ValueChanged<String> onSoilType;
  final ValueChanged<double> onPh, onNitrogen, onPhosphorus, onPotassium, onRainfall, onTemperature;
  final VoidCallback onSave, onCancel;

  const _FarmDataForm({
    required this.soilType, required this.soilPh,
    required this.nitrogen, required this.phosphorus, required this.potassium,
    required this.rainfall, required this.temperature,
    required this.onSoilType, required this.onPh,
    required this.onNitrogen, required this.onPhosphorus, required this.onPotassium,
    required this.onRainfall, required this.onTemperature,
    required this.onSave, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      title: 'New Farm Record',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormDropdown(label: 'Farmer', items: WebMockData.farmers.map((f) => f.name).toList()),
          const SizedBox(height: 16),
          _SectionLabel('Soil Information'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _FormDropdown(label: 'Soil Type', items: ['Loamy', 'Sandy Loam', 'Clay Loam', 'Deep Forest', 'Clay', 'Silty'], initialValue: soilType, onChanged: onSoilType)),
            const SizedBox(width: 12),
            Expanded(child: _FormTextField(label: 'Farm Location', hint: 'e.g. Kumasi, Ashanti')),
          ]),
          const SizedBox(height: 16),
          _SliderField(label: 'Soil pH', value: soilPh, min: 4.0, max: 9.0, divisions: 50, unit: '', onChanged: onPh, color: WebColors.info),
          const SizedBox(height: 12),
          _SectionLabel('Nutrient Levels (ppm)'),
          const SizedBox(height: 10),
          _SliderField(label: 'Nitrogen (N)', value: nitrogen, min: 0, max: 120, divisions: 120, unit: ' ppm', onChanged: onNitrogen, color: WebColors.primary),
          const SizedBox(height: 8),
          _SliderField(label: 'Phosphorus (P)', value: phosphorus, min: 0, max: 80, divisions: 80, unit: ' ppm', onChanged: onPhosphorus, color: WebColors.warning),
          const SizedBox(height: 8),
          _SliderField(label: 'Potassium (K)', value: potassium, min: 0, max: 400, divisions: 80, unit: ' ppm', onChanged: onPotassium, color: WebColors.purple),
          const SizedBox(height: 16),
          _SectionLabel('Environmental Conditions'),
          const SizedBox(height: 10),
          _SliderField(label: 'Annual Rainfall', value: rainfall, min: 200, max: 2000, divisions: 90, unit: ' mm', onChanged: onRainfall, color: WebColors.info),
          const SizedBox(height: 8),
          _SliderField(label: 'Average Temperature', value: temperature, min: 15, max: 40, divisions: 50, unit: '°C', onChanged: onTemperature, color: WebColors.danger),
          const SizedBox(height: 16),
          _FormTextField(label: 'Advisor Notes', hint: 'Observations, previous crops, drainage conditions...', maxLines: 3),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              WebButton(label: 'Cancel', outlined: true, onPressed: onCancel),
              const SizedBox(width: 12),
              WebButton(label: 'Save Farm Record', icon: Icons.save, onPressed: onSave),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color color;

  const _SliderField({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.unit, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: WebColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('${value.toStringAsFixed(unit == '' ? 1 : 0)}$unit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _FormTextField extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  const _FormTextField({required this.label, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: WebColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(fontSize: 13, color: WebColors.textMuted)),
        ),
      ],
    );
  }
}

class _FormDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  const _FormDropdown({required this.label, required this.items, this.initialValue, this.onChanged});

  @override
  State<_FormDropdown> createState() => _FormDropdownState();
}

class _FormDropdownState extends State<_FormDropdown> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: WebColors.textSecondary)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _value,
          items: widget.items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 13)))).toList(),
          onChanged: (v) { setState(() => _value = v); if (v != null) widget.onChanged?.call(v); },
          decoration: const InputDecoration(),
          style: GoogleFonts.inter(fontSize: 13, color: WebColors.textPrimary),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: WebColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.agriculture, size: 40, color: WebColors.primary),
              ),
              const SizedBox(height: 16),
              Text('Select a Farm Record', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: WebColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Choose a record from the list or create a new one', style: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

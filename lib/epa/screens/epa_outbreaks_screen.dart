import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaOutbreaksScreen extends StatefulWidget {
  const EpaOutbreaksScreen({super.key});
  @override State<EpaOutbreaksScreen> createState() => _State();
}

class _State extends State<EpaOutbreaksScreen> {
  OutbreakSignal? _selected;
  String _filter = 'All';

  List<OutbreakSignal> get _filtered => EpaMockData.outbreaks.where((o) => _filter == 'All' || o.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(
          title: 'Outbreak Signal Validation',
          subtitle: 'Review, validate and respond to disease/pest outbreak signals',
          action: EpaBadge(label: '${EpaMockData.outbreaks.where((o) => o.status == "Unvalidated").length} Pending Validation', color: EpaColors.danger),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Row(children: ['All', 'Unvalidated', 'Under Review', 'Validated', 'Resolved'].map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _Chip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
        )).toList()).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: _OutbreakList(outbreaks: _filtered, selected: _selected, onSelect: (o) => setState(() => _selected = _selected?.id == o.id ? null : o))),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _selected != null ? _OutbreakDetail(outbreak: _selected!, onValidate: () => setState(() => _selected = null)) : _EmptyPanel()),
                ])
              : Column(children: [
                  _OutbreakList(outbreaks: _filtered, selected: _selected, onSelect: (o) => setState(() => _selected = _selected?.id == o.id ? null : o)),
                  if (_selected != null) ...[const SizedBox(height: 20), _OutbreakDetail(outbreak: _selected!, onValidate: () => setState(() => _selected = null))],
                ]);
        }).animate().fadeIn(delay: 200.ms),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? EpaColors.primary.withValues(alpha: 0.1) : EpaColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? EpaColors.primary : EpaColors.divider),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? EpaColors.primary : EpaColors.textSecondary)),
      ),
    );
  }
}

class _OutbreakList extends StatelessWidget {
  final List<OutbreakSignal> outbreaks;
  final OutbreakSignal? selected;
  final ValueChanged<OutbreakSignal> onSelect;

  const _OutbreakList({required this.outbreaks, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return EpaCard(
      padding: EdgeInsets.zero,
      child: Column(children: outbreaks.map((o) {
        final isSelected = selected?.id == o.id;
        final sColor = _severityColor(o.severity);
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? EpaColors.primary.withValues(alpha: 0.05) : Colors.white,
              border: Border(bottom: const BorderSide(color: EpaColors.divider), left: isSelected ? const BorderSide(color: EpaColors.primary, width: 3) : BorderSide.none),
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(_cropEmoji(o.cropAffected), style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${o.location} • ${o.affectedFarms} farms', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  SeverityBadge(severity: o.severity),
                  const SizedBox(width: 6),
                  EpaBadge(label: o.status, color: _statusColor(o.status)),
                ]),
              ])),
              Text(DateFormat('MMM d').format(o.reportedAt), style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textMuted)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Color _severityColor(String s) => switch (s) { 'Critical' => EpaColors.danger, 'High' => EpaColors.warning, 'Medium' => EpaColors.amber, _ => EpaColors.success };
  Color _statusColor(String s) => switch (s) { 'Unvalidated' => EpaColors.danger, 'Under Review' => EpaColors.warning, 'Validated' => EpaColors.info, 'Resolved' => EpaColors.success, _ => EpaColors.textMuted };
  String _cropEmoji(String c) => switch (c.toLowerCase()) { String n when n.contains('maize') => '🌽', String n when n.contains('tomato') => '🍅', String n when n.contains('cocoa') => '🍫', String n when n.contains('cassava') => '🥔', _ => '🌾' };
}

class _OutbreakDetail extends StatelessWidget {
  final OutbreakSignal outbreak;
  final VoidCallback onValidate;
  const _OutbreakDetail({required this.outbreak, required this.onValidate});

  @override
  Widget build(BuildContext context) {
    final sColor = _severityColor(outbreak.severity);
    return EpaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_cropEmoji(outbreak.cropAffected), style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(outbreak.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Reported by ${outbreak.reportedBy}', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary)),
        ])),
        SeverityBadge(severity: outbreak.severity),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: sColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: sColor.withValues(alpha: 0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: sColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(outbreak.description, style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textPrimary, height: 1.5))),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: EpaInfoField(label: 'Crop Affected', value: outbreak.cropAffected, icon: Icons.eco)),
        const SizedBox(width: 12),
        Expanded(child: EpaInfoField(label: 'Location', value: outbreak.location, icon: Icons.location_on)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: EpaInfoField(label: 'Affected Farms', value: '${outbreak.affectedFarms} farms')),
        const SizedBox(width: 12),
        Expanded(child: EpaInfoField(label: 'Reported', value: DateFormat('MMM d, yyyy').format(outbreak.reportedAt))),
      ]),
      const SizedBox(height: 16),
      Text('Validation Actions', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        EpaButton(label: 'Validate Signal', icon: Icons.check_circle, onPressed: onValidate, color: EpaColors.success),
        EpaButton(label: 'Dispatch Response', icon: Icons.send, onPressed: () {}, color: EpaColors.primary),
        EpaButton(label: 'Request Field Visit', icon: Icons.map, outlined: true, onPressed: () {}),
        EpaButton(label: 'Escalate to HQ', icon: Icons.arrow_upward, outlined: true, color: EpaColors.danger, onPressed: () {}),
      ]),
    ]));
  }

  Color _severityColor(String s) => switch (s) { 'Critical' => EpaColors.danger, 'High' => EpaColors.warning, 'Medium' => EpaColors.amber, _ => EpaColors.success };
  String _cropEmoji(String c) => switch (c.toLowerCase()) { String n when n.contains('maize') => '🌽', String n when n.contains('tomato') => '🍅', String n when n.contains('cocoa') => '🍫', String n when n.contains('cassava') => '🥔', _ => '🌾' };
}

class _EmptyPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EpaCard(child: Center(child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: EpaColors.danger.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.warning_amber, size: 40, color: EpaColors.danger)),
        const SizedBox(height: 16),
        Text('Select an Outbreak Signal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EpaColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Choose a signal from the list to review and validate', style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary), textAlign: TextAlign.center),
      ]),
    )));
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaFarmerReportsScreen extends StatefulWidget {
  const EpaFarmerReportsScreen({super.key});
  @override State<EpaFarmerReportsScreen> createState() => _State();
}

class _State extends State<EpaFarmerReportsScreen> {
  String _search = '', _statusFilter = 'All';

  List<FarmerReport> get _filtered => EpaMockData.farmerReports.where((r) {
    final ms = r.farmerName.toLowerCase().contains(_search.toLowerCase()) || r.issue.toLowerCase().contains(_search.toLowerCase());
    final mf = _statusFilter == 'All' || r.status == _statusFilter;
    return ms && mf;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(title: 'Farmer Reports Monitoring', subtitle: 'Track and analyse farmer-reported agricultural issues').animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _ReportsPanel(filtered: _filtered, search: _search, statusFilter: _statusFilter, onSearch: (v) => setState(() => _search = v), onFilter: (v) => setState(() => _statusFilter = v))),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _CategoryChart()),
                ])
              : Column(children: [
                  _ReportsPanel(filtered: _filtered, search: _search, statusFilter: _statusFilter, onSearch: (v) => setState(() => _search = v), onFilter: (v) => setState(() => _statusFilter = v)),
                  const SizedBox(height: 20),
                  _CategoryChart(),
                ]);
        }).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  final List<FarmerReport> filtered;
  final String search, statusFilter;
  final ValueChanged<String> onSearch, onFilter;

  const _ReportsPanel({required this.filtered, required this.search, required this.statusFilter, required this.onSearch, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(flex: 2, child: EpaSearchBar(hint: 'Search reports...', onChanged: onSearch)),
        const SizedBox(width: 10),
        ...['All', 'Pending', 'In Progress', 'Resolved', 'Escalated'].map((f) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: _Chip(label: f, selected: statusFilter == f, onTap: () => onFilter(f)),
        )),
      ]),
      const SizedBox(height: 16),
      EpaCard(
        padding: EdgeInsets.zero,
        child: EpaDataTable(
          columns: const ['FARMER', 'ISSUE', 'CATEGORY', 'REGION', 'SEVERITY', 'STATUS', 'DATE'],
          rows: filtered.map((r) => [
            Text(r.farmerName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Flexible(child: Text(r.issue, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 2)),
            EpaBadge(label: r.category, color: _catColor(r.category)),
            Text(r.region, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
            SeverityBadge(severity: r.severity),
            EpaBadge(label: r.status, color: _statusColor(r.status)),
            Text(DateFormat('MMM d').format(r.submittedAt), style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textMuted)),
          ]).toList(),
        ),
      ),
    ]);
  }

  Color _catColor(String c) => switch (c) {
    'Pest Infestation' => EpaColors.danger, 'Nutrient Deficiency' => EpaColors.warning,
    'Weather Damage' => EpaColors.info, 'Soil Issue' => EpaColors.purple,
    'Water Management' => EpaColors.accent, _ => EpaColors.textMuted,
  };
  Color _statusColor(String s) => switch (s) {
    'Resolved' => EpaColors.success, 'In Progress' => EpaColors.info,
    'Escalated' => EpaColors.danger, 'Pending' => EpaColors.warning, _ => EpaColors.textMuted,
  };
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? EpaColors.primary.withValues(alpha: 0.1) : EpaColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? EpaColors.primary : EpaColors.divider),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? EpaColors.primary : EpaColors.textSecondary)),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = EpaMockData.reportCategories;
    final total = data.fold<int>(0, (s, d) => s + (d['count'] as int));
    return EpaCard(
      title: 'Report Categories',
      titleAction: Text('Total: $total', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary)),
      child: Column(children: [
        SizedBox(height: 180, child: PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 40,
          sections: data.map((d) => PieChartSectionData(
            value: (d['count'] as int).toDouble(),
            color: Color(d['color'] as int), radius: 50,
            title: '${((d['count'] as int) / total * 100).toInt()}%',
            titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          )).toList(),
        ))),
        const SizedBox(height: 12),
        ...data.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(d['color'] as int), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(d['category'] as String, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary))),
            Text('${d['count']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)),
          ]),
        )),
      ]),
    );
  }
}

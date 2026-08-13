import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaReportsScreen extends StatelessWidget {
  const EpaReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(
          title: 'EPA Summary Reports',
          subtitle: 'Agricultural intelligence reports and analytics for Ashanti Region',
          action: EpaButton(label: 'Export Report', icon: Icons.download, onPressed: () {}),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _SummaryCards().animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _WorkerPerformanceTable()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _OutbreakTrendChart()),
                ])
              : Column(children: [_WorkerPerformanceTable(), const SizedBox(height: 20), _OutbreakTrendChart()]);
        }).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),
        _ExportPanel().animate().fadeIn(delay: 300.ms),
      ]),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 900 ? 4 : 2;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 150),
        children: const [
          EpaStatCard(title: 'Total Recommendations', value: '532', subtitle: 'Across all advisors YTD', icon: Icons.recommend, gradient: EpaColors.gradientBlue, trend: '+23% vs last year', trendUp: true),
          EpaStatCard(title: 'Outbreaks Resolved', value: '18', subtitle: 'Out of 23 reported', icon: Icons.check_circle, gradient: EpaColors.gradientTeal, trend: '78% resolution rate', trendUp: true),
          EpaStatCard(title: 'Avg Response Time', value: '2.4d', subtitle: 'Days to first response', icon: Icons.timer, gradient: EpaColors.gradientAmber, trend: '-0.6d improvement', trendUp: true),
          EpaStatCard(title: 'Farmer Satisfaction', value: '87%', subtitle: 'Based on feedback surveys', icon: Icons.thumb_up, gradient: EpaColors.gradientGreen, trend: '+4% this quarter', trendUp: true),
        ],
      );
    });
  }
}

class _WorkerPerformanceTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EpaCard(
      title: 'Extension Worker Performance — June 2025',
      titleAction: EpaButton(label: 'Export CSV', icon: Icons.download, outlined: true, onPressed: () {}),
      padding: EdgeInsets.zero,
      child: EpaDataTable(
        columns: const ['WORKER', 'REGION', 'FARMERS', 'RECS', 'RESPONSE %', 'SCORE', 'RANK'],
        rows: EpaMockData.workers.asMap().entries.map((e) {
          final w = e.value;
          final rank = e.key + 1;
          return [
            Text(w.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(w.region, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
            Text('${w.activeFarmers}', style: GoogleFonts.inter(fontSize: 12)),
            Text('${w.recommendationsGiven}', style: GoogleFonts.inter(fontSize: 12)),
            Text('${w.responseRate}%', style: GoogleFonts.inter(fontSize: 12, color: w.responseRate >= 90 ? EpaColors.success : EpaColors.warning, fontWeight: FontWeight.w600)),
            Row(children: [
              Text('${w.performanceScore}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _scoreColor(w.performanceScore))),
              const SizedBox(width: 3),
              Icon(Icons.star, size: 11, color: _scoreColor(w.performanceScore)),
            ]),
            Container(width: 24, height: 24,
              decoration: BoxDecoration(color: rank <= 3 ? EpaColors.amber.withValues(alpha: 0.15) : EpaColors.divider, shape: BoxShape.circle),
              child: Center(child: Text('#$rank', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: rank <= 3 ? EpaColors.amber : EpaColors.textSecondary)))),
          ];
        }).toList(),
      ),
    );
  }

  Color _scoreColor(double s) => s >= 4.5 ? EpaColors.success : s >= 4.0 ? EpaColors.warning : EpaColors.danger;
}

class _OutbreakTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = EpaMockData.monthlyOutbreaks;
    return EpaCard(
      title: 'Outbreak Trend — 2025',
      child: SizedBox(
        height: 220,
        child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: EpaColors.divider, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: EpaColors.textMuted)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(data[v.toInt()]['month'] as String, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0, maxY: 10,
          lineBarsData: [LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble())).toList(),
            isCurved: true, color: EpaColors.danger, barWidth: 3,
            belowBarData: BarAreaData(show: true, color: EpaColors.danger.withValues(alpha: 0.08)),
            dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: EpaColors.danger, strokeWidth: 2, strokeColor: Colors.white)),
          )],
        )),
      ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EpaCard(
      title: 'Export Reports',
      child: Wrap(spacing: 12, runSpacing: 12, children: [
        _ExportCard(title: 'Monthly Summary Report', subtitle: 'June 2025 — All Districts', icon: Icons.summarize, color: EpaColors.primary),
        _ExportCard(title: 'Outbreak Incident Report', subtitle: '5 signals — Ashanti Region', icon: Icons.warning_amber, color: EpaColors.danger),
        _ExportCard(title: 'Worker Performance Report', subtitle: '6 extension workers evaluated', icon: Icons.people, color: EpaColors.accent),
        _ExportCard(title: 'Farmer Issues Analysis', subtitle: '129 reports — June 2025', icon: Icons.assignment, color: EpaColors.purple),
      ]),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  const _ExportCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: EpaColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
        const SizedBox(height: 12),
        Row(children: [
          EpaButton(label: 'PDF', icon: Icons.picture_as_pdf, outlined: true, color: color, onPressed: () {}),
          const SizedBox(width: 8),
          EpaButton(label: 'Excel', icon: Icons.table_chart, outlined: true, color: color, onPressed: () {}),
        ]),
      ]),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaDashboardScreen extends StatelessWidget {
  const EpaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CommandBanner().animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _StatsGrid().animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 24),
        _AlertsAndChart().animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 24),
        _BottomRow().animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _CommandBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF0D3B6E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting, Dr. Agyeman', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 6),
          Text('EPA Agricultural Intelligence Dashboard', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()), style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 8, children: [
            _BannerChip(icon: Icons.location_on, label: 'Ashanti Region'),
            _BannerChip(icon: Icons.shield, label: 'EPA-ASH-001'),
            _BannerChip(icon: Icons.warning_amber, label: '2 Critical Alerts', color: EpaColors.danger),
          ]),
        ])),
        const SizedBox(width: 20),
        Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: EpaColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: EpaColors.danger.withValues(alpha: 0.4))),
            child: Column(children: [
              const Icon(Icons.warning_amber, color: EpaColors.danger, size: 28),
              const SizedBox(height: 6),
              Text('2', style: GoogleFonts.inter(color: EpaColors.danger, fontSize: 28, fontWeight: FontWeight.w800)),
              Text('Critical\nAlerts', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _BannerChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EpaColors.primaryLight;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 12),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(color: color != null ? c : Colors.white.withValues(alpha: 0.75), fontSize: 12)),
    ]);
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 2 : 1;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 150),
        children: const [
          EpaStatCard(title: 'Total Farmers Monitored', value: '223', subtitle: 'Across 6 districts', icon: Icons.people, gradient: EpaColors.gradientBlue, trend: '+12 this month', trendUp: true),
          EpaStatCard(title: 'Active Outbreak Signals', value: '5', subtitle: '2 critical, 1 high', icon: Icons.warning_amber, gradient: EpaColors.gradientRed, trend: '+2 this week', trendUp: false),
          EpaStatCard(title: 'Extension Workers', value: '6', subtitle: '5 active, 1 on leave', icon: Icons.badge, gradient: EpaColors.gradientTeal, trend: '93% avg response', trendUp: true),
          EpaStatCard(title: 'Reports This Month', value: '129', subtitle: 'Farmer issue reports', icon: Icons.assignment, gradient: EpaColors.gradientAmber, trend: '+18 vs last month', trendUp: false),
        ],
      );
    });
  }
}

class _AlertsAndChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final isWide = c.maxWidth > 800;
      return isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: _ActiveAlerts()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _OutbreakChart()),
            ])
          : Column(children: [_ActiveAlerts(), const SizedBox(height: 20), _OutbreakChart()]);
    });
  }
}

class _ActiveAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final critical = EpaMockData.outbreaks.where((o) => o.status == 'Unvalidated').toList();
    return EpaCard(
      title: 'Active Outbreak Signals',
      titleAction: EpaBadge(label: '${critical.length} Pending', color: EpaColors.danger),
      padding: EdgeInsets.zero,
      child: Column(children: critical.map((o) => Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: EpaColors.divider))),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: _severityColor(o.severity).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(Icons.warning_amber, color: _severityColor(o.severity), size: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.cropAffected, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)),
            Text(o.location, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              SeverityBadge(severity: o.severity),
              const SizedBox(width: 6),
              Text('${o.affectedFarms} farms', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textMuted)),
            ]),
          ])),
          EpaButton(label: 'Validate', onPressed: () {}, color: EpaColors.primary),
        ]),
      )).toList()),
    );
  }

  Color _severityColor(String s) => switch (s) {
    'Critical' => EpaColors.danger,
    'High'     => EpaColors.warning,
    'Medium'   => EpaColors.amber,
    _          => EpaColors.success,
  };
}

class _OutbreakChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = EpaMockData.monthlyOutbreaks;
    return EpaCard(
      title: 'Monthly Outbreak Signals — 2025',
      titleAction: EpaBadge(label: 'Ashanti Region', color: EpaColors.primary),
      child: SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => EpaColors.sidebarBg,
            getTooltipItem: (g, _, rod, __) => BarTooltipItem('${data[g.x]['month']}\n${rod.toY.toInt()} signals', GoogleFonts.inter(color: Colors.white, fontSize: 11)),
          )),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: EpaColors.textMuted)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(data[v.toInt()]['month'] as String, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: EpaColors.divider, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: (e.value['count'] as int).toDouble(), gradient: EpaColors.gradientBlue, width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
          ])).toList(),
        )),
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final isWide = c.maxWidth > 800;
      return isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _RegionalTable()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _ActivityFeed()),
            ])
          : Column(children: [_RegionalTable(), const SizedBox(height: 20), _ActivityFeed()]);
    });
  }
}

class _RegionalTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = EpaMockData.regionalActivity;
    return EpaCard(
      title: 'Regional Activity Overview',
      padding: EdgeInsets.zero,
      child: EpaDataTable(
        columns: const ['REGION', 'FARMERS', 'REPORTS', 'OUTBREAKS', 'SCORE'],
        rows: data.map((d) => [
          Text(d['region'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('${d['farmers']}', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary)),
          Text('${d['reports']}', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary)),
          d['outbreaks'] > 0
              ? EpaBadge(label: '${d['outbreaks']}', color: EpaColors.danger)
              : Text('0', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.success)),
          _ScoreBar(score: d['score'] as int),
        ]).toList(),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 85 ? EpaColors.success : score >= 70 ? EpaColors.warning : EpaColors.danger;
    return Row(children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: score / 100, backgroundColor: color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
      const SizedBox(width: 8),
      Text('$score', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _ActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final feed = EpaMockData.activityFeed;
    return EpaCard(
      title: 'Activity Feed',
      child: Column(children: feed.asMap().entries.map((e) => EpaActivityItem(
        time: e.value['time'] as String,
        action: e.value['action'] as String,
        detail: e.value['detail'] as String,
        icon: e.value['icon'] as String,
        color: Color(e.value['color'] as int),
        isLast: e.key == feed.length - 1,
      )).toList()),
    );
  }
}

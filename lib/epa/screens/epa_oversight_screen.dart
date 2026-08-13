import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaOversightScreen extends StatelessWidget {
  const EpaOversightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(
          title: 'Recommendation Oversight',
          subtitle: 'Audit advisor recommendations for consistency and quality control',
          action: EpaBadge(label: '2 Flagged', color: EpaColors.danger),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _AuditTable()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _OversightPanel()),
                ])
              : Column(children: [_AuditTable(), const SizedBox(height: 20), _OversightPanel()]);
        }).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }
}

class _AuditTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = EpaMockData.recommendationAudit;
    return EpaCard(
      title: 'Recommendation Audit Log',
      titleAction: EpaButton(label: 'Export', icon: Icons.download, outlined: true, onPressed: () {}),
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(color: Color(0xFFF0F4F8), border: Border(bottom: BorderSide(color: EpaColors.divider))),
          child: Row(children: ['ADVISOR', 'CROP', 'FARMER', 'DATE', 'CONSISTENCY', 'FLAG']
            .map((h) => Expanded(child: Text(h, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: EpaColors.textSecondary, letterSpacing: 0.4)))).toList()),
        ),
        ...data.asMap().entries.map((e) {
          final d = e.value;
          final flagged = d['flag'] as bool;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: flagged ? EpaColors.danger.withValues(alpha: 0.03) : (e.key.isEven ? Colors.white : const Color(0xFFFAFBFC)),
              border: Border(bottom: const BorderSide(color: EpaColors.divider), left: flagged ? const BorderSide(color: EpaColors.danger, width: 3) : BorderSide.none),
            ),
            child: Row(children: [
              Expanded(child: Text(d['advisor'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              Expanded(child: Text(d['crop'] as String, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary))),
              Expanded(child: Text(d['farmer'] as String, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary), overflow: TextOverflow.ellipsis)),
              Expanded(child: Text(d['date'] as String, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textMuted))),
              Expanded(child: EpaBadge(label: d['consistency'] as String, color: _consistencyColor(d['consistency'] as String))),
              Expanded(child: flagged
                  ? Row(children: [const Icon(Icons.flag, color: EpaColors.danger, size: 16), const SizedBox(width: 4), Text('Flagged', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.danger, fontWeight: FontWeight.w600))])
                  : Row(children: [const Icon(Icons.check_circle, color: EpaColors.success, size: 16), const SizedBox(width: 4), Text('Clear', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.success))])),
            ]),
          );
        }),
      ]),
    );
  }

  Color _consistencyColor(String c) => switch (c) { 'Normal' => EpaColors.success, 'Anomaly' => EpaColors.danger, 'Review' => EpaColors.warning, _ => EpaColors.textMuted };
}

class _OversightPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      EpaCard(
        title: 'AI Anomaly Detection',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: EpaColors.danger.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: EpaColors.danger.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: EpaColors.danger, size: 16),
                const SizedBox(width: 8),
                Text('Anomaly Detected', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: EpaColors.danger)),
              ]),
              const SizedBox(height: 8),
              Text('Ms. Ama Owusu recommended Cocoa for a farm with Sandy Loam soil — inconsistent with standard cocoa soil requirements (Deep Forest Soil). Review recommended.', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textPrimary, height: 1.5)),
              const SizedBox(height: 10),
              EpaButton(label: 'Review Recommendation', icon: Icons.search, onPressed: () {}),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: EpaColors.warning.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: EpaColors.warning.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: EpaColors.warning, size: 16),
                const SizedBox(width: 8),
                Text('Under Review', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: EpaColors.warning)),
              ]),
              const SizedBox(height: 8),
              Text('Mr. Kofi Boateng recommended Plantain for a farm in a semi-arid zone. Rainfall data (420mm) is below the minimum threshold for plantain (1200mm).', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textPrimary, height: 1.5)),
              const SizedBox(height: 10),
              EpaButton(label: 'Review Recommendation', icon: Icons.search, outlined: true, color: EpaColors.warning, onPressed: () {}),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      EpaCard(
        title: 'Consistency Summary',
        child: Column(children: [
          _ConsistencyRow('Normal', 4, EpaColors.success),
          const SizedBox(height: 8),
          _ConsistencyRow('Under Review', 1, EpaColors.warning),
          const SizedBox(height: 8),
          _ConsistencyRow('Anomaly', 1, EpaColors.danger),
        ]),
      ),
    ]);
  }
}

class _ConsistencyRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _ConsistencyRow(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary))),
      Text('$count', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

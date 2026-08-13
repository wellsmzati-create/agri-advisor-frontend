import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaWorkersScreen extends StatefulWidget {
  const EpaWorkersScreen({super.key});
  @override State<EpaWorkersScreen> createState() => _EpaWorkersScreenState();
}

class _EpaWorkersScreenState extends State<EpaWorkersScreen> {
  String _search = '';
  ExtensionWorker? _selected;

  List<ExtensionWorker> get _filtered => EpaMockData.workers.where((w) =>
    w.name.toLowerCase().contains(_search.toLowerCase()) ||
    w.region.toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: _selected != null ? 3 : 1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EpaPageHeader(title: 'Extension Worker Monitoring', subtitle: '${EpaMockData.workers.length} workers across Ashanti Region').animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            EpaSearchBar(hint: 'Search by name or region...', onChanged: (v) => setState(() { _search = v; _selected = null; })).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            _WorkerTable(workers: _filtered, selected: _selected, onSelect: (w) => setState(() => _selected = _selected?.id == w.id ? null : w)).animate().fadeIn(delay: 200.ms),
          ]),
        ),
      ),
      if (_selected != null) ...[
        const VerticalDivider(width: 1, color: EpaColors.divider),
        SizedBox(width: 360, child: _WorkerDetail(worker: _selected!, onClose: () => setState(() => _selected = null)).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0)),
      ],
    ]);
  }
}

class _WorkerTable extends StatelessWidget {
  final List<ExtensionWorker> workers;
  final ExtensionWorker? selected;
  final ValueChanged<ExtensionWorker> onSelect;

  const _WorkerTable({required this.workers, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return EpaCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(color: Color(0xFFF0F4F8), border: Border(bottom: BorderSide(color: EpaColors.divider)), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: ['WORKER', 'REGION', 'FARMERS', 'RECS', 'RESPONSE', 'SCORE', 'STATUS', '']
            .map((h) => Expanded(child: Text(h, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: EpaColors.textSecondary, letterSpacing: 0.4)))).toList()),
        ),
        ...workers.asMap().entries.map((e) {
          final w = e.value;
          final isSelected = selected?.id == w.id;
          return GestureDetector(
            onTap: () => onSelect(w),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? EpaColors.primary.withValues(alpha: 0.05) : (e.key.isEven ? Colors.white : const Color(0xFFFAFBFC)),
                border: Border(bottom: const BorderSide(color: EpaColors.divider), left: isSelected ? const BorderSide(color: EpaColors.primary, width: 3) : BorderSide.none),
              ),
              child: Row(children: [
                Expanded(child: Row(children: [
                  EpaAvatar(initials: w.avatarInitials, size: 32, color: _avatarColor(w.id)),
                  const SizedBox(width: 10),
                  Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(w.specialization, style: GoogleFonts.inter(fontSize: 10, color: EpaColors.textMuted), overflow: TextOverflow.ellipsis),
                  ])),
                ])),
                Expanded(child: Text(w.region, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary))),
                Expanded(child: Text('${w.activeFarmers}', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary))),
                Expanded(child: Text('${w.recommendationsGiven}', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary))),
                Expanded(child: Text('${w.responseRate}%', style: GoogleFonts.inter(fontSize: 12, color: w.responseRate >= 90 ? EpaColors.success : EpaColors.warning, fontWeight: FontWeight.w600))),
                Expanded(child: Row(children: [
                  Text('${w.performanceScore}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _scoreColor(w.performanceScore))),
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 12, color: _scoreColor(w.performanceScore)),
                ])),
                Expanded(child: EpaBadge(label: w.status, color: _statusColor(w.status))),
                Expanded(child: IconButton(icon: const Icon(Icons.visibility_outlined, size: 16), color: EpaColors.textSecondary, onPressed: () => onSelect(w))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) { 'Active' => EpaColors.success, 'On Leave' => EpaColors.warning, _ => EpaColors.textMuted };
  Color _scoreColor(double s) => s >= 4.5 ? EpaColors.success : s >= 4.0 ? EpaColors.warning : EpaColors.danger;
  Color _avatarColor(String id) { final c = [EpaColors.primary, EpaColors.accent, EpaColors.purple, EpaColors.warning, EpaColors.success, EpaColors.info]; return c[id.hashCode % c.length]; }
}

class _WorkerDetail extends StatelessWidget {
  final ExtensionWorker worker;
  final VoidCallback onClose;
  const _WorkerDetail({required this.worker, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EpaColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Worker Profile', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClose, color: EpaColors.textSecondary),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: EpaColors.gradientBlue, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              EpaAvatar(initials: worker.avatarInitials, size: 52, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worker.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(worker.specialization, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 6),
                EpaBadge(label: worker.status, color: Colors.white, filled: true),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _MiniStat('Farmers', '${worker.activeFarmers}'),
            const SizedBox(width: 8),
            _MiniStat('Recs', '${worker.recommendationsGiven}'),
            const SizedBox(width: 8),
            _MiniStat('Response', '${worker.responseRate}%'),
          ]),
          const SizedBox(height: 16),
          EpaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Details', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            EpaInfoField(label: 'Email', value: worker.email, icon: Icons.email),
            const SizedBox(height: 8),
            EpaInfoField(label: 'Region', value: worker.region, icon: Icons.location_on),
            const SizedBox(height: 8),
            EpaInfoField(label: 'Last Active', value: DateFormat('MMM d, yyyy').format(worker.lastActive), icon: Icons.access_time),
            const SizedBox(height: 8),
            EpaInfoField(label: 'Performance Score', value: '${worker.performanceScore} / 5.0'),
          ])),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: EpaButton(label: 'Send Notice', icon: Icons.send, onPressed: () {})),
            const SizedBox(width: 10),
            EpaButton(label: 'Report', icon: Icons.bar_chart, outlined: true, onPressed: () {}),
          ]),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: EpaColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: EpaColors.divider)),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: EpaColors.textSecondary)),
      ]),
    ));
  }
}

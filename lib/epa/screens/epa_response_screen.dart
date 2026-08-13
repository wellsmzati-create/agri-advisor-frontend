import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaResponseScreen extends StatefulWidget {
  const EpaResponseScreen({super.key});
  @override State<EpaResponseScreen> createState() => _State();
}

class _State extends State<EpaResponseScreen> {
  bool _showCompose = false;
  ResponseAction? _selected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(
          title: 'Response Coordination',
          subtitle: 'Coordinate EPA-wide agricultural interventions and broadcasts',
          action: EpaButton(label: 'New Response Action', icon: Icons.add, onPressed: () => setState(() { _showCompose = true; _selected = null; })),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 800;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: _ActionList(actions: EpaMockData.responseActions, selected: _selected, onSelect: (a) => setState(() { _selected = a; _showCompose = false; }))),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _showCompose
                      ? _ComposePanel(onSave: () => setState(() => _showCompose = false), onCancel: () => setState(() => _showCompose = false))
                      : _selected != null ? _ActionDetail(action: _selected!) : _EmptyPanel()),
                ])
              : Column(children: [
                  _ActionList(actions: EpaMockData.responseActions, selected: _selected, onSelect: (a) => setState(() { _selected = a; _showCompose = false; })),
                  if (_showCompose) ...[const SizedBox(height: 20), _ComposePanel(onSave: () => setState(() => _showCompose = false), onCancel: () => setState(() => _showCompose = false))],
                  if (_selected != null) ...[const SizedBox(height: 20), _ActionDetail(action: _selected!)],
                ]);
        }).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }
}

class _ActionList extends StatelessWidget {
  final List<ResponseAction> actions;
  final ResponseAction? selected;
  final ValueChanged<ResponseAction> onSelect;

  const _ActionList({required this.actions, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return EpaCard(
      padding: EdgeInsets.zero,
      child: Column(children: actions.map((a) {
        final isSelected = selected?.id == a.id;
        return GestureDetector(
          onTap: () => onSelect(a),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? EpaColors.primary.withValues(alpha: 0.05) : Colors.white,
              border: Border(bottom: const BorderSide(color: EpaColors.divider), left: isSelected ? const BorderSide(color: EpaColors.primary, width: 3) : BorderSide.none),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                EpaBadge(label: a.priority, color: _priorityColor(a.priority)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                EpaBadge(label: a.type, color: EpaColors.primary),
                const SizedBox(width: 6),
                EpaBadge(label: a.status, color: _statusColor(a.status)),
                const Spacer(),
                Text(DateFormat('MMM d').format(a.createdAt), style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(a.targetRegion, style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Color _priorityColor(String p) => switch (p) { 'Critical' => EpaColors.danger, 'High' => EpaColors.warning, 'Medium' => EpaColors.amber, _ => EpaColors.textMuted };
  Color _statusColor(String s) => switch (s) { 'Active' => EpaColors.primary, 'Completed' => EpaColors.success, 'Sent' => EpaColors.accent, 'Scheduled' => EpaColors.purple, _ => EpaColors.textMuted };
}

class _ActionDetail extends StatelessWidget {
  final ResponseAction action;
  const _ActionDetail({required this.action});

  @override
  Widget build(BuildContext context) {
    return EpaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_typeIcon(action.type), color: EpaColors.primary, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(action.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(action.type, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary)),
        ])),
        EpaBadge(label: action.status, color: _statusColor(action.status)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: EpaColors.primary.withValues(alpha: 0.15))),
        child: Text(action.description, style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textPrimary, height: 1.5)),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: EpaInfoField(label: 'Target Region', value: action.targetRegion, icon: Icons.location_on)),
        const SizedBox(width: 12),
        Expanded(child: EpaInfoField(label: 'Priority', value: action.priority)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: EpaInfoField(label: 'Created By', value: action.createdBy, icon: Icons.person)),
        const SizedBox(width: 12),
        Expanded(child: EpaInfoField(label: 'Date', value: DateFormat('MMM d, yyyy').format(action.createdAt))),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [
        EpaButton(label: 'Update Status', icon: Icons.edit, onPressed: () {}),
        EpaButton(label: 'Broadcast', icon: Icons.campaign, outlined: true, onPressed: () {}),
        EpaButton(label: 'Close Action', icon: Icons.check, outlined: true, color: EpaColors.success, onPressed: () {}),
      ]),
    ]));
  }

  Color _statusColor(String s) => switch (s) { 'Active' => EpaColors.primary, 'Completed' => EpaColors.success, 'Sent' => EpaColors.accent, 'Scheduled' => EpaColors.purple, _ => EpaColors.textMuted };
  IconData _typeIcon(String t) => switch (t) { 'Intervention' => Icons.medical_services, 'Advisory' => Icons.lightbulb, 'Broadcast' => Icons.campaign, 'Campaign' => Icons.flag, _ => Icons.task };
}

class _ComposePanel extends StatelessWidget {
  final VoidCallback onSave, onCancel;
  const _ComposePanel({required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return EpaCard(
      title: 'New Response Action',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Field('Action Title', 'e.g. Emergency Pesticide Distribution'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Dropdown('Action Type', ['Intervention', 'Advisory', 'Broadcast', 'Campaign', 'Field Visit'])),
          const SizedBox(width: 12),
          Expanded(child: _Dropdown('Priority', ['Critical', 'High', 'Medium', 'Normal'])),
        ]),
        const SizedBox(height: 12),
        _Dropdown('Target Region', ['All Ashanti Districts', 'Kumasi Metro', 'Ejisu-Juaben', 'Bekwai Municipal', 'Obuasi Municipal', 'Mampong Municipal', 'Kwabre East']),
        const SizedBox(height: 12),
        _Field('Description', 'Describe the response action in detail...', maxLines: 5),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          EpaButton(label: 'Cancel', outlined: true, onPressed: onCancel),
          const SizedBox(width: 10),
          EpaButton(label: 'Save as Draft', icon: Icons.save, outlined: true, onPressed: onSave),
          const SizedBox(width: 10),
          EpaButton(label: 'Dispatch Now', icon: Icons.send, onPressed: onSave),
        ]),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  const _Field(this.label, this.hint, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpaColors.textSecondary)),
      const SizedBox(height: 5),
      TextField(maxLines: maxLines, style: GoogleFonts.inter(fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(fontSize: 13, color: EpaColors.textMuted))),
    ]);
  }
}

class _Dropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  const _Dropdown(this.label, this.items);
  @override State<_Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<_Dropdown> {
  String? _value;
  @override void initState() { super.initState(); _value = widget.items.first; }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpaColors.textSecondary)),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        value: _value,
        items: widget.items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _value = v),
        decoration: const InputDecoration(),
        style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textPrimary),
      ),
    ]);
  }
}

class _EmptyPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EpaCard(child: Center(child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.campaign, size: 40, color: EpaColors.primary)),
        const SizedBox(height: 16),
        Text('Select a Response Action', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EpaColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Choose an action to view details or create a new one', style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary), textAlign: TextAlign.center),
      ]),
    )));
  }
}

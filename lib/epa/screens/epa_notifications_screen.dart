import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';

class EpaNotificationsScreen extends StatefulWidget {
  const EpaNotificationsScreen({super.key});
  @override State<EpaNotificationsScreen> createState() => _State();
}

class _State extends State<EpaNotificationsScreen> {
  String _filter = 'All';
  final _notifs = List<EpaNotification>.from(EpaMockData.notifications);

  List<EpaNotification> get _filtered => _notifs.where((n) {
    if (_filter == 'All') return true;
    if (_filter == 'Unread') return !n.isRead;
    return n.type == _filter.toLowerCase();
  }).toList();

  void _markAllRead() => setState(() {
    for (int i = 0; i < _notifs.length; i++) {
      _notifs[i] = EpaNotification(id: _notifs[i].id, title: _notifs[i].title, body: _notifs[i].body, type: _notifs[i].type, priority: _notifs[i].priority, timestamp: _notifs[i].timestamp, isRead: true);
    }
  });

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.isRead).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EpaPageHeader(
          title: 'Notifications',
          subtitle: '$unread unread notifications',
          action: unread > 0 ? EpaButton(label: 'Mark All Read', icon: Icons.done_all, outlined: true, onPressed: _markAllRead) : null,
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (_, c) {
          final isWide = c.maxWidth > 900;
          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _NotifList(notifications: _filtered, filter: _filter, onFilter: (f) => setState(() => _filter = f), onMarkRead: (n) => setState(() {
                    final i = _notifs.indexWhere((x) => x.id == n.id);
                    if (i != -1) _notifs[i] = EpaNotification(id: n.id, title: n.title, body: n.body, type: n.type, priority: n.priority, timestamp: n.timestamp, isRead: true);
                  }))),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _NotifStats(notifications: _notifs)),
                ])
              : Column(children: [
                  _NotifList(notifications: _filtered, filter: _filter, onFilter: (f) => setState(() => _filter = f), onMarkRead: (_) {}),
                  const SizedBox(height: 20),
                  _NotifStats(notifications: _notifs),
                ]);
        }).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }
}

class _NotifList extends StatelessWidget {
  final List<EpaNotification> notifications;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<EpaNotification> onMarkRead;

  const _NotifList({required this.notifications, required this.filter, required this.onFilter, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: ['All', 'Unread', 'Outbreak', 'Report', 'Notice', 'Response', 'System'].map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _Chip(label: f, selected: filter == f, onTap: () => onFilter(f)),
        )).toList()),
      ),
      const SizedBox(height: 16),
      EpaCard(
        padding: EdgeInsets.zero,
        child: notifications.isEmpty
            ? Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No notifications', style: GoogleFonts.inter(color: EpaColors.textMuted))))
            : Column(children: notifications.map((n) => _NotifTile(notification: n, onMarkRead: () => onMarkRead(n))).toList()),
      ),
    ]);
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

class _NotifTile extends StatelessWidget {
  final EpaNotification notification;
  final VoidCallback onMarkRead;
  const _NotifTile({required this.notification, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final td = _typeData(notification.type);
    final color = td['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : color.withValues(alpha: 0.04),
        border: Border(bottom: const BorderSide(color: EpaColors.divider), left: notification.isRead ? BorderSide.none : BorderSide(color: color, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(child: Text(td['emoji'] as String, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notification.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700, color: EpaColors.textPrimary))),
            if (!notification.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: EpaColors.danger, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 4),
          Text(notification.body, style: GoogleFonts.inter(fontSize: 12, color: EpaColors.textSecondary, height: 1.4)),
          const SizedBox(height: 6),
          Row(children: [
            EpaBadge(label: notification.priority, color: _priorityColor(notification.priority)),
            const SizedBox(width: 8),
            Text(_timeAgo(notification.timestamp), style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textMuted)),
            const Spacer(),
            if (!notification.isRead) TextButton(onPressed: onMarkRead, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('Mark read', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.primary))),
          ]),
        ])),
      ]),
    );
  }

  Map<String, dynamic> _typeData(String t) => switch (t) {
    'outbreak' => {'emoji': '⚠️', 'color': EpaColors.danger},
    'report'   => {'emoji': '📊', 'color': EpaColors.info},
    'notice'   => {'emoji': '📢', 'color': EpaColors.warning},
    'response' => {'emoji': '🚨', 'color': EpaColors.accent},
    'system'   => {'emoji': '⚙️', 'color': EpaColors.textSecondary},
    _          => {'emoji': '📌', 'color': EpaColors.textMuted},
  };

  Color _priorityColor(String p) => switch (p) { 'Critical' => EpaColors.danger, 'High' => EpaColors.warning, 'Normal' => EpaColors.info, _ => EpaColors.textMuted };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return DateFormat('MMM d').format(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _NotifStats extends StatelessWidget {
  final List<EpaNotification> notifications;
  const _NotifStats({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).length;
    final byType = <String, int>{};
    for (final n in notifications) { byType[n.type] = (byType[n.type] ?? 0) + 1; }

    return Column(children: [
      EpaCard(title: 'Summary', child: Column(children: [
        _StatRow('Total', '${notifications.length}', EpaColors.textPrimary),
        const SizedBox(height: 8),
        _StatRow('Unread', '$unread', EpaColors.danger),
        const SizedBox(height: 8),
        _StatRow('Read', '${notifications.length - unread}', EpaColors.textSecondary),
      ])),
      const SizedBox(height: 16),
      EpaCard(title: 'By Type', child: Column(children: byType.entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(_typeEmoji(e.key), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(_capitalize(e.key), style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text('${e.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: EpaColors.primary))),
        ]),
      )).toList())),
      const SizedBox(height: 16),
      EpaCard(title: 'Quick Actions', child: Column(children: [
        SizedBox(width: double.infinity, child: EpaButton(label: 'Broadcast Alert', icon: Icons.campaign, onPressed: () {})),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: EpaButton(label: 'Schedule Notice', icon: Icons.schedule, outlined: true, onPressed: () {})),
      ])),
    ]);
  }

  String _typeEmoji(String t) => switch (t) { 'outbreak' => '⚠️', 'report' => '📊', 'notice' => '📢', 'response' => '🚨', 'system' => '⚙️', _ => '📌' };
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary)),
      Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

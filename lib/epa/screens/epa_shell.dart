import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../epa_theme.dart';
import '../epa_mock_data.dart';
import '../widgets/epa_widgets.dart';
import 'epa_dashboard_screen.dart';
import 'epa_workers_screen.dart';
import 'epa_farmer_reports_screen.dart';
import 'epa_outbreaks_screen.dart';
import 'epa_response_screen.dart';
import 'epa_reports_screen.dart';
import 'epa_oversight_screen.dart';
import 'epa_notifications_screen.dart';

class EpaShell extends StatefulWidget {
  const EpaShell({super.key});

  @override
  State<EpaShell> createState() => _EpaShellState();
}

class _EpaShellState extends State<EpaShell> {
  int _idx = 0;

  static const _items = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.people_outline, Icons.people, 'Extension Workers'),
    _NavItem(Icons.assignment_outlined, Icons.assignment, 'Farmer Reports'),
    _NavItem(Icons.warning_amber_outlined, Icons.warning_amber, 'Outbreak Signals'),
    _NavItem(Icons.campaign_outlined, Icons.campaign, 'Response Coordination'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'EPA Reports'),
    _NavItem(Icons.fact_check_outlined, Icons.fact_check, 'Rec. Oversight'),
    _NavItem(Icons.notifications_outlined, Icons.notifications, 'Notifications'),
  ];

  Widget get _screen => switch (_idx) {
    0 => const EpaDashboardScreen(),
    1 => const EpaWorkersScreen(),
    2 => const EpaFarmerReportsScreen(),
    3 => const EpaOutbreaksScreen(),
    4 => const EpaResponseScreen(),
    5 => const EpaReportsScreen(),
    6 => const EpaOversightScreen(),
    7 => const EpaNotificationsScreen(),
    _ => const EpaDashboardScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpaColors.pageBg,
      body: Row(children: [
        _EpaSidebar(items: _items, selectedIndex: _idx, onSelect: (i) => setState(() => _idx = i)),
        Expanded(child: Column(children: [
          _EpaTopBar(title: _items[_idx].label, onNotificationTap: () => setState(() => _idx = 7)),
          Expanded(child: _screen),
        ])),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _EpaSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _EpaSidebar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final officer = EpaMockData.currentOfficer;
    return Container(
      width: 240,
      color: EpaColors.sidebarBg,
      child: Column(children: [
        // Logo
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: EpaColors.primary, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.shield, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AgriAdvisor', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('EPA Portal', style: GoogleFonts.inter(color: EpaColors.sidebarText, fontSize: 10)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
              child: Text('EPA', style: GoogleFonts.inter(color: EpaColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w800))),
          ]),
        ),
        const Divider(color: Color(0xFF1B2E42), height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isActive = i == selectedIndex;
              final hasBadge = i == 3 || i == 7; // outbreaks & notifications
              return Tooltip(
                message: item.label,
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? EpaColors.sidebarActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isActive ? Border.all(color: EpaColors.primary.withValues(alpha: 0.3)) : null,
                    ),
                    child: Row(children: [
                      Icon(isActive ? item.activeIcon : item.icon,
                        color: isActive ? EpaColors.primaryLight : EpaColors.sidebarText, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.label,
                        style: GoogleFonts.inter(color: isActive ? Colors.white : EpaColors.sidebarText, fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))),
                      if (hasBadge)
                        Container(width: 16, height: 16,
                          decoration: BoxDecoration(color: i == 3 ? EpaColors.danger : EpaColors.warning, shape: BoxShape.circle),
                          child: Center(child: Text(i == 3 ? '2' : '3', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)))),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(color: Color(0xFF1B2E42), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            EpaAvatar(initials: officer.avatarInitials, size: 34, gradient: EpaColors.gradientBlue),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(officer.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text(officer.badge, style: GoogleFonts.inter(color: EpaColors.sidebarText, fontSize: 9)),
            ])),
            const Icon(Icons.more_vert, color: EpaColors.sidebarText, size: 16),
          ]),
        ),
      ]),
    );
  }
}

class _EpaTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onNotificationTap;

  const _EpaTopBar({required this.title, required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: EpaColors.topBarBg, border: Border(bottom: BorderSide(color: EpaColors.divider))),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shield, size: 13, color: EpaColors.primary),
            const SizedBox(width: 5),
            Text('EPA Officer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: EpaColors.primary)),
          ])),
        const SizedBox(width: 12),
        Flexible(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: EpaColors.textPrimary), overflow: TextOverflow.ellipsis)),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, minWidth: 80),
          child: EpaSearchBar(hint: 'Search...'),
        ),
        const SizedBox(width: 12),
        // Alert indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: EpaColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: EpaColors.danger.withValues(alpha: 0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: EpaColors.danger, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('2 Critical', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: EpaColors.danger)),
          ]),
        ),
        const SizedBox(width: 10),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 22, color: EpaColors.textSecondary), onPressed: onNotificationTap),
          Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: EpaColors.danger, shape: BoxShape.circle))),
        ]),
        const SizedBox(width: 4),
        if (w >= 900) Row(mainAxisSize: MainAxisSize.min, children: [
          EpaAvatar(initials: 'KA', size: 32, gradient: EpaColors.gradientBlue),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. Kofi Agyeman', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpaColors.textPrimary)),
            Text('EPA Officer', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: EpaColors.textSecondary),
        ]),
      ]),
    );
  }
}

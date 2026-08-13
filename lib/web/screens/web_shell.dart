import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../web_theme.dart';
import 'web_dashboard_screen.dart';
import 'web_farmers_screen.dart';
import 'web_crops_screen.dart';
import 'web_messages_screen.dart';
import 'web_notifications_screen.dart';
import 'web_recommendations_screen.dart';
import 'web_seasonal_screen.dart';
import 'web_tips_screen.dart';
import '../widgets/web_widgets.dart';

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Farmers'),
    _NavItem(icon: Icons.recommend_outlined, activeIcon: Icons.recommend, label: 'Recommendations'),
    _NavItem(icon: Icons.eco_outlined, activeIcon: Icons.eco, label: 'Crops'),
    _NavItem(icon: Icons.lightbulb_outline, activeIcon: Icons.lightbulb, label: 'Tips'),
    _NavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign, label: 'Seasonal'),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications'),
  ];

  Widget get _currentScreen => switch (_selectedIndex) {
    0 => const WebDashboardScreen(),
    1 => const WebFarmersScreen(),
    2 => const WebRecommendationsScreen(),
    3 => const WebCropsScreen(),
    4 => const WebTipsScreen(),
    5 => const WebSeasonalScreen(),
    6 => const WebMessagesScreen(),
    7 => const WebNotificationsScreen(),
    _ => const WebDashboardScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width < 1100;
    final collapsed = _sidebarCollapsed || isTablet;

    return Scaffold(
      backgroundColor: WebColors.pageBg,
      body: Row(
        children: [
          _Sidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            collapsed: collapsed,
            onSelect: (i) => setState(() => _selectedIndex = i),
            onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                   title: _navItems[_selectedIndex].label,
                   onMenuTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                   onNotificationTap: () => setState(() => _selectedIndex = 7),
                 ),
                Expanded(child: _currentScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.collapsed,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((auth) => auth.user);
    final advisorName = user?.name ?? 'Advisor';
    final advisorInitials = _initialsFor(advisorName);
    final w = collapsed ? 68.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      clipBehavior: Clip.hardEdge,
      color: WebColors.sidebarBg,
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 100;
              return SizedBox(
                height: 64,
                child: narrow
                    ? Center(
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: WebColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.eco, color: Colors.white, size: 18),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: WebColors.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.eco, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'AgriAdvisor',
                                style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
          const Divider(color: Color(0xFF1E2D3D), height: 1),
          const SizedBox(height: 8),

          // ── Nav items ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isActive = i == selectedIndex;
                return Tooltip(
                  message: collapsed ? item.label : '',
                  preferBelow: false,
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: _NavTile(
                      item: item,
                      isActive: isActive,
                      collapsed: collapsed,
                      showBadge: false,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: Color(0xFF1E2D3D), height: 1),

          // ── Advisor profile ───────────────────────────────────────────────
          LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 100;
              return SizedBox(
                height: 62,
                child: narrow
                    ? Center(
                        child: WebAvatar(
                          initials: advisorInitials,
                          size: 34,
                          gradient: WebColors.gradientGreen,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            WebAvatar(
                              initials: advisorInitials,
                              size: 34,
                              gradient: WebColors.gradientGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    advisorName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Senior Advisor',
                                    style: GoogleFonts.inter(
                                      color: WebColors.sidebarText, fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_vert, color: WebColors.sidebarText, size: 16),
                          ],
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _initialsFor(String value) => value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}

/// Separate stateless widget so the layout tree is clean and predictable.
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive, collapsed, showBadge;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? WebColors.sidebarActive : Colors.transparent;
    final iconColor = isActive ? WebColors.primaryLight : WebColors.sidebarText;
    final icon = Icon(
      isActive ? item.activeIcon : item.icon,
      color: iconColor,
      size: 20,
    );

    // Use LayoutBuilder so the tile reacts to the *actual* animated width,
    // not the boolean which flips instantly while the container still tweens.
    return LayoutBuilder(
      builder: (_, constraints) {
        final useCollapsed = constraints.maxWidth < 100;

        if (useCollapsed) {
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: icon),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: WebColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : WebColors.sidebarText,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: WebColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap, onNotificationTap;

  const _TopBar({
    required this.title,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((auth) => auth.user);
    final name = user?.name ?? 'Advisor';
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final useStackedSearch = maxWidth < 980;
        final showSearch = maxWidth >= 340;
        final showUserMeta = maxWidth >= 760;
        final horizontalPadding = maxWidth < 520 ? 12.0 : 24.0;

        final notificationButton = Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: WebColors.textSecondary,
              ),
              onPressed: onNotificationTap,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: WebColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );

        final searchBar = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: useStackedSearch ? double.infinity : 240,
            minWidth: useStackedSearch ? 0 : 120,
          ),
          child: const WebSearchBar(hint: 'Search farmers, crops...'),
        );

        final headerRow = Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, size: 20, color: WebColors.textSecondary),
              onPressed: onMenuTap,
              tooltip: 'Toggle sidebar',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WebColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            notificationButton,
            const SizedBox(width: 4),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _TopBarUserMenu(
                  initials: initials,
                  name: name,
                  showLabel: showUserMeta,
                ),
              ),
            ),
          ],
        );

        return Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            useStackedSearch ? 10 : 0,
            horizontalPadding,
            useStackedSearch ? 10 : 0,
          ),
          decoration: const BoxDecoration(
            color: WebColors.topBarBg,
            border: Border(bottom: BorderSide(color: WebColors.divider)),
          ),
          child: useStackedSearch
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 44, child: headerRow),
                    if (showSearch) ...[
                      const SizedBox(height: 10),
                      searchBar,
                    ],
                  ],
                )
              : SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      Expanded(child: headerRow),
                      const SizedBox(width: 16),
                      searchBar,
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _TopBarUserMenu extends StatelessWidget {
  final String initials;
  final String name;
  final bool showLabel;

  const _TopBarUserMenu({
    required this.initials,
    required this.name,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WebAvatar(
          initials: initials,
          size: 32,
          gradient: WebColors.gradientGreen,
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WebColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Senior Advisor',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: WebColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: WebColors.textSecondary,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../crops/recommendation_detail_screen.dart';
import '../history/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback so context.read is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FarmerProvider, AuthProvider>(
      builder: (_, farmer, auth, __) {
        if (farmer.dashboardLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (farmer.dashboardError != null && farmer.dashboard == null) {
          return _ErrorScaffold(
            message: farmer.dashboardError!,
            onRetry: () => farmer.loadDashboard(force: true),
          );
        }

        final db = farmer.dashboard;
        final userName = auth.user?.name ?? '';
        final userInitials = userName
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0])
            .take(2)
            .join()
            .toUpperCase();
        final farmLocation =
            db?.farms.isNotEmpty == true ? db!.farms.first.location : '';
        final farmSize =
            db?.farms.isNotEmpty == true ? db!.farms.first.sizeAcres.toInt() : 0;
        final recs = db?.activeRecommendations ?? const [];
        final tips = db?.recentTips ?? const [];
        final seasonalNotices = db?.seasonalNotices ?? const [];

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => farmer.loadDashboard(force: true),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration:
                          const BoxDecoration(gradient: AppColors.gradientGreen),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, kToolbarHeight + 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Good ${_greeting()}, 👋',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                              fontSize: 13)),
                                      Text(userName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold)),
                                      if (farmLocation.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.location_on,
                                              color: Colors.white70, size: 13),
                                          const SizedBox(width: 3),
                                          Text(farmLocation,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ]),
                                      ],
                                    ],
                                  ),
                                  AdvisorAvatar(
                                    initials: userInitials,
                                    size: 52,
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF1B5E20),
                                      Color(0xFF388E3C)
                                    ]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(children: [
                                _StatChip(
                                    label: '$farmSize Acres',
                                    icon: Icons.landscape),
                                const SizedBox(width: 10),
                                _StatChip(
                                    label: '${recs.length} Recommendations',
                                    icon: Icons.recommend),
                                const SizedBox(width: 10),
                                const _StatChip(
                                    label: 'Season Active',
                                    icon: Icons.wb_sunny),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: const Text('AgriAdvisor',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.primary,
                  actions: [
                    IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {}),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _WeatherBanner()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                        SectionHeader(
                          title: 'Recent Recommendations',
                          actionLabel: 'View History',
                          onAction: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen())),
                        ),
                        const SizedBox(height: 12),
                        if (recs.isEmpty)
                          const _EmptyCard(
                              message: 'No recommendations yet.')
                        else
                          ...recs.take(2).toList().asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RecommendationCard(rec: e.value)
                                      .animate(
                                          delay: Duration(
                                              milliseconds: 100 * e.key))
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: 0.05, end: 0),
                                ),
                              ),
                        const SizedBox(height: 8),
                        SectionHeader(
                            title: "Today's Farming Tips",
                            actionLabel: 'See All',
                            onAction: () {}),
                        const SizedBox(height: 12),
                        if (tips.isEmpty)
                          const _EmptyCard(message: 'No tips available.')
                        else
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: tips.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (ctx, i) =>
                                  _TipCard(tip: tips[i], index: i)
                                      .animate(
                                          delay: Duration(
                                              milliseconds: 80 * i))
                                      .fadeIn(duration: 400.ms),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'Seasonal Notifications'),
                        const SizedBox(height: 12),
                        if (seasonalNotices.isEmpty)
                          const _EmptyCard(
                            message:
                                'No seasonal notices have been published by your advisor yet.',
                          )
                        else
                          ...seasonalNotices.take(3).map((notice) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AlertCard(
                                  alert: {
                                    'icon': _seasonalIcon(notice.category),
                                    'title': notice.title,
                                    'body': notice.summary,
                                    'color': _seasonalColor(notice.category),
                                  },
                                ),
                              )),
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'Agricultural Updates'),
                        const SizedBox(height: 12),
                        ..._kAgriUpdates.map((u) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UpdateCard(update: u),
                            )),
                        const SizedBox(height: 24),
                      ],
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  // ignore: unused_field
  static const _kSeasonalAlerts = [
    {'icon': '🌧️', 'title': 'Heavy Rains Expected', 'body': 'Ensure field drainage.', 'color': AppColors.info},
    {'icon': '🌡️', 'title': 'High Temperature Alert', 'body': 'Irrigate morning/evening.', 'color': AppColors.warning},
  ];

  static String _seasonalIcon(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('pest')) return '!';
    if (normalized.contains('weather')) return '~';
    if (normalized.contains('government')) return '#';
    return '*';
  }

  static Color _seasonalColor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('pest')) return AppColors.warning;
    if (normalized.contains('weather')) return AppColors.info;
    if (normalized.contains('government')) return AppColors.primaryDark;
    return AppColors.primary;
  }

  static const _kAgriUpdates = [
    {'icon': '🏛️', 'title': 'Fertilizer Subsidy', 'body': 'Subsidized NPK & Urea available. Visit district office.'},
    {'icon': '📊', 'title': 'Maize Market Price Up 12%', 'body': 'Good time to sell.'},
    {'icon': '🌱', 'title': 'New Hybrid Seed Varieties', 'body': 'Drought-tolerant maize varieties for 2025 season.'},
  ];
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
          child: Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13))),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('⛅', style: TextStyle(fontSize: 44)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Local Weather',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const Text('28°C  •  Partly Cloudy',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.water_drop, color: Colors.white70, size: 14),
            SizedBox(width: 4),
            Text('72%', style: TextStyle(color: Colors.white, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.air, color: Colors.white70, size: 14),
            SizedBox(width: 4),
            Text('14 km/h', style: TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ]),
      ]),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CropRecommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => RecommendationDetailScreen(rec: rec))),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🌾', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rec.cropName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Text('By ${rec.advisorName}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(rec.season,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            StatusBadge(
              label: rec.status,
              color: rec.isPublished ? AppColors.success : AppColors.textSecondary,
            ),
          ]),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final FarmingTip tip;
  final int index;
  const _TipCard({required this.tip, required this.index});

  static const _gradients = [
    [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    [Color(0xFF5D4037), Color(0xFF8D6E63)],
    [Color(0xFF1565C0), Color(0xFF42A5F5)],
    [Color(0xFFE65100), Color(0xFFFF8A65)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10)),
          child: Text(tip.category,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        Text(tip.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        const Spacer(),
        Text(tip.authorName,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Text(alert['icon'] as String, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert['title'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: color)),
            const SizedBox(height: 3),
            Text(alert['body'] as String,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final Map<String, dynamic> update;
  const _UpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Text(update['icon'] as String, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(update['title'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 3),
              Text(update['body'] as String,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

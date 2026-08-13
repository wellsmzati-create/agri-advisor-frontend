import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const {};
  List<CropRecommendation> _recent = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await ApiService.advisorDashboard();
      final recentRaw = (summary['recent_recommendations'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recent = recentRaw.map(CropRecommendation.fromJson).toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = const {};
        _recent = const [];
        _error = 'Unable to load advisor dashboard data.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: WebColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              WebButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
              ),
            ],
          ),
        ),
      );
    }

    final farmerCount = (_summary['farmers'] as num?)?.toInt() ?? 0;
    final recommendationCount = (_summary['recommendations'] as num?)?.toInt() ?? 0;
    final tipCount = (_summary['tips'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Advisor Dashboard',
            subtitle: 'Live backend summary for your advisory workspace',
            action: WebButton(
              label: 'Refresh',
              icon: Icons.refresh,
              outlined: true,
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (_, constraints) {
              final columns = constraints.maxWidth > 980
                  ? 3
                  : constraints.maxWidth > 640
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  WebStatCard(
                    title: 'Farmers',
                    value: '$farmerCount',
                    subtitle: 'Managed farmer profiles',
                    icon: Icons.people,
                    gradient: WebColors.gradientGreen,
                  ),
                  WebStatCard(
                    title: 'Recommendations',
                    value: '$recommendationCount',
                    subtitle: 'Created through the backend',
                    icon: Icons.recommend,
                    gradient: WebColors.gradientBlue,
                  ),
                  WebStatCard(
                    title: 'Published Tips',
                    value: '$tipCount',
                    subtitle: 'Advisor knowledge base entries',
                    icon: Icons.lightbulb,
                    gradient: WebColors.gradientOrange,
                  ),
                ],
              );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 20),
          WebCard(
            title: 'Recent Recommendations',
            titleAction: WebBadge(
              label: '${_recent.length} recent',
              color: WebColors.primary,
            ),
            child: _recent.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No recommendations have been generated yet.',
                        style: GoogleFonts.inter(color: WebColors.textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: _recent.map((rec) => _RecommendationRow(rec: rec)).toList(),
                  ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 20),
          WebCard(
            title: 'Backend Notes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  icon: Icons.storage,
                  text: 'This dashboard is now reading counts directly from the Laravel backend.',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.timelapse,
                  text: 'Recommendation generation may stay pending until the backend queue worker is running.',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.settings_input_antenna,
                  text: 'Use a running backend host and the correct API base URL for login and refresh to succeed.',
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final CropRecommendation rec;

  const _RecommendationRow({required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = switch (rec.status) {
      'published' => WebColors.primary,
      'generated' => WebColors.info,
      'pending' => WebColors.warning,
      _ => WebColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WebColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.eco, color: WebColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.cropName.isEmpty ? 'Pending recommendation' : rec.cropName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WebColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.reason.isEmpty ? 'Waiting for the backend job to finish.' : rec.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          WebBadge(label: rec.status, color: color),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: WebColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: WebColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

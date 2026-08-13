import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../crops/recommendation_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.recsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (provider.recsError != null && provider.recommendations.isEmpty) {
          return Scaffold(
            appBar: GradientAppBar(title: 'Recommendation History', showBack: true),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.recsError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          provider.loadRecommendations(force: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final recs = provider.recommendations;
        return Scaffold(
          appBar: GradientAppBar(title: 'Recommendation History', showBack: true),
          body: RefreshIndicator(
            onRefresh: () => provider.loadRecommendations(force: true),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    _SummaryChip(label: 'Total', value: '${recs.length}', color: AppColors.primary),
                    const SizedBox(width: 10),
                    _SummaryChip(label: 'Published', value: '${recs.where((r) => r.isPublished).length}', color: AppColors.success),
                    const SizedBox(width: 10),
                    _SummaryChip(label: 'Pending', value: '${recs.where((r) => r.status == 'pending').length}', color: AppColors.textSecondary),
                  ]),
                ),
                Expanded(
                  child: recs.isEmpty
                      ? const EmptyState(emoji: '📋', title: 'No recommendations yet', subtitle: 'Your advisor recommendations will appear here')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: recs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final rec = recs[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => RecommendationDetailScreen(rec: rec))),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                        child: const Center(child: Text('🌾', style: TextStyle(fontSize: 22))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(rec.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(DateFormat('MMMM d, yyyy').format(rec.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ])),
                                      StatusBadge(label: rec.status, color: rec.isPublished ? AppColors.success : AppColors.textSecondary),
                                    ]),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(rec.advisorName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text(rec.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      _Tag(icon: Icons.landscape, label: rec.soilType),
                                      const SizedBox(width: 8),
                                      _Tag(icon: Icons.water_drop, label: rec.rainfall),
                                      const Spacer(),
                                      const Text('View Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                      const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                                    ]),
                                  ]),
                                ),
                              ),
                            ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
                          },
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

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

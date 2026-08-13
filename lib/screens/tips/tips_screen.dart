import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String _selectedFilter = 'All';

  static const _filters = [
    'All', 'Soil Management', 'Planting Calendar',
    'Pest Management', 'Water Management', 'Post-Harvest',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadTips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.tipsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final allTips = provider.tips;
        final filtered = _selectedFilter == 'All'
            ? allTips
            : allTips.where((t) => t.category == _selectedFilter).toList();

        return Scaffold(
          appBar: GradientAppBar(title: 'Farming Tips'),
          body: RefreshIndicator(
            onRefresh: () => provider.loadTips(force: true),
            child: Column(
              children: [
                _FeaturedBanner(tip: allTips.isNotEmpty ? allTips.first : null),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final sel = f == _selectedFilter;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.divider),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          emoji: '💡',
                          title: 'No tips in this category',
                          subtitle: 'Check back soon for new tips',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _TipCard(tip: filtered[i])
                              .animate(
                                  delay: Duration(milliseconds: 80 * i))
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.05, end: 0),
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

class _FeaturedBanner extends StatelessWidget {
  final FarmingTip? tip;
  const _FeaturedBanner({this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('⭐ Featured Tip',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Text(
              tip?.title ?? 'Soil Testing: The Foundation of Good Farming',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test your soil before every planting season for best results.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Read More',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        const Text('🌱', style: TextStyle(fontSize: 64)),
      ]),
    );
  }
}

class _TipCard extends StatefulWidget {
  final FarmingTip tip;
  const _TipCard({required this.tip});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _CategoryChip(label: widget.tip.category, color: AppColors.primary),
              const SizedBox(width: 8),
              _CategoryChip(label: widget.tip.season, color: AppColors.accent),
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ]),
            const SizedBox(height: 10),
            Text(widget.tip.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, height: 1.3)),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: Text(widget.tip.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              secondChild: Text(widget.tip.content,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 12),
            Row(children: [
              AdvisorAvatar(
                initials: widget.tip.authorName
                    .split(' ')
                    .map((w) => w.isEmpty ? '' : w[0])
                    .take(2)
                    .join(),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(widget.tip.authorName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(DateFormat('MMM d').format(widget.tip.publishedAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

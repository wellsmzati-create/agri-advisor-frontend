import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final CropRecommendation rec;
  const RecommendationDetailScreen({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradientGreen),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text('🌾', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 8),
                      Text(
                        rec.cropName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: rec.status,
                        color: rec.status == 'Active' ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, yyyy').format(rec.date),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AdvisorAvatar(initials: rec.advisorName.split(' ').map((w) => w[0]).take(2).join()),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rec.advisorName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const Text('Agricultural Advisor',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Text('Why This Crop?',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(rec.reason,
                              style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Suitable Conditions',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          InfoRow(icon: Icons.landscape, label: 'Soil Type', value: rec.soilType),
                          InfoRow(icon: Icons.wb_sunny, label: 'Season', value: rec.season),
                          InfoRow(icon: Icons.water_drop, label: 'Rainfall', value: rec.rainfall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step-by-Step Farming Guide',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 14),
                          ...rec.steps.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.gradientGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(e.value,
                                          style: const TextStyle(fontSize: 13, height: 1.5)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

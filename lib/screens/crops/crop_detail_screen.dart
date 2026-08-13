import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CropDetailScreen extends StatelessWidget {
  final Crop crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
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
                      Text(crop.imageEmoji, style: const TextStyle(fontSize: 80))
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 8),
                      Text(
                        crop.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
                      StatusBadge(label: crop.category, color: AppColors.primary),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: '${crop.growthDays} days to harvest',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(crop.description,
                      style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  _InfoCard(
                    title: 'Growing Conditions',
                    children: [
                      InfoRow(icon: Icons.landscape, label: 'Soil Type', value: crop.soilType),
                      InfoRow(icon: Icons.wb_sunny, label: 'Climate', value: crop.climate),
                      InfoRow(icon: Icons.water_drop, label: 'Rainfall', value: crop.rainfall),
                      InfoRow(icon: Icons.thermostat, label: 'Temperature', value: crop.temperature),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StepsCard(
                    title: '🌱 Planting Instructions',
                    steps: crop.plantingSteps,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  _StepsCard(
                    title: '🔧 Maintenance Tips',
                    steps: crop.maintenanceTips,
                    color: AppColors.secondary,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String title;
  final List<String> steps;
  final Color color;
  const _StepsCard({required this.title, required this.steps, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
    );
  }
}

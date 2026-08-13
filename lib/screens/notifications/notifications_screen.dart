import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.notifLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final notifications = provider.notifications;
        final unread = provider.unreadCount;
        final now = DateTime.now();

        final today = notifications
            .where((n) => now.difference(n.timestamp).inDays == 0)
            .toList();
        final thisWeek = notifications.where((n) {
          final d = now.difference(n.timestamp).inDays;
          return d > 0 && d <= 7;
        }).toList();
        final older = notifications
            .where((n) => now.difference(n.timestamp).inDays > 7)
            .toList();

        return Scaffold(
          appBar: GradientAppBar(
            title: 'Notifications',
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: provider.markAllRead,
                  child: const Text('Mark all read',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadNotifications(force: true),
            child: notifications.isEmpty
                ? const EmptyState(
                    emoji: '🔔',
                    title: 'No notifications',
                    subtitle: 'You are all caught up!',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.notifications_active,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '$unread unread notification${unread > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ]),
                        ),
                      if (today.isNotEmpty) ...[
                        const _GroupHeader(label: 'Today'),
                        ...today.asMap().entries.map((e) =>
                            _NotificationCard(
                              notification: e.value,
                              onTap: () => provider.markRead(e.value.id),
                            )
                                .animate(
                                    delay: Duration(milliseconds: 60 * e.key))
                                .fadeIn(duration: 300.ms)),
                        const SizedBox(height: 8),
                      ],
                      if (thisWeek.isNotEmpty) ...[
                        const _GroupHeader(label: 'This Week'),
                        ...thisWeek.asMap().entries.map((e) =>
                            _NotificationCard(
                              notification: e.value,
                              onTap: () => provider.markRead(e.value.id),
                            )
                                .animate(
                                    delay: Duration(milliseconds: 60 * e.key))
                                .fadeIn(duration: 300.ms)),
                        const SizedBox(height: 8),
                      ],
                      if (older.isNotEmpty) ...[
                        const _GroupHeader(label: 'Earlier'),
                        ...older.asMap().entries.map((e) =>
                            _NotificationCard(
                              notification: e.value,
                              onTap: () => provider.markRead(e.value.id),
                            )
                                .animate(
                                    delay: Duration(milliseconds: 60 * e.key))
                                .fadeIn(duration: 300.ms)),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5)),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
        'recommendation' => Icons.recommend,
        'alert' => Icons.warning_amber_rounded,
        'message' => Icons.chat_bubble,
        'tip' => Icons.lightbulb,
        'reminder' => Icons.alarm,
        'notice' => Icons.campaign,
        _ => Icons.notifications,
      };

  Color get _color => switch (notification.type) {
        'recommendation' => AppColors.primary,
        'alert' => AppColors.warning,
        'message' => AppColors.info,
        'tip' => AppColors.accent,
        'reminder' => AppColors.secondary,
        'notice' => AppColors.earthBrown,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: notification.isRead ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : _color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: notification.isRead
                  ? AppColors.divider
                  : _color.withOpacity(0.3)),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                      color: _color.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14)),
                      ),
                      if (!notification.isRead)
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _color, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 4),
                    Text(notification.body,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                    const SizedBox(height: 6),
                    Text(_formatTime(notification.timestamp),
                        style: TextStyle(
                            fontSize: 11, color: _color.withOpacity(0.7))),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

class WebNotificationsScreen extends StatefulWidget {
  const WebNotificationsScreen({super.key});

  @override
  State<WebNotificationsScreen> createState() => _WebNotificationsScreenState();
}

class _WebNotificationsScreenState extends State<WebNotificationsScreen> {
  static const _notificationRefreshInterval = Duration(seconds: 6);

  Timer? _refreshTimer;
  bool _loading = true;
  bool _broadcasting = false;
  String _filter = 'All';
  String? _error;

  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      _notificationRefreshInterval,
      (_) {
        if (!mounted) return;
        _load(silent: true);
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }

    try {
      final notifications = await ApiService.advisorNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _error = 'Unable to load advisor notifications from the backend.';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await ApiService.markAdvisorNotificationRead(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map(
              (item) => item.id == notification.id
                  ? item.copyWith(isRead: true)
                  : item,
            )
            .toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark the notification as read.')),
      );
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((item) => !item.isRead).toList();
    if (unread.isEmpty) return;

    try {
      await Future.wait(
        unread.map((notification) => ApiService.markAdvisorNotificationRead(notification.id)),
      );
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.map((item) => item.copyWith(isRead: true)).toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark all notifications as read.')),
      );
    }
  }

  Future<void> _broadcast() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _BroadcastDialog(),
    );
    if (!mounted || payload == null) return;

    setState(() => _broadcasting = true);

    try {
      final sent = await ApiService.broadcastAdvisorNotification(payload);
      if (!mounted) return;
      setState(() => _broadcasting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Broadcast sent to $sent user${sent == 1 ? '' : 's'}.')),
      );
      await _load(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _broadcasting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _broadcasting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send the broadcast notification.')),
      );
    }
  }

  List<AppNotification> get _filtered {
    return _notifications.where((notification) {
      if (_filter == 'All') return true;
      if (_filter == 'Unread') return !notification.isRead;
      return notification.type == _filter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _notifications.isEmpty) {
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
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Notifications',
            subtitle: '$unreadCount unread notifications',
            action: Row(
              children: [
                WebButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: () => _load(),
                ),
                const SizedBox(width: 10),
                WebButton(
                  label: _broadcasting ? 'Sending...' : 'Broadcast',
                  icon: Icons.campaign,
                  onPressed: _broadcasting ? null : _broadcast,
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 10),
                  WebButton(
                    label: 'Mark All Read',
                    icon: Icons.done_all,
                    outlined: true,
                    onPressed: _markAllRead,
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth > 900;
              final list = _NotificationList(
                notifications: _filtered,
                filter: _filter,
                onFilter: (value) => setState(() => _filter = value),
                onMarkRead: _markRead,
              );
              final stats = _NotificationStats(notifications: _notifications);

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: list),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: stats),
                      ],
                    )
                  : Column(
                      children: [
                        list,
                        const SizedBox(height: 20),
                        stats,
                      ],
                    );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 280.ms),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<AppNotification> onMarkRead;

  const _NotificationList({
    required this.notifications,
    required this.filter,
    required this.onFilter,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Unread', 'Recommendation', 'Tip', 'Message', 'Notice']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: value,
                      selected: filter == value,
                      onTap: () => onFilter(value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        WebCard(
          padding: EdgeInsets.zero,
          child: notifications.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No notifications match the current filter.',
                      style: GoogleFonts.inter(color: WebColors.textMuted),
                    ),
                  ),
                )
              : Column(
                  children: notifications
                      .map(
                        (notification) => _NotificationTile(
                          notification: notification,
                          onMarkRead: () => onMarkRead(notification),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? WebColors.primary.withValues(alpha: 0.1)
              : WebColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? WebColors.primary : WebColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? WebColors.primary : WebColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final type = _notificationTypeData(notification.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : (type['color'] as Color).withValues(alpha: 0.04),
        border: Border(
          bottom: const BorderSide(color: WebColors.divider),
          left: notification.isRead
              ? BorderSide.none
              : BorderSide(color: type['color'] as Color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (type['color'] as Color).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                type['icon'] as IconData,
                color: type['color'] as Color,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: WebColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: WebColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    WebBadge(label: notification.type, color: type['color'] as Color),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(notification.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: WebColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      TextButton(
                        onPressed: onMarkRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mark read',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: WebColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationStats extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationStats({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((item) => !item.isRead).length;
    final byType = <String, int>{};
    for (final notification in notifications) {
      byType[notification.type] = (byType[notification.type] ?? 0) + 1;
    }

    return Column(
      children: [
        WebCard(
          title: 'Summary',
          child: Column(
            children: [
              _StatRow(
                label: 'Total',
                value: '${notifications.length}',
                color: WebColors.textPrimary,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: 'Unread',
                value: '$unread',
                color: WebColors.primary,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: 'Read',
                value: '${notifications.length - unread}',
                color: WebColors.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WebCard(
          title: 'By Type',
          child: Column(
            children: byType.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          _notificationTypeData(entry.key)['icon'] as IconData,
                          size: 16,
                          color: _notificationTypeData(entry.key)['color'] as Color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _capitalize(entry.key),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: WebColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: WebColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WebColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        WebCard(
          title: 'Flow',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(
                icon: Icons.chat_bubble_outline,
                text: 'Farmer replies now create advisor message notifications.',
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.lightbulb_outline,
                text: 'Published tips can notify farmers and appear in the mobile tips feed.',
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.notifications_active_outlined,
                text: 'Broadcast notices can be sent directly to farmer accounts from this screen.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog();

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'notice';
  String _role = 'farmer';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'title': _titleController.text.trim(),
      'body': _bodyController.text.trim(),
      'type': _type,
      'role': _role,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Broadcast Notification'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                validator: _required,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                validator: _required,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'notice', child: Text('Notice')),
                  DropdownMenuItem(value: 'alert', child: Text('Alert')),
                  DropdownMenuItem(value: 'tip', child: Text('Tip')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'farmer', child: Text('Farmers')),
                  DropdownMenuItem(value: 'advisor', child: Text('Advisors')),
                  DropdownMenuItem(value: 'epa', child: Text('EPA')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Audience'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _notificationTypeData(String type) {
  switch (type) {
    case 'recommendation':
      return {'icon': Icons.agriculture, 'color': WebColors.primary};
    case 'alert':
      return {'icon': Icons.warning_amber_rounded, 'color': WebColors.warning};
    case 'message':
      return {'icon': Icons.chat_bubble_outline, 'color': WebColors.info};
    case 'tip':
      return {'icon': Icons.lightbulb_outline, 'color': WebColors.accent};
    case 'reminder':
      return {
        'icon': Icons.notifications_active_outlined,
        'color': WebColors.purple,
      };
    case 'notice':
      return {'icon': Icons.campaign_outlined, 'color': WebColors.danger};
    default:
      return {'icon': Icons.push_pin_outlined, 'color': WebColors.textSecondary};
  }
}

// ignore: unused_element
Map<String, dynamic> _typeData(String type) {
  switch (type) {
    case 'recommendation':
      return {'emoji': '🌾', 'color': WebColors.primary};
    case 'alert':
      return {'emoji': '⚠️', 'color': WebColors.warning};
    case 'message':
      return {'emoji': '💬', 'color': WebColors.info};
    case 'tip':
      return {'emoji': '💡', 'color': WebColors.accent};
    case 'reminder':
      return {'emoji': '🔔', 'color': WebColors.purple};
    case 'notice':
      return {'emoji': '📢', 'color': WebColors.danger};
    default:
      return {'emoji': '📌', 'color': WebColors.textSecondary};
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 7) return DateFormat('MMM d').format(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'now';
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';
import 'chat_screen.dart';

class AdvisorsScreen extends StatefulWidget {
  const AdvisorsScreen({super.key});

  @override
  State<AdvisorsScreen> createState() => _AdvisorsScreenState();
}

class _AdvisorsScreenState extends State<AdvisorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, provider, __) {
        if (provider.convsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final conversations = provider.conversations;

        return Scaffold(
          appBar: GradientAppBar(title: 'My Advisors'),
          body: RefreshIndicator(
            onRefresh: () => provider.loadConversations(force: true),
            child: conversations.isEmpty
                ? const EmptyState(
                    emoji: '💬',
                    title: 'No conversations yet',
                    subtitle: 'Your advisor conversations will appear here',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.verified_user,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Expert Agricultural Advisors',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${conversations.length} active conversation${conversations.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      const Text('Conversations',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...conversations.asMap().entries.map(
                            (e) => _ConversationTile(conversation: e.value)
                                .animate(
                                    delay:
                                        Duration(milliseconds: 80 * e.key))
                                .fadeIn(duration: 350.ms)
                                .slideX(begin: 0.05, end: 0),
                          ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AdvisorAvatar(initials: conversation.advisorInitials),
        title: Text(conversation.advisorName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: last != null
            ? Text(last.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))
            : const Text('No messages yet',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
        trailing: conversation.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ChatScreen(conversation: conversation)),
        ),
      ),
    );
  }
}

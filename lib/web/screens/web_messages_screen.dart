import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../web_theme.dart';
import '../widgets/web_widgets.dart';

Future<void> showAdvisorConversationDialog(
  BuildContext context, {
  required String conversationId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1080,
        height: 720,
        child: AdvisorMessagesWorkspace(
          initialConversationId: conversationId,
        ),
      ),
    ),
  );
}

class WebMessagesScreen extends StatelessWidget {
  const WebMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Messages',
            subtitle:
                'Review advisor conversations and respond to farmers in real time.',
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 24),
          const Expanded(
            child: AdvisorMessagesWorkspace(),
          ).animate().fadeIn(delay: 100.ms, duration: 280.ms),
        ],
      ),
    );
  }
}

class AdvisorMessagesWorkspace extends StatefulWidget {
  final String? initialConversationId;

  const AdvisorMessagesWorkspace({
    super.key,
    this.initialConversationId,
  });

  @override
  State<AdvisorMessagesWorkspace> createState() =>
      _AdvisorMessagesWorkspaceState();
}

class _AdvisorMessagesWorkspaceState extends State<AdvisorMessagesWorkspace> {
  static const _messageRefreshInterval = Duration(seconds: 6);

  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  List<Conversation> _conversations = const [];
  List<ChatMessage> _messages = const [];
  Conversation? _selected;

  bool _loadingConversations = true;
  bool _loadingMessages = false;
  bool _sending = false;
  String _query = '';
  String? _error;
  String? _messagesError;

  @override
  void initState() {
    super.initState();
    _loadConversations(initialConversationId: widget.initialConversationId);
    _refreshTimer = Timer.periodic(
      _messageRefreshInterval,
      (_) {
        if (!mounted) return;
        _loadConversations(
          initialConversationId: _selected?.id ?? widget.initialConversationId,
        );
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({String? initialConversationId}) async {
    try {
      final conversations = await ApiService.advisorConversations();
      conversations.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

      Conversation? selected;
      if (initialConversationId != null) {
        for (final conversation in conversations) {
          if (conversation.id == initialConversationId) {
            selected = conversation;
            break;
          }
        }
      }
      selected ??= _selected == null
          ? (conversations.isNotEmpty ? conversations.first : null)
          : _findConversation(conversations, _selected!.id);

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _selected = selected;
        _loadingConversations = false;
        _error = null;
      });

      if (selected != null) {
        await _loadMessages(selected);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _conversations = const [];
        _selected = null;
        _loadingConversations = false;
        _error = 'Unable to load advisor conversations from the backend.';
      });
    }
  }

  Conversation? _findConversation(
    List<Conversation> conversations,
    String conversationId,
  ) {
    for (final conversation in conversations) {
      if (conversation.id == conversationId) return conversation;
    }
    return conversations.isNotEmpty ? conversations.first : null;
  }

  Future<void> _loadMessages(Conversation conversation) async {
    setState(() {
      _selected = conversation;
      _loadingMessages = true;
      _messagesError = null;
    });

    try {
      final messages = await ApiService.advisorConversationMessages(conversation.id);
      if (!mounted) return;

      final updatedConversation = conversation.copyWith(
        unreadCount: 0,
        lastMessage: messages.isNotEmpty ? messages.last : conversation.lastMessage,
        updatedAt: messages.isNotEmpty ? messages.last.timestamp : conversation.updatedAt,
      );

      setState(() {
        _messages = messages;
        _selected = updatedConversation;
        _conversations = _conversations
            .map((item) => item.id == conversation.id ? updatedConversation : item)
            .toList()
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
        _loadingMessages = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages = const [];
        _loadingMessages = false;
        _messagesError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = const [];
        _loadingMessages = false;
        _messagesError = 'Unable to load conversation messages.';
      });
    }
  }

  Future<void> _send() async {
    final conversation = _selected;
    final text = _composerController.text.trim();
    if (conversation == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _composerController.clear();

    try {
      final sent = await ApiService.advisorSendMessage(conversation.id, text);
      if (!mounted) return;

      final updatedConversation = conversation.copyWith(
        unreadCount: 0,
        lastMessage: sent,
        updatedAt: sent.timestamp,
      );

      setState(() {
        _messages = [..._messages, sent];
        _selected = updatedConversation;
        _conversations = [
          updatedConversation,
          ..._conversations.where((item) => item.id != updatedConversation.id),
        ];
        _sending = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send the message.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 40,
                color: WebColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: WebColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              WebButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () {
                  setState(() => _loadingConversations = true);
                  _loadConversations(
                    initialConversationId: widget.initialConversationId,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final filteredConversations = _conversations.where((conversation) {
      final value = _query.toLowerCase();
      return conversation.counterpartName.toLowerCase().contains(value) ||
          conversation.counterpartRole.toLowerCase().contains(value) ||
          (conversation.lastMessage?.content.toLowerCase().contains(value) ?? false);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: WebColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 340,
            child: _ConversationListPane(
              conversations: filteredConversations,
              selectedConversation: _selected,
              onQueryChanged: (value) => setState(() => _query = value),
              onRefresh: () {
                setState(() => _loadingConversations = true);
                _loadConversations(
                  initialConversationId: _selected?.id ?? widget.initialConversationId,
                );
              },
              onSelect: _loadMessages,
            ),
          ),
          const VerticalDivider(width: 1, color: WebColors.divider),
          Expanded(
            child: _selected == null
                ? const _MessagesPlaceholder()
                : _ConversationPane(
                    conversation: _selected!,
                    messages: _messages,
                    loading: _loadingMessages,
                    sending: _sending,
                    messagesError: _messagesError,
                    scrollController: _scrollController,
                    composerController: _composerController,
                    onReload: () => _loadMessages(_selected!),
                    onSend: _send,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationListPane extends StatelessWidget {
  final List<Conversation> conversations;
  final Conversation? selectedConversation;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onRefresh;
  final ValueChanged<Conversation> onSelect;

  const _ConversationListPane({
    required this.conversations,
    required this.selectedConversation,
    required this.onQueryChanged,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Conversations',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: WebColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    color: WebColors.textSecondary,
                    tooltip: 'Refresh messages',
                  ),
                ],
              ),
              WebSearchBar(
                hint: 'Search farmers or messages',
                onChanged: onQueryChanged,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: WebColors.divider),
        Expanded(
          child: conversations.isEmpty
              ? const _CompactPlaceholder(
                  title: 'No conversations',
                  message:
                      'Start a chat from the farmer management screen or wait for a farmer message.',
                  icon: Icons.chat_bubble_outline,
                )
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (_, index) {
                    final conversation = conversations[index];
                    final isSelected = conversation.id == selectedConversation?.id;
                    return _ConversationTile(
                      conversation: conversation,
                      selected: isSelected,
                      onTap: () => onSelect(conversation),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? WebColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          border: Border(
            bottom: const BorderSide(color: WebColors.divider),
            left: selected
                ? const BorderSide(color: WebColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebAvatar(
              initials: conversation.counterpartInitials,
              size: 38,
              gradient: WebColors.gradientGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.counterpartName.isEmpty
                              ? 'Conversation'
                              : conversation.counterpartName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: WebColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTimestamp(conversation.updatedAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: WebColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _capitalizeRole(conversation.counterpartRole),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: WebColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage?.content ?? 'No messages yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: WebColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: WebColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationPane extends StatelessWidget {
  final Conversation conversation;
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? messagesError;
  final ScrollController scrollController;
  final TextEditingController composerController;
  final VoidCallback onReload;
  final VoidCallback onSend;

  const _ConversationPane({
    required this.conversation,
    required this.messages,
    required this.loading,
    required this.sending,
    required this.messagesError,
    required this.scrollController,
    required this.composerController,
    required this.onReload,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.select<AuthProvider, String?>((auth) => auth.user?.id);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: WebColors.divider)),
          ),
          child: Row(
            children: [
              WebAvatar(
                initials: conversation.counterpartInitials,
                size: 40,
                gradient: WebColors.gradientGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.counterpartName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: WebColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_capitalizeRole(conversation.counterpartRole)} conversation',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: WebColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onReload,
                icon: const Icon(Icons.refresh, size: 18),
                color: WebColors.textSecondary,
                tooltip: 'Reload messages',
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : messagesError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: WebColors.warning,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              messagesError!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: WebColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            WebButton(
                              label: 'Retry',
                              icon: Icons.refresh,
                              onPressed: onReload,
                            ),
                          ],
                        ),
                      ),
                    )
                  : messages.isEmpty
                      ? const _CompactPlaceholder(
                          title: 'No messages yet',
                          message: 'Send the first message to start the conversation.',
                          icon: Icons.waving_hand_outlined,
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(18),
                          itemCount: messages.length,
                          itemBuilder: (_, index) => _WebMessageBubble(
                            message: messages[index],
                            isMine: messages[index].senderId == currentUserId,
                            counterpartInitials: conversation.counterpartInitials,
                          ),
                        ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: WebColors.divider)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: composerController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Write a message to ${conversation.counterpartName}...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              WebButton(
                label: sending ? 'Sending...' : 'Send',
                icon: Icons.send_rounded,
                onPressed: sending ? null : onSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WebMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String counterpartInitials;

  const _WebMessageBubble({
    required this.message,
    required this.isMine,
    required this.counterpartInitials,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat('MMM d, h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            WebAvatar(
              initials: counterpartInitials,
              size: 30,
              gradient: WebColors.gradientGreen,
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? WebColors.primary
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    border: isMine
                        ? null
                        : Border.all(color: WebColors.divider),
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: isMine ? Colors.white : WebColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: WebColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesPlaceholder extends StatelessWidget {
  const _MessagesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _CompactPlaceholder(
      title: 'Select a conversation',
      message:
          'Choose a farmer conversation from the list to review messages and respond.',
      icon: Icons.chat_bubble_outline,
    );
  }
}

class _CompactPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _CompactPlaceholder({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: WebColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: WebColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: WebColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: WebColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTimestamp(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inDays > 7) return DateFormat('MMM d').format(timestamp);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}

String _capitalizeRole(String value) {
  if (value.isEmpty) return 'Participant';
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

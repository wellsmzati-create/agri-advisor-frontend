import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../providers/farmer_provider.dart';
import '../../widgets/shared_widgets.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _messageRefreshInterval = Duration(seconds: 6);

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _refreshTimer;

  String get _convId => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadMessages(_convId);
    });
    _refreshTimer = Timer.periodic(
      _messageRefreshInterval,
      (_) {
        if (!mounted) return;
        context.read<FarmerProvider>().refreshConversation(_convId);
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<FarmerProvider>().sendMessage(_convId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: AppColors.gradientGreen)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          AdvisorAvatar(
              initials: widget.conversation.advisorInitials, size: 36),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.conversation.advisorName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Text('Advisor',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<FarmerProvider>(
        builder: (_, provider, __) {
          final loading = provider.msgLoading(_convId);
          final messages = provider.messagesFor(_convId);

          return Column(
            children: [
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const Center(
                            child: Text('No messages yet. Say hello! 👋',
                                style: TextStyle(
                                    color: AppColors.textSecondary)))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) => _MessageBubble(
                              message: messages[i],
                              advisorInitials:
                                  widget.conversation.advisorInitials,
                            )
                                .animate()
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.1, end: 0),
                          ),
              ),
              _InputBar(controller: _ctrl, onSend: _send),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String advisorInitials;
  const _MessageBubble(
      {required this.message, required this.advisorInitials});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromFarmer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AdvisorAvatar(initials: advisorInitials, size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.gradientGreen : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(message.content,
                      style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Center(
                  child: Text('Me',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold))),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2))
        ],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ask your advisor...',
              hintStyle:
                  const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 46, height: 46,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

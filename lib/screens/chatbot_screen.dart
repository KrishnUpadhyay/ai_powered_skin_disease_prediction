import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatbotScreen({super.key, this.initialMessage});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _suggestedPrompts = [
    "What is Melanoma risk?",
    "My mole is bleeding",
    "How to soothe Eczema?",
    "Fungal infection advice",
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! I am DermaBot, your AI Clinical Triage Assistant. Feel free to describe skin symptoms you are experiencing, ask about remedies, or enquire about general skin conditions.",
      isUser: false,
    ));

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSubmitted(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final res = await ApiService.sendChatMessage(text);
      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: res['response'] as String? ?? 'Sorry, I couldn\'t process that request.',
          isUser: false,
          riskLevel: res['risk_level'] as String?,
          suggestedAction: res['suggested_action'] as String?,
        ));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: "Connection failed: $e. Please verify the Flask backend server is running.",
          isUser: false,
          riskLevel: "Error",
        ));
        _isTyping = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Color _getRiskColor(String? risk) {
    if (risk == null) return Colors.grey;
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return AppColors.danger;
      case 'MODERATE':
        return AppColors.warning;
      case 'LOW':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
              ),
              child: const Icon(Icons.forum_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DermaBot AI',
                  style: AppTextStyles.bodyBold(isDark: isDark).copyWith(fontSize: 14),
                ),
                Text(
                  'Clinical Triage Assistant',
                  style: AppTextStyles.label(isDark: isDark).copyWith(fontSize: 9, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),

            // Typing indicator overlay
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 600.ms).fadeOut(delay: 300.ms),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ).animate(onPlay: (controller) => controller.repeat()).fadeIn(delay: 200.ms, duration: 600.ms).fadeOut(delay: 500.ms),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ).animate(onPlay: (controller) => controller.repeat()).fadeIn(delay: 400.ms, duration: 600.ms).fadeOut(delay: 700.ms),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DermaBot is typing...',
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMuted : AppColors.lightTextMuted),
                    ),
                  ],
                ),
              ),

            // Suggested prompt chips
            if (_messages.length <= 2 && !_isTyping)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _suggestedPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _suggestedPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: ActionChip(
                        label: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        backgroundColor: isDark ? AppColors.surfaceLight : Colors.black.withAlpha(12),
                        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withAlpha(20)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        onPressed: () => _handleSubmitted(prompt),
                      ),
                    );
                  },
                ),
              ),

            // Input controller bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type symptoms or ask questions...',
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final bubbleColor = msg.isUser
        ? AppColors.primary
        : (isDark ? AppColors.surface : Colors.white);
    
    final textColor = msg.isUser
        ? Colors.white
        : (isDark ? Colors.white : AppColors.lightTextPrimary);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: msg.isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: msg.isUser
              ? null
              : Border(
                  left: BorderSide(
                    color: _getRiskColor(msg.riskLevel),
                    width: 3.5,
                  ),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 10 : 5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message body
            Text(
              msg.text,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            
            // Risk assessment indicator (only for AI diagnosis replies)
            if (!msg.isUser && msg.riskLevel != null && msg.riskLevel != 'Low') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRiskColor(msg.riskLevel).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRiskColor(msg.riskLevel).withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      msg.riskLevel == 'High' ? Icons.warning_rounded : Icons.info_outline_rounded,
                      color: _getRiskColor(msg.riskLevel),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Triage Action: ${msg.suggestedAction ?? "Monitor"}',
                      style: TextStyle(
                        color: _getRiskColor(msg.riskLevel),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fade(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;
  final String? suggestedAction;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.riskLevel,
    this.suggestedAction,
  });
}

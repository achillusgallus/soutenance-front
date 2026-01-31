import 'package:flutter/material.dart';
import 'package:togoschool/services/service_api.dart';
import 'package:togoschool/utils/security_utils.dart';
import 'package:togoschool/core/theme/app_theme.dart';

class ForumChatPage extends StatefulWidget {
  final int topicId;
  final String topicTitle;
  final bool isTeacher;

  const ForumChatPage({
    super.key,
    required this.topicId,
    required this.topicTitle,
    this.isTeacher = false,
  });

  @override
  State<ForumChatPage> createState() => _ForumChatPageState();
}

class _ForumChatPageState extends State<ForumChatPage> {
  final api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMore &&
        !isLoading &&
        currentPage < lastPage) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (mounted) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
      await _fetchMessages();
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await api.read(
        "/sujets/${widget.topicId}/messages?page=$currentPage",
      );
      if (mounted) {
        final data = res?.data;
        List<dynamic> fetchedMessages = [];

        if (data is Map && data.containsKey('data')) {
          fetchedMessages = data['data'];
          lastPage = data['last_page'] ?? 1;
        } else if (data is List) {
          fetchedMessages = data;
        }

        setState(() {
          if (currentPage == 1) {
            messages = fetchedMessages;
          } else {
            messages.addAll(fetchedMessages);
          }
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final safeText = SecurityUtils.sanitizeInput(_messageController.text);
    if (safeText.isEmpty) return;

    setState(() => isSending = true);
    try {
      if (widget.isTeacher) {
        // Teacher reply endpoint
        await api.create(
          "/professeur/forums/sujets/${widget.topicId}/repondre",
          {"message": safeText},
        );
      } else {
        // Student/General message endpoint
        await api.create("/messages", {
          "sujet_id": widget.topicId,
          "message": safeText,
        });
      }

      _messageController.clear();
      // Reload page 1 to get the new message properly formatted from backend
      // OR insert locally. Re-fetching page 1 is safer for ID/Consistency.
      setState(() {
        currentPage = 1;
      });
      await _fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur d'envoi: $e")));
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Sujet Actif",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    reverse: true, // Chat mode: bottom to top
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      100,
                    ), // Extra bottom padding for input
                    itemCount: messages.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final msg = messages[index];
                      final isMe = msg['is_me'] ?? false;

                      // Date logic for reverse list:
                      // Current item is 'index'. Previous item (visually above, so chronologically older)
                      // is 'index + 1'.
                      // We show date if diff between current and older is significant,
                      // OR if it's the last item (top of screen, oldest loaded).

                      bool showDate = false;
                      if (index == messages.length - 1) {
                        showDate = true;
                      } else if (index < messages.length - 1) {
                        final olderMsg = messages[index + 1];
                        showDate =
                            msg['created_at_human'] !=
                            olderMsg['created_at_human'];
                      }

                      return Column(
                        children: [
                          if (showDate)
                            _buildDateSeparator(msg['created_at_human']),
                          _buildMessageBubble(msg, isMe),
                        ],
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String? date) {
    if (date == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
                letterSpacing: 1,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final name = msg['user']?['name'] ?? 'Utilisateur';
    final content = msg['message'] ?? '';
    final time = msg['created_at_human'] ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate avatar color
    final colors = [
      AppTheme.primaryColor,
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
    ];
    final avatarColor =
        colors[(msg['user_id'] ?? name).hashCode.abs() % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users' messages
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor.withOpacity(0.8), avatarColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              const Color(0xFF4F46E5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe
                        ? null
                        : (isDark ? theme.cardColor : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isMe ? 0 : 12,
                    right: isMe ? 12 : 0,
                  ),
                  child: Text(
                    time,
                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.scaffoldBackgroundColor
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                decoration: InputDecoration(
                  hintText: "Votre message...",
                  hintStyle: TextStyle(color: theme.hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucun message",
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez la discussion maintenant !",
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

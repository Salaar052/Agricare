import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ai_chatbot/ai_chat_model.dart';
import '../../api/ai_chat_service.dart';
import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final AIChatService _chatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatSession> _chatSessions = [];
  ChatSession? _currentChat;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSidebarOpen = true;

  late AnimationController _sidebarAnimController;
  late Animation<double> _sidebarAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _forest    = Color(0xFF1B3A1F);
  static const Color _canopy    = Color(0xFF2D5A27);
  static const Color _leaf      = Color(0xFF4A8C3F);
  static const Color _sage      = Color(0xFF7AAE6E);
  static const Color _mist      = Color(0xFFEFF5ED);
  static const Color _fog       = Color(0xFFF7FAF6);
  static const Color _bark      = Color(0xFF5C3D2E);
  static const Color _petal     = Color(0xFFFFFFFF);
  static const Color _shadow    = Color(0x1A1B3A1F);
  static const Color _border    = Color(0xFFD4E6CF);
  static const Color _textDark  = Color(0xFF1B2E1D);
  static const Color _textMid   = Color(0xFF4A6048);
  static const Color _textLight = Color(0xFF8AAB84);
  static const Color _danger    = Color(0xFFB94040);

  @override
  void initState() {
    super.initState();

    _sidebarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sidebarAnim = CurvedAnimation(
      parent: _sidebarAnimController,
      curve: Curves.easeInOutCubic,
    );
    _sidebarAnimController.value = 1.0; // starts open

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _loadChatSessions();
  }

  double _getSidebarWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return w * 0.78;
    if (w < 900) return 270;
    return 300;
  }

  Future<void> _loadChatSessions() async {
    try {
      final sessions = await _chatService.getAllChats();
      setState(() => _chatSessions = sessions);
    } catch (e) {
      _showError('Failed to load chats: $e');
    }
  }

  Future<void> _createNewChat() async {
    final titleController = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _petal,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _shadow, blurRadius: 40, spreadRadius: 0),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _leaf.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_comment_rounded,
                        color: _leaf, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('New Conversation',
                      style: _titleStyle.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                autofocus: true,
                style: _bodyStyle.copyWith(color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Give this chat a name…',
                  hintStyle: _bodyStyle.copyWith(color: _textLight),
                  filled: true,
                  fillColor: _mist,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _leaf, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: _bodyStyle.copyWith(color: _textMid)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, titleController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _leaf,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Create',
                          style: _labelStyle.copyWith(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (title != null && title.trim().isNotEmpty) {
      try {
        final newChat = await _chatService.createChat(title.trim());
        await _loadChatSessions();
        _selectChat(newChat);
      } catch (e) {
        _showError('Failed to create chat: $e');
      }
    }
  }

  Future<void> _selectChat(ChatSession chat) async {
    _fadeController.reset();
    setState(() {
      _currentChat = chat;
      _isLoading = true;
      if (MediaQuery.of(context).size.width < 600) {
        _toggleSidebar(false);
      }
    });

    try {
      final messages = await _chatService.getMessages(chat.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _fadeController.forward();
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChat == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toString(),
        chatId: _currentChat!.id,
        sender: 'user',
        message: message,
        createdAt: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response =
          await _chatService.sendMessage(_currentChat!.id, message);
      setState(() {
        _messages.removeLast();
        _messages.add(response.userMessage);
        _messages.add(response.botMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to send message: $e');
    }
  }

  Future<void> _deleteChat(ChatSession chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _petal,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _shadow, blurRadius: 40),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _danger, size: 22),
              ),
              const SizedBox(height: 16),
              Text('Delete Chat', style: _titleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${chat.title}"? This cannot be undone.',
                style: _bodyStyle.copyWith(color: _textMid, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Keep',
                          style: _bodyStyle.copyWith(color: _textMid)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Delete',
                          style: _labelStyle.copyWith(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.deleteChat(chat.id);
        if (_currentChat?.id == chat.id) {
          setState(() {
            _currentChat = null;
            _messages = [];
          });
        }
        await _loadChatSessions();
      } catch (e) {
        _showError('Failed to delete chat: $e');
      }
    }
  }

  void _toggleSidebar(bool open) {
    setState(() => _isSidebarOpen = open);
    if (!_isMobile) {
      if (open) {
        _sidebarAnimController.forward();
      } else {
        _sidebarAnimController.reverse();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: _bodyStyle.copyWith(color: Colors.white)),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Text styles ───────────────────────────────────────────────────────────
  static const TextStyle _titleStyle = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _textDark,
    letterSpacing: -0.3,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _textDark,
    letterSpacing: 0.2,
  );
  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _textDark,
    height: 1.55,
  );

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _getSidebarWidth(context);
    final mobile = _isMobile;

    return Scaffold(
      backgroundColor: _fog,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sage.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _leaf.withOpacity(0.06),
              ),
            ),
          ),

          // ── Main area always fills full screen ───────────────────────────
          Positioned.fill(
            child: mobile
                // On mobile: main area always full width
                ? _buildMainArea()
                // On tablet/desktop: sidebar + main side by side
                : Row(
                    children: [
                      SizeTransition(
                        sizeFactor: _sidebarAnim,
                        axis: Axis.horizontal,
                        child: SizedBox(
                          width: sidebarWidth,
                          child: _buildSidebar(),
                        ),
                      ),
                      Expanded(child: _buildMainArea()),
                    ],
                  ),
          ),

          // ── Mobile: sidebar slides in as overlay on top ──────────────────
          if (mobile) ...[
            // Dim scrim when sidebar open
            if (_isSidebarOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _toggleSidebar(false),
                  child: AnimatedOpacity(
                    opacity: _isSidebarOpen ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    child: Container(color: Colors.black.withOpacity(0.38)),
                  ),
                ),
              ),

            // Sidebar panel sliding from left
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              top: 0,
              bottom: 0,
              left: _isSidebarOpen ? 0 : -sidebarWidth,
              width: sidebarWidth,
              child: _buildSidebar(),
            ),
          ],
        ],
      ),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_forest, Color(0xFF243D20)],
        ),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(),

          // Sessions list
          Expanded(child: _buildSessionList()),

          // Footer
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 16, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo mark
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.18), width: 1),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgriCare',
                      style: _titleStyle.copyWith(
                          color: Colors.white, fontSize: 17),
                    ),
                    Text(
                      'AI Assistant',
                      style: _bodyStyle.copyWith(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () => _toggleSidebar(false),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: Colors.white.withOpacity(0.7), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // New Chat button
          GestureDetector(
            onTap: _createNewChat,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_leaf, Color(0xFF3A7432)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _leaf.withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('New Chat',
                      style: _labelStyle.copyWith(
                          color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    if (_chatSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white.withOpacity(0.2), size: 44),
              const SizedBox(height: 14),
              Text(
                'No conversations yet',
                style: _labelStyle.copyWith(
                    color: Colors.white.withOpacity(0.45)),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "New Chat" to begin',
                style: _bodyStyle.copyWith(
                    color: Colors.white.withOpacity(0.28), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: _chatSessions.length,
      itemBuilder: (context, index) {
        final chat = _chatSessions[index];
        final isActive = _currentChat?.id == chat.id;

        return _buildSessionTile(chat, isActive);
      },
    );
  }

  Widget _buildSessionTile(ChatSession chat, bool isActive) {
    return GestureDetector(
      onTap: () => _selectChat(chat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? Colors.white.withOpacity(0.22)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon dot
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive
                    ? _sage.withOpacity(0.3)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chat_rounded,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chat.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle.copyWith(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Delete
            GestureDetector(
              onTap: () => _deleteChat(chat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: isActive
                      ? Colors.red.shade300
                      : Colors.white.withOpacity(0.28),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _sage,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _sage.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AI is online & ready',
            style: _bodyStyle.copyWith(
                color: Colors.white.withOpacity(0.38), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ── MAIN AREA ─────────────────────────────────────────────────────────────
  Widget _buildMainArea() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildMessagesArea()),
        if (_currentChat != null) _buildInputBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      decoration: BoxDecoration(
        color: _petal,
        boxShadow: [
          BoxShadow(
            color: _shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to dashboard',
            onPressed: () {
              if (Get.isRegistered<MainNavController>()) {
                Get.find<MainNavController>().goToDashboardRoot();
              } else {
                Get.offAllNamed(AppRoutes.dashboard);
              }
            },
            icon: Icon(Icons.arrow_back_rounded, color: _forest, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: _forest.withOpacity(0.06),
              side: BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sidebar toggle
          GestureDetector(
            onTap: () => _toggleSidebar(!_isSidebarOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSidebarOpen
                    ? _forest.withOpacity(0.08)
                    : _forest.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Icon(
                _isSidebarOpen
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
                color: _forest,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title section
          Expanded(
            child: _currentChat != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentChat!.title,
                        style: _titleStyle.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_messages.length} message${_messages.length == 1 ? '' : 's'}',
                        style: _bodyStyle.copyWith(
                            color: _textLight, fontSize: 11.5),
                      ),
                    ],
                  )
                : Text('AgriCare AI',
                    style: _titleStyle.copyWith(
                        color: _forest, fontSize: 17)),
          ),

          // AI badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _leaf.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _leaf.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _leaf,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _leaf.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text('AI',
                    style: _labelStyle.copyWith(
                        color: _leaf, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_currentChat == null) return _buildEmptyState();
    if (_messages.isEmpty && !_isLoading) return _buildChatEmptyState();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) return _buildLoadingMessage();
          return _buildMessage(_messages[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_mist, Color(0xFFDCEDD8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _sage.withOpacity(0.2), blurRadius: 24),
                ],
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Welcome to AgriCare AI',
                style: _titleStyle.copyWith(fontSize: 22),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Your intelligent farming assistant.\nSelect a conversation or start a new one.',
              style: _bodyStyle.copyWith(color: _textLight, height: 1.7),
              textAlign: TextAlign.center,
            ),
            if (!_isSidebarOpen) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _toggleSidebar(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_canopy, _leaf],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _leaf.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text('Open Chat List',
                          style: _labelStyle.copyWith(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Start the conversation',
                style: _titleStyle.copyWith(fontSize: 18, color: _textMid)),
            const SizedBox(height: 8),
            Text(
              'Ask anything about farming, crops, or agri-care',
              style: _bodyStyle.copyWith(color: _textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 14,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              // Bot avatar
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10, bottom: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_canopy, _leaf],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _leaf.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: const Center(
                  child:
                      Text('🌿', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [_canopy, Color(0xFF3A7432)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : _petal,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? _canopy.withOpacity(0.25)
                          : _shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isUser
                      ? null
                      : Border.all(color: _border, width: 1),
                ),
                child: Text(
                  message.message,
                  style: _bodyStyle.copyWith(
                    color: isUser ? Colors.white : _textDark,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              // User avatar
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 10, bottom: 2),
                decoration: BoxDecoration(
                  color: _mist,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.5),
                ),
                child: const Icon(Icons.person_rounded,
                    color: _textMid, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _petal,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(color: _shadow.withOpacity(0.06), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_leaf),
              ),
            ),
            const SizedBox(width: 12),
            Text('Thinking…',
                style: _bodyStyle.copyWith(color: _textLight, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _petal,
        border: const Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: _shadow.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _mist,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border, width: 1.2),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                minLines: 1,
                style: _bodyStyle.copyWith(color: _textDark),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about crops, soil, weather…',
                  hintStyle:
                      _bodyStyle.copyWith(color: _textLight, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? const LinearGradient(
                        colors: [Color(0xFFBBBBBB), Color(0xFFAAAAAA)])
                    : const LinearGradient(
                        colors: [_canopy, _leaf],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: _leaf.withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sidebarAnimController.dispose();
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
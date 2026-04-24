import 'package:flutter/material.dart';
import '../../models/ai_chatbot/ai_chat_model.dart';
import '../../api/ai_chat_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final AIChatService _chatService = AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatSession> _chatSessions = [];
  ChatSession? _currentChat;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  // Get responsive sidebar width
  double _getSidebarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      // Mobile: half screen
      return screenWidth * 0.5;
    } else if (screenWidth < 900) {
      // Tablet: 250px
      return 250;
    } else {
      // Desktop: 280px
      return 280;
    }
  }

  Future<void> _loadChatSessions() async {
    try {
      final sessions = await _chatService.getAllChats();
      setState(() {
        _chatSessions = sessions;
      });
    } catch (e) {
      _showError('Failed to load chats: $e');
    }
  }

  Future<void> _createNewChat() async {
    final titleController = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Chat'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(hintText: 'Enter chat title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: Text('Create'),
          ),
        ],
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
    setState(() {
      _currentChat = chat;
      _isLoading = true;
      // Auto-close sidebar on mobile after selection
      if (MediaQuery.of(context).size.width < 600) {
        _isSidebarOpen = false;
      }
    });

    try {
      final messages = await _chatService.getMessages(chat.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
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

    // Add user message to UI immediately
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          chatId: _currentChat!.id,
          sender: 'user',
          message: message,
          createdAt: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        _currentChat!.id,
        message,
      );

      setState(() {
        // Replace the temporary user message with the one from server
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
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${chat.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            child: Text('Delete'),
          ),
        ],
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFFD32F2F)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (_isSidebarOpen)
            Container(
              width: _getSidebarWidth(context),
              decoration: BoxDecoration(
                color: Color(0xFFF5F9F3),
                border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Column(
                children: [
                  // Sidebar Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Color(0xFF2D5016)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isSidebarOpen = false;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _createNewChat,
                            icon: Icon(Icons.add),
                            label: Text('New Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A7C2C),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chat List
                  Expanded(
                    child: _chatSessions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No chats yet.\nCreate a new chat to start!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _chatSessions.length,
                            itemBuilder: (context, index) {
                              final chat = _chatSessions[index];
                              final isActive = _currentChat?.id == chat.id;

                              return Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Color(0xFF4A7C2C).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  onTap: () => _selectChat(chat),
                                  leading: Icon(
                                    Icons.chat_bubble_outline,
                                    color: isActive
                                        ? Color(0xFF2D5016)
                                        : Color(0xFF666666),
                                  ),
                                  title: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isActive
                                          ? Color(0xFF2D5016)
                                          : Color(0xFF333333),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFD32F2F),
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteChat(chat),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSidebarOpen ? Icons.menu_open : Icons.menu,
                          color: Color(0xFF2D5016),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarOpen = !_isSidebarOpen;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentChat?.title ?? 'Select a chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5016),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages Area
                Expanded(
                  child: _currentChat == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Color(0xFFE0E0E0),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Welcome to AI Assistant! 👋',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5016),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Create a new chat or select an existing one to start chatting',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Only show button when sidebar is closed
                              if (!_isSidebarOpen) ...[
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isSidebarOpen = true;
                                    });
                                  },
                                  icon: Icon(Icons.menu_open),
                                  label: Text('Open Chat List'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4A7C2C),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : _messages.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.waving_hand,
                                size: 60,
                                color: Color(0xFF4A7C2C),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Start chatting! 💬',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5016),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Send a message to begin the conversation',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              // Loading indicator
                              return _buildLoadingMessage();
                            }

                            final message = _messages[index];
                            return _buildMessage(message);
                          },
                        ),
                ),

                // Input Area
                if (_currentChat != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          SizedBox(width: 12),
                          FloatingActionButton(
                            onPressed: _isLoading ? null : _sendMessage,
                            backgroundColor: _isLoading
                                ? Colors.grey
                                : Color(0xFF4A7C2C),
                            child: Icon(Icons.send, color: Colors.white),
                            mini: MediaQuery.of(context).size.width < 600,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF4A7C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isUser ? Colors.white : Color(0xFF333333),
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C2C)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(color: Color(0xFF666666), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

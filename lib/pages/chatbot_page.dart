import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '../app_routes.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late GenerativeModel _model;

  // Define colors
  final Color primaryColor = const Color(0xFF4B39EF);
  final Color secondaryColor = const Color(0xFF39D2C0);
  final Color accentColor = const Color(0xFFFF5963);
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = const Color(0xFFFFFFFF);
  final Color primaryText = const Color(0xFF14181B);
  final Color secondaryText = const Color(0xFF57636C);

  @override
  void initState() {
    super.initState();
    _initializeAI();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your English learning assistant. I can help you with:\n\n• Grammar explanations\n• Vocabulary practice\n• Pronunciation tips\n• Conversation practice\n• Writing corrections\n\nWhat would you like to work on today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }


void _initializeAI() {
  // Use this temporary approach for testing:
  const apiKey = String.fromEnvironment(
    'GOOGLE_AI_API_KEY',
    defaultValue: '6b6c9792-9cba-4e4f-a236-ea64ec1a95dd', 
    //static const String MERRIAM_WEBSTER_API_KEY = '6b6c9792-9cba-4e4f-a236-ea64ec1a95dd';
    //static const String DICTIONARY_API_BASE = 'https://dictionaryapi.com/api/v3/references/learners/json/';

  );
  
  _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: apiKey,
  );
}

 /*  void _initializeAI() {
    // Initialize the Generative AI model
    static const String MERRIAM_WEBSTER_API_KEY = '6b6c9792-9cba-4e4f-a236-ea64ec1a95dd';
    static const String DICTIONARY_API_BASE = 'https://dictionaryapi.com/api/v3/references/learners/json/';

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  } */

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get AI response
      final prompt = "You are an English teaching assistant for visually impaired students. "
          "Provide clear, concise, and helpful responses. Focus on English learning aspects. "
          "User message: $message";
      
      final response = await _model.generateContent([Content.text(prompt)]);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "I'm sorry, I couldn't process that request.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      // Add welcome message back
      _messages.add(ChatMessage(
        text: "Hello! I'm your English learning assistant. How can I help you with your English learning today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        backgroundColor: primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'English Learning Assistant',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryText),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
          IconButton(
            icon: Icon(Icons.volume_up, color: primaryText),
            onPressed: _readLastMessage,
            tooltip: 'Read last message',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.school, color: Colors.white, size: 18),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? primaryColor : secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: message.isUser ? Colors.white : primaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, color: primaryColor, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.school, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: secondaryText,
                    shape: BoxShape.circle,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground,
        border: Border(top: BorderSide(color: secondaryText.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about English learning...',
                hintStyle: GoogleFonts.inter(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: primaryBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  void _readLastMessage() {
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      // You can integrate with TTS here using your existing TTS system
      // For example: PronunciationBackend().speakFeedback(lastMessage.text);
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
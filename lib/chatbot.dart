import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String message;
  final bool isHarki;

  ChatMessage({required this.message, required this.isHarki});
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  GenerativeModel? model;
  ChatSession? session;
  bool _isInitialized = false;
  bool _isLoadingResponse = false;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeHarki();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeHarki() async {
    final harkikey = dotenv.env['HARKI_KEY'];
    if (harkikey == null) {
      throw Exception('HARKI_KEY is not set in the environment variables');
    }
    try {
      model = GenerativeModel(
        model: "gemini-pro",
        apiKey: harkikey,
      );
      session = model?.startChat();
      await _sendToHarki("You are Harki, the AI assistant inside this app. Keep responses focused and clear.");
      setState(() => _isInitialized = true);
    } catch (e) {
      _showErrorSnackbar('Failed to initialize AI. Some features may be limited.');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoadingResponse) return;
    final messageText = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoadingResponse = true;
      _messages.add(ChatMessage(message: messageText, isHarki: false));
    });

    try {
      final harkiResponse = await _sendToHarki(messageText);
      setState(() => _messages.add(ChatMessage(message: harkiResponse, isHarki: true)));
    } catch (e) {
      _showErrorSnackbar('Failed to send message. Please try again.');
    } finally {
      setState(() => _isLoadingResponse = false);
    }
  }

  Future<String> _sendToHarki(String message) async {
    if (session == null) {
      return "AI service is not yet initialized.";
    }
    try {
      final prompt = "Citizen security context: $message";
      final response = await session!.sendMessage(Content.text(prompt));
      return response.text ?? "Error: No response text.";
    } catch (e) {
      return "Error: Could not generate a response.";
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        elevation: 0,
        title: const Text('AI Powered Chat', style: TextStyle(color: Color(0xFF57D463))),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Flexible(child: _buildMessageList()),
              if (_isLoadingResponse) _buildLoadingIndicator(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.isHarki ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (message.isHarki) _buildBotAvatar(), // Bot avatar on the left for bot messages
            _buildMessageBubble(message),
            if (!message.isHarki) _buildUserAvatar(), // User avatar on the right for user messages
          ],
        );
      },
    );
  }

  Widget _buildUserAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0), // Adjust padding as needed
      child: CircleAvatar(
        radius: 20,
        backgroundImage: user?.photoURL != null
            ? NetworkImage(user!.photoURL!) // User's Google profile picture
            : null, // No icon overlay if there's a profile picture
        backgroundColor: Colors.grey, // No background image if there's no profile picture
        child: user?.photoURL == null
            ? const Icon(Icons.person, color: Colors.white, size: 20) // Default user icon
            : null, // Background color for the default icon
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0), // Adjust the padding as needed
      child: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF57D463).withOpacity(0.2), // Apply the specified color
        child: const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/images/bot.png'),
          backgroundColor: Colors.transparent, // Set to transparent to avoid overlay issues
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: message.isHarki ? const Color(0xFF57D463).withOpacity(0.2) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: message.isHarki ? Radius.zero : const Radius.circular(12),
            bottomRight: message.isHarki ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isHarki ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              message.isHarki ? 'Harki' : (user?.displayName ?? 'User'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: message.isHarki ? const Color(0xFF006400) : Colors.black, // Dark green for Harki's name
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isInitialized && !_isLoadingResponse,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: _isInitialized ? 'Type your message...' : 'Initializing AI...',
                hintStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoadingResponse
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Color(0xFF57D463)),
            onPressed: _isInitialized && !_isLoadingResponse ? _sendMessage : null,
          ),
        ],
      ),
    );
  }
}

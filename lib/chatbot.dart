// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

      // Confirming initialization with a test message
      final testPrompt = await _sendToHarki("Test message to confirm Harki initialization.");
      debugPrint("Test response: $testPrompt");

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing Harki: $e');
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
      debugPrint('Error sending message: $e');
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
      debugPrint('Error sending message to Harki: $e');
      return "Error: Could not generate a response.";
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        elevation: 0,
        title: const Text('AI Powered Chat', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const Divider(),
            _buildMessageList(),
            if (_isLoadingResponse) _buildLoadingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: _messages.isEmpty
          ? const Center(child: Text('No messages yet. Start the conversation!'))
          : ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ListTile(
                  title: Text(
                    message.isHarki ? 'Harki' : 'You',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: message.isHarki ? Colors.blue : Colors.black,
                    ),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.isHarki 
                          ? Colors.blue.withOpacity(0.2) 
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.message,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
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
                hintText: _isInitialized 
                    ? 'Type your message...'
                    : 'Initializing AI...',
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
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: _isInitialized && !_isLoadingResponse 
                ? _sendMessage 
                : null,
          ),
        ],
      ),
    );
  }
}

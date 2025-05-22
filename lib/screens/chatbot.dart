import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ensure firebase_core is initialized in your main.dart
// import 'package:firebase_core/firebase_core.dart';

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
  final User? user = FirebaseAuth.instance.currentUser; // Made User nullable

  late final GenerativeModel _model;
  ChatSession? _session;
  bool _isInitialized = false;
  bool _isLoadingResponse = false;
  final List<ChatMessage> _messages = [];

  // Store the FirebaseVertexAI instance
  final FirebaseVertexAI _vertexAI = FirebaseVertexAI.instance;

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
    try {
      _model = _vertexAI.generativeModel(
        // Use a model that supports chat, like 'gemini-1.5-flash' or 'gemini-pro'
        model: 'gemini-1.5-flash', 
        systemInstruction: Content.system(
          "You are Harki, a helpful and empathetic AI assistant for citizen security. "
          "Your primary goal is to provide clear, concise, and actionable advice related to personal safety and community security. "
          "Maintain a supportive and calm tone. If a user seems distressed, offer to help them find appropriate resources if possible. "
          "Keep responses focused on the context of citizen security. Do not engage in off-topic conversations."
        ),
        // Generation Config: Fine-tune how the model generates responses
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 800,
        ),
      );

      // Start the chat session.
      _session = _model.startChat(history: [
      ]);

      setState(() => _isInitialized = true);
      _showSnackbar("Harki AI Initialized.", success: true);

    } catch (e) {
      print('Firebase Vertex AI Initialization Error: $e');
      _showSnackbar('Failed to initialize Harki AI. Some features may be limited. Error: ${e.toString()}');
      setState(() => _isInitialized = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoadingResponse || !_isInitialized || _session == null) {
      if (_session == null && _isInitialized) {
        _showSnackbar('Chat session not started. Please try re-initializing.');
      }
      return;
    }
    final messageText = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoadingResponse = true;
      _messages.add(ChatMessage(message: messageText, isHarki: false));
    });

    try {
      // Prepend context if needed, though systemInstruction should cover general context.
      // For specific query context, you can still add it.
      final userMessageWithContext = "Citizen security context: $messageText";
      final response = await _session!.sendMessage(Content.text(userMessageWithContext));

      final harkiResponseText = response.text;
      if (harkiResponseText == null) {
        _showSnackbar('Harki AI returned an empty response.');
        _messages.add(ChatMessage(message: "Sorry, I didn't get a response. Please try again.", isHarki: true));
      } else {
        _messages.add(ChatMessage(message: harkiResponseText, isHarki: true));
      }
    } catch (e) {
      print('Error sending message to Harki AI: $e');
      _showSnackbar('Failed to send message to Harki AI. Error: ${e.toString()}');
      _messages.add(ChatMessage(message: "Error: Could not get a response from Harki.", isHarki: true));
    } finally {
      setState(() => _isLoadingResponse = false);
    }
  }

  // _sendToHarki is now integrated into _sendMessage
  // void _showErrorSnackbar(String message) { ... } // Renamed to _showSnackbar

  void _showSnackbar(String message, {bool success = false, Duration duration = const Duration(seconds: 4)}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green[600] : Colors.red[600],
          duration: duration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        elevation: 0,
        title: const Text('Harki AI Chat', style: TextStyle(color: Color(0xFF57D463))),
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
              if (!_isInitialized && !_isLoadingResponse)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 16),
                      Text("Initializing Harki AI...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
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
        // Display messages from newest to oldest
        final message = _messages[_messages.length - 1 - index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.isHarki ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (message.isHarki) _buildBotAvatar(),
            _buildMessageBubble(message),
            if (!message.isHarki) _buildUserAvatar(),
          ],
        );
      },
    );
  }

  Widget _buildUserAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 8.0, top: 12.0, bottom: 4.0),
      child: CircleAvatar(
        radius: 18,
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        backgroundColor: Colors.grey[300],
        child: user?.photoURL == null ? Icon(Icons.person, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 10.0, top: 12.0, bottom: 4.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF57D463).withOpacity(0.2),
        child: const CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage('assets/images/bot.png'),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isHarki = message.isHarki;
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0), // Reduced horizontal margin
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isHarki ? const Color(0xFF57D463).withOpacity(0.15) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isHarki ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isHarki ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: isHarki ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              isHarki ? 'Harki' : (user?.displayName ?? 'You'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHarki ? const Color(0xFF006400) : Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message.message,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text("Harki is typing...", style: TextStyle(color: Colors.grey))
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isInitialized && !_isLoadingResponse,
              style: const TextStyle(color: Colors.black, fontSize: 15),
              decoration: InputDecoration(
                hintText: _isInitialized ? 'Message Harki...' : 'Harki AI is initializing...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_isLoadingResponse || !_isInitialized) ? null : (_) => _sendMessage(),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoadingResponse
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).primaryColor),
                  )
                : Icon(Icons.send_rounded, color: _isInitialized ? Theme.of(context).primaryColor : Colors.grey, size: 28),
            onPressed: (_isLoadingResponse || !_isInitialized) ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
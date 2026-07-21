import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../app/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiChatSheet extends StatefulWidget {
  final String? placeContext;
  const AiChatSheet({super.key, this.placeContext});

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final String _groqApiKey = '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';
  
  // Maintain the chat history for Groq (OpenAI format)
  final List<Map<String, String>> _chatHistory = [
    {
      "role": "system",
      "content": "You are 'Ceylon Trekker AI', an expert and premium travel guide for Sri Lanka. \\nCRITICAL RULES:\\n1. ALWAYS respond in clear, professional, and natural ENGLISH, regardless of the language or spelling the user uses (even if they type in Singlish/Sinhala).\\n2. Structure your answers clearly using bullet points and bold text for place names.\\n3. Keep answers concise, highly relevant, and practical. Do not use robotic greetings."
    }
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.placeContext != null) {
      _chatHistory[0]['content'] = _chatHistory[0]['content']! + "\\n\\nThe user is currently looking at: ${widget.placeContext}. Give them specific facts or tips about this place!";
      _messages.add(ChatMessage(
        text: "Ayubowan! 🌴 You are looking at ${widget.placeContext}. Ask me anything about it!",
        isUser: false,
      ));
    } else {
      _messages.add(ChatMessage(
        text: "Ayubowan! 🌴 I'm your Ceylon Trekker AI Guide (Powered by Groq). Where would you like to explore today?",
        isUser: false,
      ));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _textController.clear();
    });
    
    _chatHistory.add({"role": "user", "content": text});
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": _chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];
        
        _chatHistory.add({"role": "assistant", "content": aiMessage});

        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: aiMessage, isUser: false));
        });
      } else {
        _chatHistory.removeLast(); // Remove user message to prevent consecutive user messages
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: 'Groq API Error (${response.statusCode}):\\n${response.body}',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      _chatHistory.removeLast(); // Remove user message on network failure
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: 'Network error: $e',
          isUser: false,
        ));
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Chat Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: AppTheme.emerald),
                SizedBox(width: 12),
                Text(
                  'AI Guide (Groq)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: AppTheme.emerald),
                    ),
                  );
                }

                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: message.isUser ? AppTheme.emerald.withValues(alpha: 0.9) : AppTheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 16),
                      ),
                      border: message.isUser ? null : Border.all(color: Colors.white10),
                    ),
                    child: message.isUser
                        ? Text(
                            message.text,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                          )
                        : MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                              strong: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              listBullet: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about Sri Lanka...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: AppTheme.emerald,
                    radius: 24,
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ChationcApp());
}

class ChationcApp extends StatelessWidget {
  const ChationcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chationc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Poppins',
      ),
      home: const ChatBoardPage(),
    );
  }
}

// Model to store message data
class Message {
  final String text;
  final bool isMe;
  final DateTime time;
  final String id;

  Message({
    required this.text,
    required this.isMe,
    required this.time,
    required this.id,
  });
}

class ChatBoardPage extends StatefulWidget {
  const ChatBoardPage({super.key});

  @override
  State<ChatBoardPage> createState() => _ChatBoardPageState();
}

class _ChatBoardPageState extends State<ChatBoardPage> {
  final List<Message> _messages = [
    Message(
      id: 'welcome',
      text: "Welcome to chationc! Start the conversation.",
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final newUserMessage = Message(
      id: _generateId(),
      text: text,
      isMe: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(newUserMessage);
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'];
        _addBotMessage(aiResponse);
      } else {
        _addBotMessage("Sorry, backend error. Check console.");
      }
    } catch (e) {
      _addBotMessage("Connection issue: $e");
    }
  }

  void _addBotMessage(String text) {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
          Message(
            id: _generateId(),
            text: text,
            isMe: false,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _3DMessageBubble(
                      key: ValueKey(message.id),
                      message: message.text,
                      isMe: message.isMe,
                      time: message.time,
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.forum, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Text(
            'chationc',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => _sendMessage(_textController.text),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3D Animation Widget
class _3DMessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final DateTime time;

  const _3DMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  State<_3DMessageBubble> createState() => _3DMessageBubbleState();
}

class _3DMessageBubbleState extends State<_3DMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: 0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(
              widget.isMe ? -_rotateAnimation.value : _rotateAnimation.value,
            )
            ..scale(_scaleAnimation.value),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: widget.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: widget.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isMe ? 20 : 0),
                  bottomRight: Radius.circular(widget.isMe ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(widget.time),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

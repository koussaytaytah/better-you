import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/data_provider.dart';

class AIChatbotScreen extends ConsumerStatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  ConsumerState<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends ConsumerState<AIChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hello! I am your AI Chatbot. I can give you advice and analyze photos or voice messages. How can I help you today?',
      'isMe': false,
      'time': DateTime.now(),
      'type': 'text',
    },
  ];

  void _sendMessage({String? text, String? imagePath, String? vocalPath}) {
    if (text == null && imagePath == null && vocalPath == null) return;

    setState(() {
      _messages.add({
        'text': text,
        'imagePath': imagePath,
        'vocalPath': vocalPath,
        'isMe': true,
        'time': DateTime.now(),
        'type': imagePath != null
            ? 'image'
            : (vocalPath != null ? 'vocal' : 'text'),
      });
      if (text != null) _controller.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': _getAIResponse(
              text ?? (imagePath != null ? 'photo' : 'voice'),
            ),
            'isMe': false,
            'time': DateTime.now(),
            'type': 'text',
          });
        });
      }
    });
  }

  String _getAIResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('hello') || q.contains('hi')) {
      return 'Hi there! Ready to crush your goals today?';
    } else if (q.contains('sleep')) {
      return 'Getting 7-9 hours of sleep is crucial for recovery. Try to avoid screens 1 hour before bed.';
    } else if (q.contains('water') || q.contains('drink')) {
      return 'Aim for 8 glasses of water a day. Staying hydrated keeps your energy levels high!';
    } else if (q.contains('weight') || q.contains('diet')) {
      return 'Focus on whole foods and protein. Consistency is more important than perfection!';
    } else if (q.contains('photo')) {
      return 'That looks like a healthy meal! Make sure to keep your portions in check.';
    } else if (q.contains('voice')) {
      return 'I heard you! Keep up the great work on your fitness journey.';
    } else {
      return 'That sounds interesting! Tell me more about your health journey.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Chatbot',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
    final isMe = msg['isMe'] as bool;
    final type = msg['type'] as String;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'text' && msg['text'] != null)
              Text(
                msg['text'] as String,
                style: GoogleFonts.poppins(
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
              ),
            if (type == 'image' && msg['imagePath'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(msg['imagePath'] as String),
                  fit: BoxFit.cover,
                ),
              ),
            if (type == 'vocal')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: isMe ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Message',
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg['time'] as DateTime),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
            ),
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
              );
              if (image != null) {
                _sendMessage(imagePath: image.path);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary),
            onPressed: () {
              // Simulate vocal recording
              _sendMessage(vocalPath: 'dummy_path');
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Ask for advice...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(text: _controller.text),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(text: _controller.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

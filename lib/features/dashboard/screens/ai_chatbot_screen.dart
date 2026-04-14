import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../chat/widgets/audio_message_bubble.dart';
import '../../../shared/widgets/glass_card.dart';

final aiServiceProvider = Provider((ref) => AIService());

class AIChatbotScreen extends ConsumerStatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  ConsumerState<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends ConsumerState<AIChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _isLoading = false;
  String? _recordingPath;
  final List<Map<String, dynamic>> _messages = [];

  final List<String> _smartChips = [
    'Log yesterday\'s sleep',
    'Why am I tired?',
    'Analyze my latest meal',
    'Suggest a 20m workout',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'text':
          'Hello! I am your AI Chatbot. I can give you advice and analyze photos or voice messages. How can I help you today?',
      'isMe': false,
      'time': DateTime.now(),
      'type': 'text',
    });
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _flutterTts.stop();
    super.dispose();
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

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        const config = RecordConfig();
        await _audioRecorder.start(config, path: _recordingPath!);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMessage(vocalPath: path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _sendMessage({String? text, String? imagePath, String? vocalPath}) async {
    if (text == null && imagePath == null && vocalPath == null) return;
    
    final messageText = text ?? (vocalPath != null ? "Voice Message" : "Image Message");

    setState(() {
      _messages.add({
        'text': messageText,
        'imagePath': imagePath,
        'vocalPath': vocalPath,
        'isMe': true,
        'time': DateTime.now(),
        'type': imagePath != null ? 'image' : (vocalPath != null ? 'vocal' : 'text'),
      });
      _isLoading = true;
      if (text != null) _controller.clear();
    });
    _scrollToBottom();

    final user = ref.read(currentUserProvider);
    final todayLog = ref.read(todayLogProvider).value;
    String query = text ?? "";

    if (vocalPath != null) {
      final transcription = await ref.read(aiServiceProvider).transcribeAudio(vocalPath);
      if (transcription != null) {
        query = transcription;
        setState(() {
          final index = _messages.lastIndexWhere((m) => m['vocalPath'] == vocalPath);
          if (index != -1) {
            _messages[index]['text'] = '🎤 $transcription';
          }
        });
      }
    }

    final response = await ref.read(aiServiceProvider).getAIResponse(
      query.isEmpty ? "What's in this image?" : query,
      user: user,
      todayLog: todayLog,
      base64Image: imagePath != null ? base64Encode(File(imagePath).readAsBytesSync()) : null,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'text': response,
          'isMe': false,
          'time': DateTime.now(),
          'type': 'text',
        });
        _isLoading = false;
      });
      _scrollToBottom();
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
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          _buildSmartChips(isDark),
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
              ? AppColors.primary.withValues(alpha: isDark ? 0.8 : 1.0)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          border: isMe ? null : Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isMe ? 24 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 24),
          ),
          boxShadow: isMe ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'image' && msg['imagePath'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(msg['imagePath'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (type == 'vocal' && msg['vocalPath'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AudioMessageBubble(
                  url: msg['vocalPath'] as String,
                  isMe: isMe,
                ),
              ),
            if (!isMe)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                    onPressed: () {
                      _flutterTts.speak(msg['text'] as String);
                    },
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            if (msg['text'] != null)
              Text(
                msg['text'] as String,
                style: GoogleFonts.poppins(
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSmartChips(bool isDark) {
    if (_messages.length > 2) return const SizedBox.shrink(); // Hide after early conversation

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _smartChips.length,
        itemBuilder: (context, index) {
          final chip = _smartChips[index];
          return GestureDetector(
            onTap: () {
              _controller.text = chip;
              _sendMessage();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                chip,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ).animate(delay: (400 + (index * 100)).ms).fadeIn().slideX(begin: 0.1);
        },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
              Stack(
                alignment: Alignment.center,
                children: [
                   if (_isRecording)
                    ...[1, 2, 3].map((i) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withValues(alpha: 0.2),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(
                        duration: 1200.ms,
                        delay: (400 * i).ms,
                        begin: const Offset(1, 1),
                        end: const Offset(2.5, 2.5),
                        curve: Curves.easeOut,
                      ).fadeOut()),
                  GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressUp: _stopRecording,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.danger : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? Colors.white : AppColors.primary,
                      ),
                    ).animate(target: _isRecording ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: _isRecording ? 'Recording...' : 'Ask for advice...',
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
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   ...[0.4, 0.7, 1.0, 0.7, 0.4].map((h) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 20 * h,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                    begin: 0.5,
                    end: 1.5,
                    duration: 400.ms,
                    curve: Curves.easeInOut,
                  )),
                  const SizedBox(width: 12),
                  Text(
                    'Recording... Release to send',
                    style: GoogleFonts.poppins(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

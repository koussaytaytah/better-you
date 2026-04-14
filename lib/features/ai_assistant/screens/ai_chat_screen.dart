import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

final aiServiceProvider = Provider((ref) => AIService());

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLoading = false;
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your Better You AI assistant. How can I help you with your health journey today?",
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 25, // Lower quality to reduce payload size
      maxWidth: 800, // Limit resolution
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      _sendMultimediaMessage(
        text: "What's in this image? Provide health advice if relevant.",
        base64Image: base64Image,
        imagePath: image.path,
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        const config = RecordConfig();
        await _audioRecorder.start(config, path: _recordingPath!);
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
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
        // Add message immediately for feedback
        final userMsg = ChatMessage(
          text: "Voice Message",
          isMe: true,
          timestamp: DateTime.now(),
          audioPath: path,
        );
        setState(() {
          _messages.add(userMsg);
          _isLoading = true;
        });
        _scrollToBottom();
        _processVoiceMessage(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _processVoiceMessage(String path) async {
    final transcription = await ref
        .read(aiServiceProvider)
        .transcribeAudio(path);

    if (transcription != null && transcription.isNotEmpty) {
      final user = ref.read(currentUserProvider);
      final todayLog = ref.read(todayLogProvider).value;

      // Update the "Voice Message" placeholder with actual transcription
      setState(() {
        final index = _messages.lastIndexWhere((m) => m.audioPath == path);
        if (index != -1) {
          _messages[index] = ChatMessage(
            text: '🎤 $transcription',
            isMe: true,
            timestamp: _messages[index].timestamp,
            audioPath: path,
          );
        }
      });

      final response = await ref
          .read(aiServiceProvider)
          .getAIResponse(transcription, user: user, todayLog: todayLog);

      setState(() {
        _messages.add(
          ChatMessage(text: response, isMe: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not understand the audio. Please try again.'),
        ),
      );
    }
  }

  void _sendMessage({String? customText}) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    _sendMultimediaMessage(text: text);
  }

  void _sendMultimediaMessage({
    required String text,
    String? base64Image,
    String? imagePath,
  }) async {
    final user = ref.read(currentUserProvider);
    final todayLog = ref.read(todayLogProvider).value;

    setState(() {
      _messages.add(
        ChatMessage(
          text: base64Image != null ? "Analyzing image..." : text,
          isMe: true,
          timestamp: DateTime.now(),
          imagePath: imagePath,
        ),
      );
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await ref
        .read(aiServiceProvider)
        .getAIResponse(
          text,
          user: user,
          todayLog: todayLog,
          base64Image: base64Image,
        );

    setState(() {
      _messages.add(
        ChatMessage(text: response, isMe: false, timestamp: DateTime.now()),
      );
      _isLoading = false;
    });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI Assistant',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: _messages[index], tts: _flutterTts),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
                        color: _isRecording
                            ? AppColors.danger
                            : AppColors.background,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording ? [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ] : null,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: _isRecording ? Colors.white : AppColors.primary,
                      ),
                    ).animate(target: _isRecording ? 1 : 0).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 300.ms,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.textLight,
                ),
              ),
              IconButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textLight,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _isRecording
                        ? 'Recording...'
                        : 'Ask me anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
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

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imagePath;
  final String? audioPath;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imagePath,
    this.audioPath,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final FlutterTts tts;

  const _ChatBubble({required this.message, required this.tts});

  Future<void> _speakResponse() async {
    await tts.speak(message.text);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
            bottomLeft: message.isMe
                ? const Radius.circular(20)
                : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(message.imagePath!)),
                ),
              ),
            if (message.audioPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AudioMessageBubble(
                  url: message.audioPath!,
                  isMe: message.isMe,
                ),
              ),
            if (!message.isMe)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: _speakResponse,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.poppins(
                color: message.isMe ? Colors.white : AppColors.text,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: (message.isMe ? Colors.white : AppColors.text)
                    .withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: message.isMe ? 0.1 : -0.1);
  }
}

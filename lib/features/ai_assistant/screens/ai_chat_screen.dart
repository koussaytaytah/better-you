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
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        if (kIsWeb) {
          const config = RecordConfig();
          await _audioRecorder.start(config, path: '');
          setState(() => _isRecording = true);
          return;
        }

        final directory = await getApplicationDocumentsDirectory();
        _recordingPath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();
        await _audioRecorder.start(config, path: _recordingPath!);

        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required to record voice messages.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start recording: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);

        if (path != null) {
          _processVoiceMessage(path);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  void _handleMicTap() {
    if (_isRecording) {
      _stopRecording();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Long press the microphone to record your message.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _processVoiceMessage(String path) async {
    setState(() => _isLoading = true);

    final transcription = await ref
        .read(aiServiceProvider)
        .transcribeAudio(path);

    if (transcription != null && transcription.isNotEmpty) {
      // Don't call _sendMessage directly, handle it here to avoid double UI addition
      final user = ref.read(currentUserProvider);
      final todayLog = ref.read(todayLogProvider).value;

      setState(() {
        _messages.add(
          ChatMessage(
            text: transcription,
            isMe: true,
            timestamp: DateTime.now(),
            audioPath: path,
          ),
        );
        _isLoading = true;
      });
      _scrollToBottom();

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
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
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
              GestureDetector(
                onTap: _handleMicTap,
                onLongPress: _startRecording,
                onLongPressUp: _stopRecording,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            color: _isRecording
                                ? AppColors.danger
                                : AppColors.textLight,
                          )
                          .animate(target: _isRecording ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                            duration: 500.ms,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(duration: 1000.ms, color: Colors.white54),
                ),
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
              child: Text(
                'Recording... Release to send',
                style: GoogleFonts.poppins(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(),
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

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final FlutterTts tts;

  const _ChatBubble({required this.message, required this.tts});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isSpeaking = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.message.audioPath != null) {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        // Stop TTS if speaking
        await widget.tts.stop();
        if (mounted) setState(() => _isSpeaking = false);

        await _audioPlayer.play(DeviceFileSource(widget.message.audioPath!));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    }
  }

  Future<void> _speakResponse() async {
    if (_isSpeaking) {
      await widget.tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      // Stop audio player if playing
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlaying = false);

      setState(() => _isSpeaking = true);
      await widget.tts.setLanguage("en-US");
      await widget.tts.setPitch(1.0);
      await widget.tts.speak(widget.message.text);
      widget.tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.message.isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: widget.message.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: widget.message.isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
            bottomLeft: widget.message.isMe
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
          crossAxisAlignment: widget.message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (widget.message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(widget.message.imagePath!)),
                ),
              ),
            if (widget.message.audioPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: _playAudio,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: widget.message.isMe
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Message',
                        style: TextStyle(
                          color: widget.message.isMe
                              ? Colors.white
                              : AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!widget.message.isMe)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: _speakResponse,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            Text(
              widget.message.text,
              style: GoogleFonts.poppins(
                color: widget.message.isMe ? Colors.white : AppColors.text,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(widget.message.timestamp),
              style: TextStyle(
                color: (widget.message.isMe ? Colors.white : AppColors.text)
                    .withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: widget.message.isMe ? 0.1 : -0.1);
  }
}

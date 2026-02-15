import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers.dart';

class ChatInput extends ConsumerStatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendVoice;

  const ChatInput({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  bool _isRecording = false;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _controller.clear();
    }
  }

  Future<void> _toggleRecording() async {
    final recorderService = ref.read(voiceRecorderServiceProvider);

    if (_isRecording) {
      // Stop
      final result = await recorderService.stopAudioCapture();
      setState(() => _isRecording = false);

      result.fold(
        (path) async {
          // Upload
          // Show loading/uploading state in UI if needed (skipped for simplicity)
          final uploadResult = await recorderService.uploadRecording(path);
          uploadResult.fold(
            (url) => widget.onSendVoice(url),
            (error) => _showError('Upload failed: ${error.message}'),
          );
        },
        (error) => _showError('Recording failed: ${error.message}'),
      );
    } else {
      // Start
      final result = await recorderService.startAudioCapture();
      result.fold(
        (_) => setState(() => _isRecording = true),
        (error) => _showError('Could not start recording: ${error.message}'),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _toggleRecording,
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic,
                color: _isRecording ? AppColors.error : AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 8),
            if (_isRecording)
              Expanded(
                child: Text(
                  'Recording... (Tap stop to send)',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              )
            else
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: AppColors.textFaint),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            const SizedBox(width: 8),
            if (!_isRecording)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.background,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

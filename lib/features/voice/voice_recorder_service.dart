import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';

import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';

/// Service responsible for recording audio and uploading it to Firebase Storage.
///
/// Wraps the [Record] package and [PermissionHandler] to isolate device-specific logic.
class VoiceRecorderService {
  final AudioRecorder _audioRecorder;
  final FirebaseStorage _storage;

  VoiceRecorderService({
    required FirebaseStorage storage,
    AudioRecorder? audioRecorder,
  })  : _storage = storage,
        _audioRecorder = audioRecorder ?? AudioRecorder();

  /// Starts recording audio to a temporary file.
  Future<Result<void>> startAudioCapture() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        return const Failure(AppError(message: 'Microphone permission denied'));
      }

      // Check if already recording
      final isRecording = await _audioRecorder.isRecording();
      if (isRecording) {
        debugPrint('VoiceRecorderService: Already recording, stopping current one.');
        await _audioRecorder.stop();
      }

      // Generate a temporary file path
      final tempDir = Directory.systemTemp;
      final path = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      debugPrint('VoiceRecorderService: Initializing hardware at $path');
      
      // Hardware-safe delay: Give Android audio subsystem a moment to switch modes
      await Future.delayed(const Duration(milliseconds: 200));

      // Start recording with explicit AAC LC encoder for maximum Android compatibility
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), 
        path: path,
      ); 
      
      return const Success(null);
    } catch (e, stack) {
      debugPrint('VoiceRecorderService: startAudioCapture failed: $e');
      return Failure(AppError(
        message: 'Mic initialization failed: ${e.toString()}',
        stackTrace: stack,
      ));
    }
  }

  /// Stops recording and returns the file path.
  Future<Result<String>> stopAudioCapture() async {
    try {
      final isRecording = await _audioRecorder.isRecording();
      if (!isRecording) {
        return const Failure(AppError(message: 'Not currently recording'));
      }

      final path = await _audioRecorder.stop();
      if (path == null) {
        return const Failure(AppError(message: 'No file path returned'));
      }
      debugPrint('VoiceRecorderService: Stopped recording, path: $path');
      return Success(path);
    } catch (e, stack) {
      debugPrint('VoiceRecorderService: stopAudioCapture failed: $e');
      return Failure(AppError(
        message: 'Failed to stop recording',
        stackTrace: stack,
      ));
    }
  }

  /// Uploads the recorded file to Firebase Storage.
  Future<Result<String>> uploadRecording(String filePath) async {
    try {
      // Tiny delay to ensure OS has fully flushed the file buffers after recording stops
      await Future.delayed(const Duration(milliseconds: 200));

      final file = File(filePath);
      if (!file.existsSync()) {
        return const Failure(AppError(message: 'Recording file lost or not created'));
      }

      final length = await file.length();
      if (length == 0) {
        return const Failure(AppError(message: 'Recording is empty - likely hardware failure'));
      }

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref().child('voice_messages').child(fileName);

      debugPrint('VoiceRecorderService: Uploading to ${ref.fullPath} ($length bytes)...');
      
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'audio/m4a'),
      );

      // Monitor state for better debugging
      final snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        return Failure(AppError(message: 'Upload task failed with state: ${snapshot.state}'));
      }

      debugPrint('VoiceRecorderService: Upload successful, fetching URL with retries...');
      
      String? downloadUrl;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          // Progressive delay: 500ms, 1000ms, 1500ms
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
          downloadUrl = await snapshot.ref.getDownloadURL();
          break; // Success!
        } catch (e) {
          retryCount++;
          debugPrint('VoiceRecorderService: URL fetch attempt $retryCount failed: $e');
          if (retryCount >= maxRetries) rethrow;
        }
      }

      return Success(downloadUrl!);
    } catch (e, stack) {
      debugPrint('VoiceRecorderService: uploadRecording failed: $e');
      return Failure(AppError(
        message: 'Upload failed: ${e.toString()}',
        stackTrace: stack,
      ));
    }
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }

  Future<bool> _checkPermission() async {
    // Use the package's native permission check
    return await _audioRecorder.hasPermission();
  }
}

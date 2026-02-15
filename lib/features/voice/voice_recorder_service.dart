import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
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
        return const Failure(AppError(message: 'Already recording'));
      }

      // Generate a temporary file path
      final tempDir = Directory.systemTemp;
      final path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Start recording
      await _audioRecorder.start(const RecordConfig(), path: path); 
      
      return const Success(null);
    } catch (e, stack) {
      debugPrint('VoiceRecorderService: startAudioCapture failed: $e');
      return Failure(AppError(
        message: 'Failed to start recording',
        stackTrace: stack,
      ));
    }
  }

  /// Stops recording and returns the file path.
  Future<Result<String>> stopAudioCapture() async {
    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        return const Failure(AppError(message: 'Recording failed: No file path returned'));
      }
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
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Failure(AppError(message: 'File does not exist'));
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref().child('voice_messages').child(fileName);

      await ref.putFile(file);
      // TODO: Check file size before upload to prevent exceeding storage quotas (Cost Control).
      final downloadUrl = await ref.getDownloadURL();

      return Success(downloadUrl);
    } catch (e, stack) {
      debugPrint('VoiceRecorderService: uploadRecording failed: $e');
      return Failure(AppError(
        message: 'Failed to upload recording',
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

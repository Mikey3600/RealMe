import 'package:audioplayers/audioplayers.dart';

import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';

/// Service responsible for playing audio from URLs.
///
/// Wraps [AudioPlayer] to isolate playback logic.
class VoicePlayerService {
  final AudioPlayer _audioPlayer;

  VoicePlayerService({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  /// Plays audio from the given [url].
  Future<Result<void>> play(String url) async {
    try {
      if (url.isEmpty) {
        return const Failure(AppError(message: 'Audio URL is empty'));
      }
      
      await _audioPlayer.play(UrlSource(url));
      return const Success(null);
    } catch (e, stack) {
      return Failure(AppError(
        message: 'Failed to play audio',
        stackTrace: stack,
      ));
    }
  }

  /// Stops current playback.
  Future<Result<void>> stop() async {
    try {
      await _audioPlayer.stop();
      return const Success(null);
    } catch (e, stack) {
      return Failure(AppError(
        message: 'Failed to stop audio',
        stackTrace: stack,
      ));
    }
  }

  /// Pauses current playback.
  Future<Result<void>> pause() async {
    try {
      await _audioPlayer.pause();
      return const Success(null);
    } catch (e, stack) {
      return Failure(AppError(
        message: 'Failed to pause audio',
        stackTrace: stack,
      ));
    }
  }

  /// Disposes the underlying player.
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

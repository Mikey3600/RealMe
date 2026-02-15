import 'package:hive_flutter/hive_flutter.dart';

import '../core/errors/app_error.dart';
import '../core/errors/result.dart';

/// Service responsible for local storage using Hive.
///
/// Handles caching of pending messages for offline support.
class HiveService {
  static const String pendingMessagesBoxName = 'pending_messages';

  /// Initializes Hive and opens necessary boxes.
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(pendingMessagesBoxName);
  }

  /// Adds a pending message to the cache.
  Future<Result<void>> addPendingMessage(Map<String, dynamic> message) async {
    try {
      final box = Hive.box<Map>(pendingMessagesBoxName);
      await box.add(message);
      return const Success(null);
    } catch (e, stack) {
      return Failure(AppError(
        message: 'Failed to cache pending message',
        stackTrace: stack,
      ));
    }
  }

  /// Retrieves all pending messages.
  List<Map<dynamic, dynamic>> getPendingMessages() {
    final box = Hive.box<Map>(pendingMessagesBoxName);
    return box.values.cast<Map<dynamic, dynamic>>().toList();
  }

  /// Removes a pending message by key (implemented for future sync).
  Future<void> removePendingMessage(int key) async {
    final box = Hive.box<Map>(pendingMessagesBoxName);
    await box.delete(key);
  }
}

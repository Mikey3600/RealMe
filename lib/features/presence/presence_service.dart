import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/firestore_paths.dart';

/// Service responsible for tracking the user's online presence and last seen times.
///
/// It observes the application lifecycle to update the user's status in Firestore
/// automatically.
class PresenceService with WidgetsBindingObserver {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PresenceService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  /// Starts listening to app lifecycle changes and sets the user as online.
  void init() {
    WidgetsBinding.instance.addObserver(this);
    _syncPresenceToRemote(isOnline: true);
  }

  /// Stops listening to app lifecycle changes and sets the user as offline.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncPresenceToRemote(isOnline: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPresenceToRemote(isOnline: true);
    } else {
      // paused, inactive, detached -> user is effectively offline or backgrounded
      // Note: This is "fire-and-forget". If the OS kills the app immediately,
      // this network request might not complete. 'lastSeen' timestamp helps mitigate this.
      _syncPresenceToRemote(isOnline: false);
    }
  }

  /// Updates the user's presence document in Firestore.
  ///
  /// [isOnline] : True if the app is in the foreground, false otherwise.
  Future<void> _syncPresenceToRemote({required bool isOnline}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for presence updates to avoid spamming UI/logs
      debugPrint('Presence update failed: $e');
    }
  }
}

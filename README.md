# RealMe

**RealMe** is a production-grade, real-time messaging application built with Flutter and Firebase. It demonstrates a scalable, offline-first architecture designed for reliability and clean code principles.

## 1. Project Overview

RealMe solves the problem of unreliable connectivity in mobile messaging. Unlike tutorial applications that assume perfect network conditions, RealMe implements a robust offline strategy and explicit error handling to ensure message delivery and data integrity.

The scope of this project includes:
-   **Authentication**: Secure Google Sign-In.
-   **Real-time Communication**: Instant messaging sync via Firestore.
-   **Media**: Voice recording and playback with optimized storage.
-   **Presence**: Real-time "Online" and "Last Seen" indicators.
-   **Resilience**: Offline queuing and background synchronization.

## 2. Feature Set

-   **Authentication**: Google Sign-In with strict session management and secure credential handling.
-   **Chat**: Real-time text messaging with 1-on-1 support.
-   **Voice Notes**: Native audio recording (AAC/m4a) and streaming playback.
-   **Presence System**: Automatic status updates based on app lifecycle (foreground/background).
-   **Offline-First**: Messages are queued locally via Hive if the network is unavailable and synced when connectivity returns.
-   **Push Notifications**: Firebase Cloud Messaging (FCM) integration for background alerts.
-   **Robust Error Handling**: User-friendly error messages with no silent failures.
-   **Testing**: comprehensive unit tests for data layers and widget tests for key UI flows.

## 3. Tech Stack

-   **Framework**: Flutter (Dart)
-   **State Management**: `flutter_riverpod` (v2.5+) for dependency injection and reactive state.
-   **Backend**: Firebase (Auth, Firestore, Storage, Messaging).
-   **Local Storage**: `hive` (NoSQL database) for persistent offline message queues.
-   **Audio**: `record` (recording) and `audioplayers` (playback).
-   **Utils**: `permission_handler` (OS permissions), `connectivity_plus` (network status).

## 4. Architecture Walkthrough

RealMe follows a **Clean Architecture** approach with strict separation of concerns, utilizing the **Repository Pattern** to decouple the domain logic from external data sources.

### Layered Structure

1.  **Presentation Layer (`lib/features/*/presentation`)**:
    -   **Widgets**: Passive UI components that render state (e.g., `ChatScreen`).
    -   **Controllers**: `StateNotifier` classes that manage UI state and interact with Use Cases/Repositories (e.g., `AuthController`).
    -   **State**: Immutable state objects or primitives managed by Riverpod.

2.  **Domain Layer (`lib/features/*/domain`)**:
    -   **Entities**: Pure Dart classes representing core business data (e.g., `MessageEntity`, `UserEntity`).
    -   **Repository Interfaces**: Abstract contracts defining *what* operations are possible, not *how* they are implemented (e.g., `ChatRepository`).
    -   **No Dependencies**: This layer does not import Flutter or Firebase.

3.  **Data Layer (`lib/features/*/data` & `lib/services`)**:
    -   **Repository Implementations**: Concrete classes (e.g., `FirebaseChatRepository`) that implement the domain interfaces.
    -   **Data Sources**: Direct API calls to Firebase, Hive, etc.
    -   **DTOs/Mappers**: Conversion logic between Firestore documents/JSON and Domain Entities.

### Key Design Patterns

-   **Command-Query Separation (CQS)**:
    -   **Commands** (Writes): Methods that perform an action (e.g., `sendMessage`) return `Future<Result<void>>`. They do not return data, only success/failure status.
    -   **Queries** (Reads): Methods that return data (e.g., `getMessages`) return `Stream<List<MessageEntity>>`. They do not perform side effects.

-   **Depdendency Injection**:
    -   Managed via `lib/core/providers.dart`.
    -   Services like `VoiceRecorderService` use `Provider.autoDispose` to ensure native resources (microphones/audio sessions) are released immediately when not in use.

## 5. Data Flow Walkthrough

### 1. User Authentication
1.  User taps "Sign in with Google".
2.  `AuthController` calls `AuthRepository.signInWithGoogle()`.
3.  `FirebaseAuthRepository` triggers the Google Sign-In flow (side effect).
4.  On success, Firebase credentials are exchanged, and the user is authenticated.
5.  Refreshed `authUserProvider` stream updates the UI to navigate to the Home Screen.

### 2. Sending a Message (Online)
1.  User types a message and taps Send.
2.  `ChatController` creates a `MessageEntity` with status `sending`.
3.  `ChatRepository.sendMessage()` is called.
4.  `FirebaseChatRepository` writes the document to `/chats/{chatId}/messages/{messageId}`.
5.  Firestore's real-time listener updates the UI automatically.

### 3. Sending a Message (Offline)
1.  `ChatRepository.sendMessage()` is called but `set()` throws or times out (detected via connectivity check logic wrapped in the repository).
2.  **Fallback**: The message is serialized and stored in Hive (`pending_messages` box).
3.  The UI optimistically shows the message (handled via local state merge or strictly listening to the stream which Firestore buffers locally).
4.  *Note: Firestore SDK buffers writes internally. Hive is used here as a secondary "Outbox" for explicit retry control or app restarts.*

### 4. Presence Updates
1.  `PresenceService` observes `AppLifecycleState`.
2.  **Resumed**: Calls `_syncPresenceToRemote(isOnline: true)`.
3.  **Paused/Detached**: Calls `_syncPresenceToRemote(isOnline: false)`.
4.  Firestore updates `users/{uid}/isOnline` and `lastSeen`.
5.  *Trade-off*: This is "fire-and-forget"; if the OS kills the app instantly, the "offline" update might not send (hence "Last Seen" timestamp).

## 6. Offline Strategy

RealMe employs a **Hybrid Offline Strategy**:

1.  **Firestore Persistence**: Enabled by default. Allows the app to read previously loaded messages and queue writes while the app is running.
2.  **Hive Outbox**:
    -   **Purpose**: Explicitly persists failed messages across app restarts if the Firestore SDK cache is cleared or unreliable.
    -   **Mechanism**: Messages failing the primary write path are caught and stored in a generic `pending_messages` Hive box.
    -   **Sync**: On app startup (or connectivity restoration), `HiveService` can iterate through this box and retry sending.

## 7. Error Handling Strategy

We avoid `try-catch` blocks in the UI. Instead, we use a functional error handling approach:

-   **`Result<T>` Type**: A custom sealed class union (`Success<T>` | `Failure<T>`).
-   **Repositories**: Catch all exceptions (FirebaseException, PlatformException), log them, and verify them into domain-specific `AppError` objects.
-   **UI Consumption**: Controllers switch on the `Result`:
    ```dart
    result.fold(
      (data) => state = AsyncData(data),
      (error) => state = AsyncError(error),
    );
    ```
-   **No Silent Failures**: Even background services (like Notification init) log errors to the console (`debugPrint`) for observability.

## 8. Testing Strategy

-   **Unit Tests (`test/`)**:
    -   Focus on **Repositories** and **Use Cases**.
    -   Mocking: `mockito` is used to mock Firebase and unrelated services.
    -   Coverage: Verifies that data is correctly mapped and that the `Result` type accurately reflects success/failure states.
-   **Widget Tests**:
    -   Focus on **Screens** (e.g., `ChatScreen`).
    -   Verifies that the UI correctly responds to stream states (loading, data, error).

## 9. Security Considerations

-   **Data Access**: Firestore Security Rules (not included in repo, but assumed) should restrict `chats/{chatId}` read/write to only the two participants (`uid` in `chatId`).
-   **API Keys**: `firebase_options.dart` is typically git-ignored in open source, but included here as a placeholder. In production, keys are unrestricted but tied to whitelisted package names/SHA-1 fingerprints.

## 10. Performance Considerations

-   **List Rendering**: `ChatScreen` uses `ListView.builder` with `reverse: true`. This ensures `O(1)` access to the newest messages at the bottom and efficient rendering of large histories.
-   **Disposable Providers**: Heavy resources (Microphone, AudioPlayer) are managed by `autoDispose` providers to prevent memory leaks.
-   **Stream Subscriptions**: Firestore streams are managed by Riverpod (`ref.watch`), which automatically cancels subscriptions when the UI is disposed.

## 11. Trade-offs & Limitations

1.  **Chat ID Generation**:
    -   *Implementation*: A canonical ID is generated by sorting UIDs: `hash(uid1_uid2)`.
    -   *Limitation*: This strictly supports 1-on-1 chats. Group chats would require a separate `ChatRoom` collection with a member list.
2.  **Client-Side Timestamps**:
    -   *Limitation*: Messages rely on `FieldValue.serverTimestamp()` for ordering. In rare race conditions (exact same millisecond), order is indeterminate.
3.  **Presence Accuracy**:
    -   *Limitation*: Relies on the client reporting its state. A crash keeps the user "Online" until a timeout or server-side function cleans it up (TTL).
4.  **Pagination**:
    -   *Current*: Loads the latest query snapshot.
    -   *Future*: Should implement `limit(20)` and lazy loading for infinite scroll.

## 12. How to Run

1.  **Prerequisites**:
    -   Flutter SDK (3.x+)
    -   Firebase Project

2.  **Setup**:
    ```bash
    # Clone the repository
    git clone https://github.com/your-username/real-me.git
    cd real-me

    # Install dependencies
    flutter pub get

    # Configure Firebase (Using FlutterFire CLI)
    flutterfire configure
    # Select your project and platforms (Android/iOS)
    # This replaces lib/firebase_options.dart with real credentials
    ```

3.  **Run**:
    ```bash
    flutter run
    ```

## 13. Project Maturity Notes

This project differs from typical tutorials in specific ways:
-   **Strict Layering**: No Firebase imports in UI code.
-   **Explicit Lifecycle**: managing `didChangeAppLifecycleState` for presence.
-   **Static Analysis**: Adherence to strict linting rules (`flutter_lints` enabled).
-   **Documentation**: Code is self-documenting via descriptive naming and architecture-focused comments.

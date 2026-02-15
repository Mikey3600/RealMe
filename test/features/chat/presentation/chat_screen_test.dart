import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_me/features/chat/domain/message_entity.dart';
import 'package:real_me/features/chat/presentation/chat_screen.dart';

void main() {
  testWidgets('ChatScreen shows messages and input field',
      (WidgetTester tester) async {
    // Arrange
    final messages = [
      MessageEntity(
        id: '1',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Hello World',
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatMessagesProvider('user2').overrideWith((ref) => Stream.value(messages)),
        ],
        child: const MaterialApp(
          home: ChatScreen(otherUserId: 'user2'),
        ),
      ),
    );

    await tester.pump(); // Process stream

    // Assert
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.byKey(const Key('message_input')), findsOneWidget);
    expect(find.byKey(const Key('send_button')), findsOneWidget);
  });
}

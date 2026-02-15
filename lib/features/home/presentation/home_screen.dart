import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder for Phase 5 (Chat List)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RealMe'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
// Demo Users List
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDemoUserTile(context, 'User A', 'user_a_id'),
          _buildDemoUserTile(context, 'User B', 'user_b_id'),
          _buildDemoUserTile(context, 'Test User', 'test_user_id'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement "New Chat" logic or UI
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildDemoUserTile(BuildContext context, String name, String id) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceHighlight,
          child: Text(name[0], style: const TextStyle(color: AppColors.primary)),
        ),
        title: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: const Text('Tap to chat', style: TextStyle(color: AppColors.textFaint)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(otherUserId: id),
            ),
          );
        },
      ),
    );
  }
}

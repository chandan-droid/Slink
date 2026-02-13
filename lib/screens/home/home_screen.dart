import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../data/services/api_service.dart';
import '../../providers/providers.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../../widgets/user_tile.dart';
import '../../widgets/online_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Connect WebSocket if not connected
    await authProvider.connectWebSocket();

    // Initialize chat provider
    chatProvider.init();

    // Fetch users
    await chatProvider.fetchUsers();
  }

  Future<void> _handleRefresh() async {
    await context.read<ChatProvider>().fetchUsers();
  }

  /// ✅ FIXED: Uses correct response from ApiService.startChat()
  Future<void> _navigateToChat(UserModel user) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final apiService = ApiService(); // You can also inject via Provider if registered

    if (authProvider.currentUser == null) return;

    try {
      // Request backend to get or create the real chatId
      final response = await apiService.startChat(user.id);

      if (response.isSuccess && response.data != null) {
        final chatId = response.data!; // ✅ Already a String from ApiResponse<String>

        // Store chat context in provider
        chatProvider.setCurrentChat(chatId, user.id);

        // Navigate to ChatScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              recipient: user,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: ${response.error ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.chats,
            style: AppTextStyles.h3,
          ),
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              return Row(
                children: [
                  OnlineIndicator(isOnline: chat.isConnected, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    chat.isConnected ? AppStrings.connected : AppStrings.connecting,
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  if (auth.currentUser != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              auth.currentUser!.username[0].toUpperCase(),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            auth.currentUser!.username,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    onPressed: _handleLogout,
                    tooltip: AppStrings.logout,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chat, _) {
        if (chat.isLoading && chat.users.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (chat.error != null && chat.users.isEmpty) {
          return _buildErrorState(chat.error!);
        }

        final otherUsers = chat.users
            .where((u) => u.id != auth.currentUser?.id)
            .toList();

        if (otherUsers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return UserTile(
                user: user,
                isTyping: chat.isUserTyping(user.id),
                onTap: () => _navigateToChat(user),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noChatsYet,
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.startChatting,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.errorOccurred,
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

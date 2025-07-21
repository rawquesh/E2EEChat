import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../backend/chats/chat_repository.dart';
import '../../../backend/chats/chats_controller.dart';
import '../../../backend/chats/chats_provider.dart';
import '../components/chat_list_item.dart';
import 'chat_message_screen.dart';

// Main Chat List Screen
class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with MySafeState {
  late ChatController _chatController;
  late ChatProvider _chatProvider;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatController = ChatController(chatProvider: _chatProvider);
    _chatController.loadStoredChatUsers();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _chatController.searchUser(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          // statusBarColor: Colors.black, // Set your desired color for the status bar
          statusBarIconBrightness: Brightness.light, // Or Brightness.dark for dark icons
          systemNavigationBarColor: Colors.white, // Set your desired color for the navigation bar
          systemNavigationBarIconBrightness: Brightness.light, // Or Brightness.light for light icons
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DarkCrypt',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Modern Search Bar
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isSearchFocused
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSearchFocused
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          width: _isSearchFocused ? 2 : 1,
                        ),
                        boxShadow: _isSearchFocused
                            ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 4))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: _isSearchFocused
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onTap: () => setState(() => _isSearchFocused = true),
                              onTapOutside: (_) => setState(() => _isSearchFocused = false),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Search conversations...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _onSearch(),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => _onSearch(),
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chat List Section
              Expanded(
                child: AnimatedBuilder(
                  animation: _chatProvider,
                  builder: (context, _) {
                    final state = _chatProvider.searchState.get();

                    if (state == SearchState.loading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
                              child: LoadingWidget(),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Searching...',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state == SearchState.empty) {
                      return _buildEmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'User not found',
                        subtitle: 'Try searching with a different name',
                      );
                    }

                    if (state == SearchState.error) {
                      return _buildEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Search Error',
                        subtitle: 'Something went wrong. Please try again.',
                      );
                    }

                    final users = _chatProvider.chatUsers.getList();
                    if (users.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No conversations',
                        subtitle: 'Start chatting to see your conversations here',
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(bottom: 8),
                          child: ChatListItem(
                            user: user,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => ChatMessageScreen(user: user),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOutCubic;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    return SlideTransition(position: animation.drive(tween), child: child);
                                  },
                                  transitionDuration: Duration(milliseconds: 300),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

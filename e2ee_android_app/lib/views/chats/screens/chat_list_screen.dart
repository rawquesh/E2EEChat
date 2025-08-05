// import 'package:e2ee_android_app/utils/storage_manager.dart';
// import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../backend/authentication/authentication_provider.dart';
import '../../../backend/chats/chats_controller.dart';
import '../../../backend/chats/chats_provider.dart';
import '../../../utils/storage_manager.dart';
import '../components/chat_list_item.dart';
import 'chat_message_screen.dart';
// import 'package:e2ee_models_app/models/chats/chat_message_model.dart';

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
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatController = ChatController(chatProvider: _chatProvider);
    _chatController.loadStoredChatUsers();

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _chatController.searchUser(query);
      _searchFocusNode.unfocus();
    }
  }

  void _confirmDeleteChat(ChatUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat'),
        content: Text('Delete conversation with ${user.nickname}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatController.deleteChat(user.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _chatProvider.resetSearch();
    _chatController.loadStoredChatUsers();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  void _showCreateGroupDialog() {
    final groupNameController = TextEditingController();
    final userSearchController = TextEditingController();
    final List<ChatUserModel> selectedUsers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Create New Group', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final searchResults = chatProvider.groupCreationSearchResults.getList();
                  final searchState = chatProvider.groupSearchState.get();

                  return SingleChildScrollView(
                    child: Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: groupNameController,
                            decoration: InputDecoration(
                              labelText: 'Group Name',
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: userSearchController,
                            decoration: InputDecoration(
                              labelText: 'Search Users',
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  final query = userSearchController.text.trim();
                                  if (query.isNotEmpty) {
                                    _chatController.searchUsers(query);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (searchState == SearchState.loading)
                            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
                          else if (searchState == SearchState.empty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("No users found", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            )
                          else if (searchState == SearchState.error)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("An error occurred", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            )
                          else if (searchResults.isNotEmpty)
                            Container(
                              height: 150,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.background, borderRadius: BorderRadius.circular(12)),
                              child: ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = searchResults[index];
                                  final isSelected = selectedUsers.any((selectedUser) => selectedUser.id == user.id);
                                  return ListTile(
                                    title: Text(user.nickname, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    trailing: Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            if (!isSelected) {
                                              selectedUsers.add(user);
                                            }
                                          } else {
                                            selectedUsers.removeWhere((selectedUser) => selectedUser.id == user.id);
                                          }
                                        });
                                      },
                                      activeColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (selectedUsers.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: selectedUsers
                                  .map(
                                    (user) => Chip(
                                      label: Text(user.nickname, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      deleteIcon: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                                      onDeleted: () {
                                        setState(() {
                                          selectedUsers.removeWhere((selectedUser) => selectedUser.id == user.id);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _chatProvider.resetGroupSearch();
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (groupNameController.text.isNotEmpty && selectedUsers.isNotEmpty) {
                      final groupName = groupNameController.text.trim();
                      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
                      final receivers = selectedUsers.map((user) => user.id).toList();
                      final myUserId = await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId) ?? '';
                      final authProvider = context.read<AuthenticationProvider>();
                      final sharedAvatar = await SharedPrefManager().getString(MySharedPreferenceVariables.avatarUrl);
                      final avatarUrl = sharedAvatar?.isNotEmpty == true ? sharedAvatar! : authProvider.userModel.get()?.profilePicture ?? '';
                      MyPrint.printOnConsole('chat list screen Avatar url: $avatarUrl');
                      if (myUserId.isNotEmpty && !receivers.contains(myUserId)) {
                        receivers.add(myUserId);
                      }

                      final group = ChatUserModel(
                        id: groupId,
                        groupName: groupName,
                        type: ChatRoomType.Group,
                        receivers: receivers,
                        lastMessage: 'Group created',
                        lastMessageTime: DateTime.now().toIso8601String(),
                        avatar: avatarUrl,
                      );

                      MyPrint.printOnConsole('XXGroup created: ${group.toMap()}');
                      _chatController.addUserToChatList(group);

                      _chatProvider.currentOpponent.set(value: group);

                      _chatProvider.resetGroupSearch();
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatMessageScreen(chatInfo: group)));
                    }
                  },
                  child: Text('Create', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light, systemNavigationBarColor: Colors.white, systemNavigationBarIconBrightness: Brightness.dark),
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
                    colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0.8), Theme.of(context).colorScheme.surface.withValues(alpha: 0.4)],
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
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, letterSpacing: -0.5),
                            ),
                            Text(
                              'Chat',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                          onPressed: _showCreateGroupDialog,
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
                        color: _isSearchFocused ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSearchFocused ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          width: _isSearchFocused ? 2 : 1,
                        ),
                        boxShadow: _isSearchFocused ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 4))] : [],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: _isSearchFocused ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Search conversations...',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w400),
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
                                    onTap: _clearSearch,
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 16),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _onSearch,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state == SearchState.empty) {
                      return _buildEmptyState(icon: Icons.person_search_rounded, title: 'User not found', subtitle: 'Try searching with a different name');
                    }

                    if (state == SearchState.error) {
                      return _buildEmptyState(icon: Icons.error_outline_rounded, title: 'Search Error', subtitle: 'Something went wrong. Please try again.');
                    }

                    final users = _chatProvider.chatUsers.getList();
                    if (users.isEmpty && state == SearchState.initial) {
                      return _buildEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No conversations', subtitle: 'Start chatting to see your conversations here');
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        MyPrint.printOnConsole('XXGroup ListView.builder: ${users[index].toMap()}');
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
                                  pageBuilder: (context, animation, secondaryAnimation) => ChatMessageScreen(chatInfo: user),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOutCubic;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    return SlideTransition(position: animation.drive(tween), child: child);
                                  },
                                  transitionDuration: Duration(milliseconds: 300),
                                ),
                              ).then((_) {
                                // After returning from chat, reload users to reflect any changes
                                _chatController.loadStoredChatUsers();
                              });
                            },
                            onLongPress: () => _confirmDeleteChat(user),
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

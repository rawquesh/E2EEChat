import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:flutter/material.dart';
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

class _ChatListScreenState extends State<ChatListScreen> with MySafeState{
  late ChatController _chatController;
  late ChatProvider _chatProvider;
  final TextEditingController _searchController = TextEditingController();

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
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 10),
            Text(
              'DarkCrypt Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search user',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: themeData.colorScheme.onSurface, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: themeData.colorScheme.onSurface, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: themeData.colorScheme.onSurface, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.check), onPressed: _onSearch),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _chatProvider,
                builder: (context, _) {
                  final state = _chatProvider.searchState.get();
                  if (state == SearchState.loading) {
                    return const Center(child: LoadingWidget());
                  }

                  if (state == SearchState.empty) {
                    return const Center(child: Text('User not found'));
                  }

                  if (state == SearchState.error) {
                    return const Center(child: Text('Error searching user'));
                  }
                  final users = _chatProvider.chatUsers.getList();
                  if (users.isEmpty) {
                    return const Center(child: Text('No chats found'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ChatListItem(
                        user: user,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatMessageScreen(user: user),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

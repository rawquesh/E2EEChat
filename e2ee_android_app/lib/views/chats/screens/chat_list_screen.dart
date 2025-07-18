import 'package:e2ee_models_app/utils/my_safe_state.dart';
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

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatController _chatController;
  late ChatProvider _chatProvider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatController = ChatController(chatProvider: _chatProvider);
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _chatController.searchUser(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Search user'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _chatProvider,
              builder: (context, _) {
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
    );
  }
}

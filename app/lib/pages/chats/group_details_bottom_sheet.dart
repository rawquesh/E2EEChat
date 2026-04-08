import 'package:e2ee_android_app/constants/app_constants.dart';
import 'package:e2ee_android_app/models/chats/chat_user_model.dart';
import 'package:e2ee_android_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import 'package:e2ee_android_app/backend/chats/chat_repository.dart';
import 'package:e2ee_android_app/managers/secure_storage_manager.dart';

class GroupDetailsBottomSheet extends StatefulWidget {
  final ChatUserModel groupInfo;

  const GroupDetailsBottomSheet({Key? key, required this.groupInfo}) : super(key: key);

  @override
  State<GroupDetailsBottomSheet> createState() => _GroupDetailsBottomSheetState();
}

class _GroupDetailsBottomSheetState extends State<GroupDetailsBottomSheet> with MySafeState {
  late Future<List<ChatUserModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchGroupMembers();
  }

  Future<List<ChatUserModel>> _fetchGroupMembers() async {
    final List<ChatUserModel> members = [];
    final token = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken) ?? '';
    if (widget.groupInfo.receivers != null) {
      for (final userId in widget.groupInfo.receivers!) {
        final user = await ChatRepository().fetchChatUser(userId: userId, token: token);
        if (user != null) {
          members.add(user);
        }
      }
    }
    return members;
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            widget.groupInfo.groupName ?? 'Group Members',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<ChatUserModel>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading members'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                final members = snapshot.data!;
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(member.nickname.substring(0, 1))),
                      title: Text(member.nickname),
                      subtitle: Text(member.username),
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

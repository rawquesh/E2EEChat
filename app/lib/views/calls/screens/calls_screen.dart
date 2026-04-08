import 'package:e2ee_android_app/backend/chats/chats_controller.dart';
import 'package:e2ee_android_app/core/navigation/navigation_arguments.dart';
import 'package:e2ee_android_app/core/navigation/navigation_operation_parameters.dart';
import 'package:e2ee_android_app/core/navigation/navigation_type.dart';
import 'package:e2ee_android_app/configs/styles.dart';
import 'package:e2ee_android_app/models/chats/chat_user_model.dart';
import 'package:e2ee_android_app/core/my_safe_state.dart';
import 'package:e2ee_android_app/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../../backend/chats/chats_provider.dart';
import '../../../backend/navigation/navigation_controller.dart';
import '../../../backend/webrtc/call_provider.dart';
// import '../components/call_details_bottom_sheet.dart';
import '../components/call_list_item.dart';

class CallRecord {
  final String id;
  final String contactName;
  final String avatar;
  final CallType callType;
  final CallStatus callStatus;
  final DateTime timestamp;
  final String phoneNumber;
  final int duration;

  CallRecord({
    required this.id,
    required this.contactName,
    required this.avatar,
    required this.callType,
    required this.callStatus,
    required this.timestamp,
    required this.phoneNumber,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactName': contactName,
      'avatar': avatar,
      'callType': callType.index,
      'callStatus': callStatus.index,
      'timestamp': timestamp.toIso8601String(),
      'phoneNumber': phoneNumber,
      'duration': duration,
    };
  }

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'],
      contactName: map['contactName'],
      avatar: map['avatar'],
      callType: CallType.values[map['callType']],
      callStatus: CallStatus.values[map['callStatus']],
      timestamp: DateTime.parse(map['timestamp']),
      phoneNumber: map['phoneNumber'],
      duration: map['duration'],
    );
  }
}

enum CallType { voice }

enum CallStatus { missed, incoming, outgoing }

class CallHistoryRepository {
  static const String _boxName = 'call_history';

  Future<Box<Map<dynamic, dynamic>>> _openBox() async {
    return await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Future<void> addCall(CallRecord call) async {
    final box = await _openBox();
    await box.put(call.id, call.toMap());
  }

  Future<List<CallRecord>> getAllCalls() async {
    final box = await _openBox();
    if (box.isEmpty) return [];
    return box.values
        .map((e) => CallRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

class CallsScreen extends StatefulWidget {
  @override
  _CallsScreenState createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> with MySafeState {
  final CallHistoryRepository _callHistoryRepository = CallHistoryRepository();
  late final ChatController _chatsController;
  List<CallRecord> _calls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatsController = ChatController(
      chatProvider: context.read<ChatProvider>(),
    );
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    if (mounted) setState(() => _isLoading = true);
    final calls = await _callHistoryRepository.getAllCalls();
    if (mounted) {
      setState(() {
        _calls = calls;
        _isLoading = false;
      });
    }
  }

  // void _showCallDetails(CallRecord call) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => CallDetailsBottomSheet(call: call),
  //   );
  // }

  void _startCall(ChatUserModel user) async {
    final callProvider = context.read<CallProvider>();
    final callController = callProvider.callController;

    await callController.startCall(
      user.id,
      receiverName: user.nickname,
      receiverAvatar: user.avatar,
    );

    if (mounted) {
      NavigationController.navigateToVoiceCallScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamed,
        ),
        arguments: VoiceCallScreenNavigationArguments(user: user),
      ).then((_) {
        // Refresh call history when call screen is popped
        _loadCallHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'Recent Calls',
          style: TextStyle(
            color: Styles.grey400,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[600]),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _CallSearchDelegate(
                  chatsController: _chatsController,
                  onCall: _startCall,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _calls.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _calls.length,
              itemBuilder: (context, index) {
                final call = _calls[index];
                return CallListItem(
                  call: call,
                  onTap: () {},
                  onRedial: () {
                    _startCall(
                      ChatUserModel(
                        id: call.phoneNumber,
                        nickname: call.contactName,
                        avatar: call.avatar,
                        lastMessage: '',
                        lastMessageTime: '',
                        isOnline: false,
                        unreadCount: 0,
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: _CallSearchDelegate(
              chatsController: _chatsController,
              onCall: _startCall,
            ),
          );
        },
        backgroundColor: Styles.grey400,
        elevation: 4,
        child: const Icon(Icons.add_call, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No recent calls',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap search to start a call',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CallSearchDelegate extends SearchDelegate<ChatUserModel?> {
  final ChatController chatsController;
  final Function(ChatUserModel) onCall;

  _CallSearchDelegate({required this.chatsController, required this.onCall});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) return Container();
    chatsController.searchUser(query);
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        if (provider.searchState.get() == SearchState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.searchState.get() == SearchState.empty) {
          return const Center(child: Text("No user found."));
        }
        final users = provider.chatUsers.getList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildSearchResultItem(context, user);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Widget _buildSearchResultItem(BuildContext context, ChatUserModel user) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            user.avatar,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        user.nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: IconButton(
        icon: Icon(Icons.call, color: theme.primaryColor, size: 28),
        onPressed: () {
          close(context, user);
          onCall(user);
        },
      ),
      onTap: () {
        close(context, user);
        onCall(user);
      },
    );
  }
}

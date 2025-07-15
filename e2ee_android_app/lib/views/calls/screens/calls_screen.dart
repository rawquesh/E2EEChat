import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../components/call_details_bottom_sheet.dart';
import '../components/call_list_item.dart';
import '../components/contact_picket_bottom_sheet.dart';

class CallRecord {
  final String id;
  final String contactName;
  final String avatar;
  final CallType callType;
  final CallStatus callStatus;
  final DateTime timestamp;
  final String phoneNumber;
  final int duration; // in seconds, 0 for missed calls

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
}

enum CallType { voice }
enum CallStatus { missed, incoming, outgoing }

// Dummy Data
class CallsData {
  static List<CallRecord> recentCalls = [
    CallRecord(
      id: '1',
      contactName: 'Sarah Johnson',
      avatar: 'S',
      callType: CallType.voice,
      callStatus: CallStatus.missed,
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      phoneNumber: '+1 234 567 8901',
      duration: 0,
    ),
    CallRecord(
      id: '2',
      contactName: 'Mike Chen',
      avatar: 'M',
      callType: CallType.voice,
      callStatus: CallStatus.outgoing,
      timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      phoneNumber: '+1 234 567 8902',
      duration: 180,
    ),
    CallRecord(
      id: '3',
      contactName: 'Emily Davis',
      avatar: 'E',
      callType: CallType.voice,
      callStatus: CallStatus.incoming,
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      phoneNumber: '+1 234 567 8903',
      duration: 300,
    ),
    CallRecord(
      id: '4',
      contactName: 'Alex Wilson',
      avatar: 'A',
      callType: CallType.voice,
      callStatus: CallStatus.outgoing,
      timestamp: DateTime.now().subtract(Duration(hours: 4)),
      phoneNumber: '+1 234 567 8904',
      duration: 120,
    ),
    CallRecord(
      id: '5',
      contactName: 'Lisa Zhang',
      avatar: 'L',
      callType: CallType.voice,
      callStatus: CallStatus.missed,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      phoneNumber: '+1 234 567 8905',
      duration: 0,
    ),
    CallRecord(
      id: '6',
      contactName: 'David Brown',
      avatar: 'D',
      callType: CallType.voice,
      callStatus: CallStatus.incoming,
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 3)),
      phoneNumber: '+1 234 567 8906',
      duration: 450,
    ),
    CallRecord(
      id: '7',
      contactName: 'Anna Smith',
      avatar: 'A',
      callType: CallType.voice,
      callStatus: CallStatus.outgoing,
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      phoneNumber: '+1 234 567 8907',
      duration: 90,
    ),
    CallRecord(
      id: '8',
      contactName: 'John Taylor',
      avatar: 'J',
      callType: CallType.voice,
      callStatus: CallStatus.missed,
      timestamp: DateTime.now().subtract(Duration(days: 3)),
      phoneNumber: '+1 234 567 8908',
      duration: 0,
    ),
  ];

  static List<String> contacts = [
    'Sarah Johnson',
    'Mike Chen',
    'Emily Davis',
    'Alex Wilson',
    'Lisa Zhang',
    'David Brown',
    'Anna Smith',
    'John Taylor',
    'Robert Garcia',
    'Maria Rodriguez',
  ];
}

// Main Calls Screen
class CallsScreen extends StatefulWidget {
  @override
  _CallsScreenState createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> with MySafeState {
  List<CallRecord> calls = CallsData.recentCalls;

  void _showCallDetails(CallRecord call) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CallDetailsBottomSheet(call: call),
    );
  }

  void _redialCall(CallRecord call) {
    // Simulate adding a new outgoing call
    setState(() {
      calls.insert(0, CallRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactName: call.contactName,
        avatar: call.avatar,
        callType: CallType.voice,
        callStatus: CallStatus.outgoing,
        timestamp: DateTime.now(),
        phoneNumber: call.phoneNumber,
        duration: 0,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${call.contactName}...'),
        backgroundColor: Color(0xFFE6A532),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startNewCall() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContactPickerBottomSheet(
        onContactSelected: (contactName) {
          setState(() {
            calls.insert(0, CallRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              contactName: contactName,
              avatar: contactName[0].toUpperCase(),
              callType: CallType.voice,
              callStatus: CallStatus.outgoing,
              timestamp: DateTime.now(),
              phoneNumber: '+1 234 567 ${(1000 + calls.length).toString().substring(1)}',
              duration: 0,
            ));
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling $contactName...'),
              backgroundColor: Color(0xFFE6A532),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          'Recent Calls',
          style: TextStyle(
            color: Color(0xFFE6A532),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: calls.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No recent calls',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a new call using the button below',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                return CallListItem(
                  call: call,
                  onTap: () => _showCallDetails(call),
                  onRedial: () => _redialCall(call),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewCall,
        backgroundColor: Color(0xFFE6A532),
        elevation: 4,
        child: Icon(
          Icons.add_call,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

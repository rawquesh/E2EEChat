import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../screens/calls_screen.dart';

class CallListItem extends StatefulWidget {
  final CallRecord call;
  final VoidCallback onTap;
  final VoidCallback onRedial;

  const CallListItem({
    Key? key,
    required this.call,
    required this.onTap,
    required this.onRedial,
  }) : super(key: key);

  @override
  State<CallListItem> createState() => _CallListItemState();
}

class _CallListItemState extends State<CallListItem> with MySafeState {
  String _formatCallTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (widget.call.callStatus) {
      case CallStatus.missed:
        return Color(0xFFE53E3E);
      case CallStatus.incoming:
        return Color(0xFF4CAF50);
      case CallStatus.outgoing:
        return Color(0xFFE6A532);
    }
  }

  IconData _getStatusIcon() {
    switch (widget.call.callStatus) {
      case CallStatus.missed:
        return Icons.call_received;
      case CallStatus.incoming:
        return Icons.call_received;
      case CallStatus.outgoing:
        return Icons.call_made;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: widget.onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFE6A532),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              widget.call.avatar,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.call.contactName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.call.callStatus == CallStatus.missed
                      ? Color(0xFFE53E3E)
                      : themeData.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              _getStatusIcon(),
              size: 14,
              color: _getStatusColor(),
            ),
            SizedBox(width: 4),
            Text(
              _formatCallTime(widget.call.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (widget.call.duration > 0) ...[
              SizedBox(width: 8),
              Text(
                '• ${_formatDuration(widget.call.duration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.phone,
            color: Color(0xFFE6A532),
            size: 24,
          ),
          onPressed: widget.onRedial,
        ),
      ),
    );
  }
}
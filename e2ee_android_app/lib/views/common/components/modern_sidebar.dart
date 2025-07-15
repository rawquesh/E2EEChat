import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class ModernSidebar extends StatelessWidget {
  final SidebarXController controller;

  const ModernSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.only(top: 16, left: 8, right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F3),
          borderRadius: BorderRadius.circular(16),
        ),
        hoverColor: const Color(0xFFECECEC),
        textStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 8),
        selectedItemTextPadding: const EdgeInsets.only(left: 8),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedItemDecoration: BoxDecoration(
          color: Color(0xFFFDF7EC),
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: const IconThemeData(
          color: Colors.grey,
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.black,
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: Color(0xFFF9F7F3),
        ),
        margin: EdgeInsets.only(top: 16, left: 8, right: 8),
        padding: EdgeInsets.symmetric(vertical: 8),
        textStyle: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        selectedItemDecoration: BoxDecoration(
          color: Color(0xFFFDF7EC),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      items: const [
        SidebarXItem(icon: Icons.home, label: 'My Page'),
        SidebarXItem(icon: Icons.video_library_outlined, label: 'Library'),
        SidebarXItem(icon: Icons.groups_outlined, label: 'Audience'),
        SidebarXItem(icon: Icons.bar_chart_outlined, label: 'Insights'),
        SidebarXItem(icon: Icons.account_balance_wallet_outlined, label: 'Payouts'),
        SidebarXItem(icon: Icons.local_offer_outlined, label: 'Promotions'),
        SidebarXItem(icon: Icons.chat_bubble_outline, label: 'Community'),
        SidebarXItem(icon: Icons.notifications_none, label: 'Notifications'),
        SidebarXItem(icon: Icons.settings_outlined, label: 'Settings'),
      ],
    );
  }
}
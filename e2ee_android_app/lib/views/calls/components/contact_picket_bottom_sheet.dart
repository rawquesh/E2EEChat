import 'package:flutter/material.dart';

import '../screens/calls_screen.dart';

class ContactPickerBottomSheet extends StatelessWidget {
  final Function(String) onContactSelected;

  const ContactPickerBottomSheet({Key? key, required this.onContactSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Select Contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: CallsData.contacts.length,
              itemBuilder: (context, index) {
                final contact = CallsData.contacts[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFE6A532),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        contact[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    contact,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.phone,
                    color: Color(0xFFE6A532),
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onContactSelected(contact);
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
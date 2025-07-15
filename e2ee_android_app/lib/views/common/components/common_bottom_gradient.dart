import 'package:flutter/material.dart';
class CommonBottomGradient extends StatelessWidget {
  const CommonBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 100, // Adjust height based on how much fade you want
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00FFFFFF), // Fully transparent white
                Color(0x55FFFFFF), // Light faded white
                Color(0xFFFFFFFF),
              ],
              stops: [0.2,0.5,0.9]
          ),
        ),
      ),
    );
  }
}

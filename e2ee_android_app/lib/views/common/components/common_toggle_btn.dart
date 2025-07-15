import 'package:flutter/material.dart';

class CommonToggleBtn extends StatefulWidget {
  final double width;
  final double height;
  final Color onColor;
  final Color offColor;
  final ValueChanged<bool>? onChanged;

  const CommonToggleBtn({
    super.key,
    this.width = 60,
    this.height = 30,
    this.onColor = Colors.green,
    this.offColor = Colors.grey,
    this.onChanged,
  });

  @override
  _CommonToggleBtnState createState() => _CommonToggleBtnState();
}

class _CommonToggleBtnState extends State<CommonToggleBtn> {
  bool isToggled = false;

  void toggle() {
    setState(() {
      isToggled = !isToggled;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(isToggled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          color: isToggled ? widget.onColor : widget.offColor,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: isToggled ? widget.width - widget.height : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.height,
                height: widget.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'common_custom_button.dart';


class CommonEmptyScreenCard extends StatelessWidget {
  final String primaryText;
  final String image;
  final String? secondaryText;
  final String ?buttonText;
  final VoidCallback onPressed;
  final double imageHeight;
  final double imageWidth;
  const CommonEmptyScreenCard({super.key, required this.primaryText, required this.image, required this.secondaryText,required  this.buttonText, required  this.onPressed, required this.imageHeight, required this.imageWidth});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return  Container(
      color: themeData.colorScheme.onPrimary,
      padding: EdgeInsets.only(bottom: 30),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(image,
                height: imageHeight,
                width: imageWidth,),
            ],
          ),
          SizedBox(height: 5,),
          Text(primaryText,
            style: themeData.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xff777777),),),
          SizedBox(height: 5,),
          secondaryText != null ? Text(secondaryText!,
              style: themeData.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xff777777),),):
          Container(),
          SizedBox(height: 20,),
         CommonCustomButton(text: buttonText!,onPressed: onPressed,fontSize: 18,height: 40,width: 120,)
         //  GestureDetector(
         //    onTap: onPressed ?? (){},
         //    child: Container(
         //      padding: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
         //      decoration: BoxDecoration(
         //        color: Color(0xff139E24),
         //        borderRadius: BorderRadius.circular(10),
         //      ),
         //      child:
         //      buttonText != null? Text(buttonText!,
         //          style: themeData.textTheme.bodyMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xffFFFFFF),),):
         //      Container(),
         //    ),
         //  )
        ],
      ),
    )
    ;
  }
}

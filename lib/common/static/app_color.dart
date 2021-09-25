import 'package:flutter/material.dart';

class AppColor {
  static Color yellow = Color(0xffFFC222);
  static Color selected = Color(0xff01B1A5);
  static Color black = Colors.black;
  static Color grey = Color(0xffF5F5F5);
  static Color darkGrey = Color(0xff8a8a8a);
  static Color white = Colors.white;
  static Color red = Color(0xfff32221);
  static Color bgDark = Color(0xFF1A1A1A);

  static Color themeBasedColor(context, darkColor, lightColor) {
    return Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
  }
}

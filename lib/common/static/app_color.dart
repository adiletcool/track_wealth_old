import 'package:flutter/material.dart';

class AppColor {
  static Color selected = Color(0xff01B1A5);
  static Color yellow = Color(0xffFFC222);
  static Color bgDark = Color(0xFF1A1A1A);
  static Color black = Colors.black;
  static Color white = Colors.white;
  static Color red = Color(0xfff32221);
  static Color redBlood = Color(0xffE00019);
  static Color grey = Color(0xffF5F5F5);
  static Color lightGrey = Color(0xffF9F9FB);
  static Color greyTitle = Color(0xffA3A3A3);
  static Color darkGrey = Color(0xff8a8a8a);
  static Color darkestGrey = Color(0xff1F1F1F);
  static Color lightBlue = Color(0xff21212B);
  static Color darkBlue = Color(0xff181820);
  static Color indigo = Color(0xff64668A);

  static Color themeBasedColor(context, darkColor, lightColor) {
    return Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
  }
}

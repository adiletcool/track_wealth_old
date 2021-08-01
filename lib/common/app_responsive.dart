import 'package:flutter/material.dart';

class AppResponsive {
  static bool isMobile(context) => MediaQuery.of(context).size.width < 800;
  static bool isTablet(context) => MediaQuery.of(context).size.width < 1130 && MediaQuery.of(context).size.width >= 800;
  static bool isDesktop(context) => MediaQuery.of(context).size.width >= 1130;
}

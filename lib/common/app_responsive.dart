import 'package:flutter/material.dart';

class AppResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const AppResponsive({Key key, @required this.mobile, this.tablet, @required this.desktop}) : super(key: key);

  static bool isMobile(context) => MediaQuery.of(context).size.width < 800;
  static bool isTablet(context) => MediaQuery.of(context).size.width < 1130 && MediaQuery.of(context).size.width >= 800;
  static bool isDesktop(context) => MediaQuery.of(context).size.width >= 1130;

  @override
  Widget build(BuildContext context) {
    // final Size _size = MediaQuery.of(context).size;

    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

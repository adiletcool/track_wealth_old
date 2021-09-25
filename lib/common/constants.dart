import 'package:flutter/material.dart';
import 'package:track_wealth/common/static/app_color.dart';

PreferredSizeWidget simpleAppBar(context, {Widget? title, bool? centerTitle, List<Widget>? actions}) {
  Color bgColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: bgColor),
      onPressed: () => Navigator.pop(context),
    ),
    title: title,
    centerTitle: centerTitle,
    actions: actions,
  );
}

Future<void> delayedScrollDown(
  ScrollController controller, {
  Duration delay = const Duration(milliseconds: 300),
  Duration animationDuration = const Duration(milliseconds: 100),
  Curve animationCurve = Curves.easeOut,
}) async {
  Future.delayed(delay).then(
    (value) => controller.animateTo(
      controller.position.maxScrollExtent,
      curve: animationCurve,
      duration: animationDuration,
    ),
  );
}

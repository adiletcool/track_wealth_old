import 'package:flutter/material.dart';
import 'package:track_wealth/core/util/app_color.dart';

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

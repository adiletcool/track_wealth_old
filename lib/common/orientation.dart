import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppOrientation {
  static bool isPortrait(context) => MediaQuery.of(context).orientation == Orientation.portrait;
}

void setOrientationMode({bool canLandscape = true}) {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    if (canLandscape) DeviceOrientation.landscapeRight,
    if (canLandscape) DeviceOrientation.landscapeLeft,
  ]);
}

import 'package:flutter/material.dart';

class AppOrientation {
  static bool isPortrait(context) => MediaQuery.of(context).orientation == Orientation.portrait;
}

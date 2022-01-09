import 'package:flutter/material.dart';

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

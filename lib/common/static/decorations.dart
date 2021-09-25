import 'package:flutter/material.dart';

import 'app_color.dart';

BoxDecoration roundedBoxDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(10),
);

InputDecoration myInputDecoration = InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  isDense: true,
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColor.selected),
    borderRadius: BorderRadius.circular(10),
  ),
);

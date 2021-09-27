import 'package:flutter/material.dart';
import 'package:track_wealth/common/static/app_color.dart';

class TradesPage extends StatefulWidget {
  @override
  _TradesPageState createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(color: bgColor, child: Center(child: Text('Trades')));
  }
}

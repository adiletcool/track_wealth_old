import 'package:flutter/material.dart';
import 'package:track_wealth/core/util/app_color.dart';

// pie chart по типам активов (их суммарной стоимости)

// при выборе типа отображать treemap (syncfusion)

class AnalysisPage extends StatefulWidget {
  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      color: bgColor,
      child: Center(
        child: Text('Analysis'),
      ),
    );
  }
}

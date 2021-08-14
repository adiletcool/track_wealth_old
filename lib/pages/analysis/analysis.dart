import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';

// pie chart по типам активов (их суммарной стоимости)

// при выборе типа отображать treemap (syncfusion)

class AnalysisPage extends StatefulWidget {
  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(context),
      body: Center(
        child: Text('Analysis'),
      ),
    );
  }
}

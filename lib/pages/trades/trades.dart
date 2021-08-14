import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';

class TradesPage extends StatefulWidget {
  @override
  _TradesPageState createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(context),
      body: Text('Trades'),
    );
  }
}

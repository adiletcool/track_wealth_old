import 'package:flutter/material.dart';
import 'package:track_wealth/core/widgets/simple_app_bar.dart';

class TrendsPage extends StatefulWidget {
  @override
  _TrendsPageState createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(context),
      body: Text('Тренды'),
    );
  }
}

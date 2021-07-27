import 'package:flutter/material.dart';

class DrawerState extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  String selectedItem = 'Портфель'; // selected Drawer Item = Home page name (портфель)

  GlobalKey<ScaffoldState> get scaffoldKey => _globalKey;

  void controlMenu() {
    if (!_globalKey.currentState.isDrawerOpen) {
      _globalKey.currentState.openDrawer();
    }
  }

  void changeSelectedItem(String name) {
    selectedItem = name;
    notifyListeners();
  }
}

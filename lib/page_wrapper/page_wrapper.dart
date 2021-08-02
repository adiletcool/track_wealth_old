import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/drawer_state.dart';
import 'package:track_wealth/pages/dashboard/dashboard.dart';
import 'package:track_wealth/pages/profile/profile.dart';

import 'side_bar/side_bar.dart';

class PageWrapper extends StatefulWidget {
  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  String userName = 'Default';
  User? firebaseUser;
  late String selectedItem;

  Map<String, Widget> getAllPages() => {
        'Профиль': ProfilePage(userName),
        'Портфель': Dashboard(),
      };

  // В зависимости от выбранного айтема меняется отображаемый виджет
  Widget getPage(String newSelectedItem) {
    Map<String, Widget> allPages = getAllPages();
    if (allPages.containsKey(newSelectedItem)) {
      return allPages[newSelectedItem]!;
    } else {
      return Dashboard();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  void setUserName() {
    if (firebaseUser == null)
      userName = 'Default name';
    else {
      if (!["", null].contains(firebaseUser!.displayName))
        userName = firebaseUser!.displayName!;
      else if (!["", null].contains(firebaseUser!.email))
        userName = firebaseUser!.email!.split('@').first;
      else if (!["", null].contains(firebaseUser!.phoneNumber)) userName = firebaseUser!.phoneNumber!;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    firebaseUser = context.watch<User?>();
    setUserName();
    selectedItem = context.watch<DrawerState>().selectedItem;

    return WillPopScope(
      onWillPop: () async {
        if (context.read<DrawerState>().scaffoldKey.currentState!.isDrawerOpen) {
          Navigator.pop(context);
        } else if (selectedItem != 'Портфель') {
          context.read<DrawerState>().changeSelectedItem('Портфель');
        } else {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        key: context.read<DrawerState>().scaffoldKey,
        drawer: !AppResponsive.isDesktop(context)
            ? SideBar(
                selectedItem: selectedItem,
                firebaseUser: firebaseUser,
                userName: userName,
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ! Side Navigation Menu
              if (AppResponsive.isDesktop(context))
                Expanded(
                  flex: 3,
                  child: SideBar(
                    selectedItem: selectedItem,
                    firebaseUser: firebaseUser,
                    userName: userName,
                  ),
                ),
              Expanded(
                flex: 11,
                child: getPage(selectedItem),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

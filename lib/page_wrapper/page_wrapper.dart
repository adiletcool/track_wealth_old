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
  /*late*/ String /*!*/ userName;
  /*late*/ User firebaseUser;
  /*late*/ String selectedItem;

  Map<String, Widget> getAllPages() => {
        'Профиль': ProfilePage(userName),
        'Портфель': Dashboard(),
      };

  // В зависимости от выбранного айтема меняется отображаемый виджет
  Widget /*!*/ getPage(String newSelectedItem) {
    Map<String, Widget> allPages = getAllPages();
    if (allPages.containsKey(newSelectedItem)) {
      return allPages[newSelectedItem];
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
    firebaseUser = context.read<User>();

    if (firebaseUser.displayName != null)
      userName = firebaseUser.displayName;
    else if (firebaseUser.email != null)
      userName = firebaseUser.email.split('@').first;
    else if (firebaseUser.phoneNumber != null)
      userName = firebaseUser.phoneNumber;
    else
      userName = 'Default name';
  }

  @override
  Widget build(BuildContext context) {
    selectedItem = context.watch<DrawerState>().selectedItem;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
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
        backgroundColor: AppColor.sidebar,
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

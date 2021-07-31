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
  String selectedItem;

  Map<String, Widget> pages = {
    'Профиль': ProfilePage(),
    'Портфель': Dashboard(),
  };

  // В зависимости от выбранного айтема меняется отображаемый виджет
  Widget getPage(String selectedItem) {
    if (pages.containsKey(selectedItem)) {
      return pages[selectedItem];
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

  @override
  Widget build(BuildContext context) {
    selectedItem = context.watch<DrawerState>().selectedItem;

    return WillPopScope(
      onWillPop: () {
        SystemNavigator.pop();
        return;
      },
      child: Scaffold(
        key: context.read<DrawerState>().scaffoldKey,
        drawer: !AppResponsive.isDesktop(context) ? SideBar() : null,
        backgroundColor: AppColor.sidebar,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ! Side Navigation Menu
              if (AppResponsive.isDesktop(context))
                Expanded(
                  flex: 3,
                  child: SideBar(),
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

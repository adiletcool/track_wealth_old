import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/pages/side_bar/side_bar.dart';

class PageWrapper extends StatelessWidget {
  final String routeName;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget body;

  PageWrapper({required this.routeName, required this.scaffoldKey, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (routeName == 'Портфель')
          SystemNavigator.pop();
        else
          Navigator.pushNamed(context, '/dashboard');
        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        drawer: !AppResponsive.isDesktop(context) ? SideBar(selectedRouteName: routeName) : null,
        appBar: appBar,
        body: SafeArea(
          child: Row(
            children: [
              if (AppResponsive.isDesktop(context))
                SizedBox(
                  width: 300,
                  child: SideBar(
                    selectedRouteName: routeName,
                  ),
                ),
              Expanded(flex: 11, child: body),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:track_wealth/common/app_responsive.dart';

import 'side_bar/side_bar.dart';

class PageWrapper extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget body;

  PageWrapper({this.scaffoldKey, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: !AppResponsive.isDesktop(context) ? SideBar() : null,
      body: SafeArea(
        child: Row(
          children: [
            if (AppResponsive.isDesktop(context))
              SizedBox(
                width: 300,
                child: SideBar(),
              ),
            Expanded(flex: 11, child: body),
          ],
        ),
      ),
    );
  }
}

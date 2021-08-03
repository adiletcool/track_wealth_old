import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/page_wrapper/page_wrapper.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Default name';
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  User? firebaseUser;
  String routeName = 'Профиль';

  void setUserName() {
    if (firebaseUser != null) {
      if (!["", null].contains(firebaseUser!.displayName))
        userName = firebaseUser!.displayName!;
      else if (!["", null].contains(firebaseUser!.email))
        userName = firebaseUser!.email!.split('@').first;
      else if (!["", null].contains(firebaseUser!.phoneNumber)) userName = firebaseUser!.phoneNumber!;
    }
    setState(() {});
  }

  void _openDrawer() => drawerKey.currentState!.openDrawer();

  @override
  Widget build(BuildContext context) {
    firebaseUser = context.watch<User?>();
    setUserName();

    return PageWrapper(
      routeName: routeName,
      drawerKey: drawerKey,
      appBar: AppResponsive.isDesktop(context) ? null : appBar(),
      body: Center(
        child: Text(userName),
      ),
    );
  }

  PreferredSizeWidget appBar() {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, color: bgColor),
        onPressed: _openDrawer,
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/page_wrapper/page_wrapper.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userName;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String routeName = 'Профиль';
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    setUserName(auth.currentUser!);
  }

  void setUserName(User firebaseUser) {
    if (!["", null].contains(firebaseUser.displayName))
      userName = firebaseUser.displayName!;
    else if (!["", null].contains(firebaseUser.email))
      userName = firebaseUser.email!.split('@').first;
    else if (!["", null].contains(firebaseUser.phoneNumber))
      userName = firebaseUser.phoneNumber!;
    else
      userName = 'Default name';
  }

  void _openDrawer() => scaffoldKey.currentState!.openDrawer();

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      routeName: routeName,
      scaffoldKey: scaffoldKey,
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

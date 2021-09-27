import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/static/app_color.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userName;
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

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      color: bgColor,
      child: Center(
        child: Text(userName),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/drawer_state.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  User firebaseUser;

  @override
  Widget build(BuildContext context) {
    firebaseUser = context.read<User>();
    if ((firebaseUser != null) && (userName == '')) {
      if (firebaseUser.displayName != null)
        userName = firebaseUser.displayName;
      else if (firebaseUser.email != null)
        userName = firebaseUser.email.split('@').first;
      else if (firebaseUser.phoneNumber != null) userName = firebaseUser.phoneNumber;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: Colors.black),
          onPressed: context.read<DrawerState>().controlMenu,
        ),
      ),
      body: Center(
        child: Text(userName),
      ),
    );
  }
}

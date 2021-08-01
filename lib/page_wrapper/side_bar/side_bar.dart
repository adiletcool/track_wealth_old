import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/auth_service.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/drawer_state.dart';

class SideBar extends StatefulWidget {
  final String userName;
  final User firebaseUser;
  final String selectedItem;

  const SideBar({@required this.selectedItem, @required this.userName, @required this.firebaseUser});

  @override
  _SideBarState createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  List<Map<String, dynamic>> drawerItems = [];

  void changePage(String newSelectedItem) {
    if (widget.selectedItem != newSelectedItem) {
      context.read<DrawerState>().changeSelectedItem(newSelectedItem);
    }
    if (!AppResponsive.isDesktop(context)) Navigator.pop(context);
  }

  List<Map<String, dynamic>> getDrawerItems() {
    return [
      {'title': "Портфель", 'icon': Icons.pie_chart_rounded, 'onTap': changePage},
      {'title': "Анализ", 'icon': Icons.assessment, 'onTap': changePage},
      {'title': "Сделки", 'icon': Icons.history, 'onTap': changePage},
      {'title': "Календарь", 'icon': Icons.event, 'onTap': changePage},
      {'title': "Тренды", 'icon': Icons.explore, 'onTap': changePage},
      {'title': "Настройки", 'icon': Icons.settings, 'onTap': changePage},
    ];
  }

  // оставить параметр item
  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Вы уверены, что хотите выйти из аккаунта?'),
          actions: [
            TextButton(
              child: Text(
                'Да',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.read<DrawerState>().changeSelectedItem('Портфель');
                context.read<AuthenticationService>().signOut(widget.firebaseUser);
              },
            ),
            TextButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    drawerItems = getDrawerItems();

    return Drawer(
      elevation: 0,
      child: Container(
        color: AppColor.grey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.all(20),
                child: Text(
                  "TRACKWEALTH",
                  style: TextStyle(
                    color: AppColor.selectedDrawerItem,
                    fontSize: 25,
                    fontFamily: 'RussoOne',
                  ),
                ),
              ),
              DrawerListTile(
                title: widget.userName,
                icon: Icons.person_rounded,
                onTapFunc: () => changePage('Профиль'),
                isSelected: widget.selectedItem == 'Профиль',
              ),
              ...drawerItems
                  .map((e) => DrawerListTile(
                        title: e['title'],
                        icon: e['icon'],
                        onTapFunc: () => e['onTap'](e['title']),
                        isSelected: widget.selectedItem == e['title'],
                      ))
                  .toList(),
              Divider(),
              DrawerListTile(
                title: 'Выйти',
                icon: Icons.logout_rounded,
                onTapFunc: logout,
                isSelected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String /*!*/ title;
  final IconData /*!*/ icon;
  final void Function() onTapFunc;
  final bool isSelected;

  const DrawerListTile({@required this.title, @required this.icon, @required this.onTapFunc, @required this.isSelected});

  @override
  Widget build(BuildContext context) {
    Color itemColor = isSelected ? AppColor.selectedDrawerItem : AppColor.black;
    return ListTile(
      onTap: onTapFunc,
      horizontalTitleGap: 0.0,
      leading: Icon(icon, size: 20, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 18,
        ),
      ),
    );
  }
}

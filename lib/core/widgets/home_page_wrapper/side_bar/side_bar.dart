import 'package:flutter/material.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/features/auth/service/auth_helpers.dart';

class SideBar extends StatefulWidget {
  @override
  _SideBarState createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  void changePage(String route) {
    Navigator.pop(context); // pop sidebar
    Navigator.pushNamed(context, route);
  }

  List<Map<String, dynamic>> drawerItems = [
    {'routeName': "Календарь", 'icon': Icons.event, 'route': '/calendar'},
    {'routeName': "Тренды", 'icon': Icons.explore, 'route': '/trends'},
    {'routeName': "Настройки", 'icon': Icons.settings, 'route': '/settings'},
  ];

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.bgDark, AppColor.grey);

    return Drawer(
      elevation: 0,
      child: Container(
        color: bgColor,
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
                    color: AppColor.selected,
                    fontSize: 25,
                    fontFamily: 'RussoOne',
                  ),
                ),
              ),
              ...drawerItems
                  .map((e) => DrawerListTile(
                        title: e['routeName'],
                        icon: e['icon'],
                        onTapFunc: () => changePage(e['route']),
                      ))
                  .toList(),
              Divider(),
              DrawerListTile(
                title: 'Выйти',
                icon: Icons.logout_rounded,
                onTapFunc: () => userLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function() onTapFunc;

  const DrawerListTile({required this.title, required this.icon, required this.onTapFunc});

  @override
  Widget build(BuildContext context) {
    Color textColor = AppColor.themeBasedColor(context, Colors.white, AppColor.black);

    return ListTile(
      onTap: onTapFunc,
      horizontalTitleGap: 0.0,
      leading: Icon(icon, size: 20, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
        ),
      ),
    );
  }
}

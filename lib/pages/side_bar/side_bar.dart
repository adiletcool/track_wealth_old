import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/auth.dart';
import 'package:track_wealth/common/constants.dart';

class SideBar extends StatefulWidget {
  final String selectedRouteName;
  const SideBar({required this.selectedRouteName});

  @override
  _SideBarState createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  List<Map<String, dynamic>> drawerItems = [];

  void changePage(String? route) {
    if (route != null) {
      if (ModalRoute.of(context)!.settings.name == route) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamed(context, route);
      }
    }
  }

  List<Map<String, dynamic>> getDrawerItems() {
    return [
      {'title': 'Профиль', 'icon': Icons.person_rounded, 'route': '/profile'},
      {'title': "Портфель", 'icon': Icons.pie_chart_rounded, 'route': '/dashboard'},
      {'title': "Анализ", 'icon': Icons.assessment},
      {'title': "Сделки", 'icon': Icons.history},
      {'title': "Календарь", 'icon': Icons.event},
      {'title': "Тренды", 'icon': Icons.explore},
      {'title': "Настройки", 'icon': Icons.settings},
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
              onPressed: () async {
                // Navigator.pop(context);
                await context.read<AuthService>().signOut();
                Navigator.pushNamed(context, '/');
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
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;

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
                        title: e['title'],
                        icon: e['icon'],
                        onTapFunc: () => changePage(e['route']),
                        isSelected: widget.selectedRouteName == e['title'],
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
  final String title;
  final IconData icon;
  final void Function() onTapFunc;
  final bool isSelected;

  const DrawerListTile({required this.title, required this.icon, required this.onTapFunc, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColor.black;

    Color itemColor = isSelected ? AppColor.selected : textColor;
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

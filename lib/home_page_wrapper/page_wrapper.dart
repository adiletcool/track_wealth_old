import 'package:flutter/material.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/pages/analysis/analysis.dart';
import 'package:track_wealth/pages/dashboard/dashboard.dart';
import 'package:track_wealth/pages/profile/profile.dart';
import 'package:track_wealth/pages/trades/trades.dart';

import 'side_bar/side_bar.dart';

class PageWrapper extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Portfolio> portfolios;
  final Portfolio selectedPortfolio;

  PageWrapper({required this.scaffoldKey, required this.portfolios, required this.selectedPortfolio});

  @override
  State<PageWrapper> createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Color tabColor;

  List<Tab> getTabIcons() => [
        Icons.grid_view_rounded,
        Icons.view_list_rounded,
        Icons.donut_large_rounded,
        Icons.account_circle_rounded,
      ]
          .map((e) => Tab(
                icon: Icon(e, color: tabColor),
              ))
          .toList();

  List<Widget> getTabPages() => [
        DashboardScreen(
          selectedPortfolio: widget.selectedPortfolio,
          scaffoldKey: widget.scaffoldKey,
        ),
        TradesPage(),
        AnalysisPage(),
        ProfilePage(portfolios: widget.portfolios, tabController: _tabController),
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tabColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: SideBar(),
      bottomNavigationBar: Material(
        color: AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey),
        child: TabBar(
          indicatorColor: AppColor.selected,
          tabs: getTabIcons(),
          controller: _tabController,
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: getTabPages(),
        ),
      ),
    );
  }
}

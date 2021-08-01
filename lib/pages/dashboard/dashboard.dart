import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';

import 'header/header.dart';
import 'portfolio/portfolio.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
      // padding: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
      color: AppColor.sidebar,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          //! Header
          SliverToBoxAdapter(child: Header()),

          //! Portfolio
          SliverToBoxAdapter(child: Portfolio()),

          /* Если нужно, чтобы скролилась таблица
           SliverFillRemaining(
            child: Portfolio(),
          ),
          Этот вариант хуже, поскольку нет возможности настроить физику скролла так,
          чтобы при скролле таблицы, сначала скролился CustomScrollView до конца
          */
        ],
      ),
    );
  }
}

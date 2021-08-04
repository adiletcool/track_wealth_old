import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/dashboard_state.dart';
import 'package:track_wealth/page_wrapper/page_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'header/header.dart';
import 'portfolio/portfolio.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String routeName = 'Портфель';

  final ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();

  num getPortfolioTotal(List<PortfolioAsset> data) => data.map((asset) => asset.worth).sum;

  // стоимость покупок. Нужно, чтобы посчитать суммарную прибыль/убыток по открытым позициям
  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.profit).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) {
    return data.map((asset) => asset.worth - asset.worth / (1 + asset.todayPriceChange / 100)).sum;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;

    return PageWrapper(
      routeName: routeName,
      drawerKey: drawerKey,
      body: FutureBuilder(
        future: Future.wait([
          context.read<DashboardState>().getPortfolioAssets(),
          context.read<DashboardState>().getCurrencies(),
        ]),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData) {
            return Container(
              margin: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
              // padding: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
              color: bgColor,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  //! Header
                  SliverToBoxAdapter(
                    child: Header(
                      drawerKey: drawerKey,
                      portfolioTotal: getPortfolioTotal(snapshot.data![0]),
                      portfolioTodayChange: getPortfolioTodayChange(snapshot.data![0]),
                      portfolioAllTimeChange: getPortfolioAllTimeChange(snapshot.data![0]),
                    ),
                  ),

                  //! Portfolio
                  SliverToBoxAdapter(
                    child: Portfolio(
                      portfolioAssets: snapshot.data![0],
                      currencies: snapshot.data![1],
                    ),
                  ),

                  /* Если нужно, чтобы скролилась таблица
                  SliverFillRemaining(child: Portfolio(...)),
                  Этот вариант хуже, поскольку нет возможности настроить физику скролла так,
                  чтобы при скролле таблицы, сначала скролился CustomScrollView до конца
                  */
                ],
              ),
            );
          } else {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
        },
      ),
    );
  }
}

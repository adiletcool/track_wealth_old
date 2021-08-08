import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:track_wealth/page_wrapper/page_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/pages/dashboard/header/subheader.dart';
import 'package:track_wealth/pages/shimmers/dashboard_shimmer.dart';

import 'header/header.dart';
import 'portfolio/portfolio.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String routeName = 'Портфель';

  final ScrollController scrollController = ScrollController();

  late List<PortfolioAsset> portfolioAssets;
  late Map<String, Map<String, dynamic>> currencies;

  @override
  void initState() {
    super.initState();
    context.read<DashboardState>().loadDataState = context.read<DashboardState>().loadData();
  }

  num getCurrenciesTotal(Map<String, Map<String, dynamic>> data) {
    return data.entries.map((entry) => entry.value['totalRub'] as num).sum;
  }

  num getPortfolioTotal(List<PortfolioAsset> data) => data.map((asset) => asset.worth).sum;

  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.profit).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) {
    return data.map((asset) => asset.worth - asset.worth / (1 + asset.todayPriceChange / 100)).sum;
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      routeName: routeName,
      scaffoldKey: scaffoldKey,
      body: dashboard(),
    );
  }

  Widget dashboard() {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;
    Future<String>? _loadData = context.watch<DashboardState>().loadDataState;

    return FutureBuilder(
      future: _loadData,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else {
            portfolioAssets = context.read<DashboardState>().portfolioAssets!;
            currencies = context.read<DashboardState>().currencies!;
            return Container(
              margin: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
              color: bgColor,
              child: RefreshIndicator(
                color: Theme.of(context).iconTheme.color,
                edgeOffset: 45,
                displacement: 30,
                onRefresh: () => context.read<DashboardState>().reloadData(),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      toolbarHeight: 45,
                      expandedHeight: 45,
                      collapsedHeight: 45,
                      backgroundColor: bgColor,
                      pinned: true,
                      leading: Container(),
                      flexibleSpace: Header(
                        drawerKey: scaffoldKey,
                        portfolioTotal: getPortfolioTotal(portfolioAssets) + getCurrenciesTotal(currencies), // активы + кэш
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SubHeader(
                        portfolioTotal: getPortfolioTotal(portfolioAssets), // изменения считаются относительно стоимости активов без учета свободных денег
                        portfolioTodayChange: getPortfolioTodayChange(portfolioAssets),
                        portfolioAllTimeChange: getPortfolioAllTimeChange(portfolioAssets),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Portfolio(
                        portfolioAssets: portfolioAssets,
                        currencies: currencies,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          return DashboardShimmer();
        }
      },
    );
  }
}

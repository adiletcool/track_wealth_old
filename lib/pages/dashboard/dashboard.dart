import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:track_wealth/page_wrapper/page_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/pages/dashboard/header/subheader.dart';
import 'package:track_wealth/pages/shimmers/dashboard_shimmer.dart';

import 'header/header.dart';
import 'portfolio/add_new_portfolio.dart';
import 'portfolio/portfolio.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String routeName = 'Портфель';

  late List<Portfolio> allPortfolios;
  late List<PortfolioAsset> portfolioAssets;
  late Map<String, Map<String, dynamic>> currencies;

  @override
  void initState() {
    super.initState();
    context.read<DashboardState>().loadDataState = context.read<DashboardState>().loadData();
  }

  void setOrientationMode({bool canLandscape = true}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      if (canLandscape) DeviceOrientation.landscapeRight,
      if (canLandscape) DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
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
            allPortfolios = context.read<DashboardState>().portfolios!;
            portfolioAssets = context.read<DashboardState>().selectedPortfolioAssets!;
            currencies = context.read<DashboardState>().currencies!;
            setOrientationMode(canLandscape: allPortfolios.length != 0);

            return allPortfolios.length == 0
                ? AddNewPortfolio(title: 'Добавьте свой первый портфель', isSeparatePage: false)
                : PageWrapper(
                    routeName: routeName,
                    scaffoldKey: scaffoldKey,
                    body: MainTable(
                      portfolioAssets: portfolioAssets,
                      currencies: currencies,
                      scaffoldKey: scaffoldKey,
                    ),
                  );
          }
        } else {
          return SafeArea(child: DashboardShimmer());
        }
      },
    );
  }
}

class MainTable extends StatelessWidget {
  final List<PortfolioAsset> portfolioAssets;
  final Map<String, Map<String, dynamic>> currencies;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController = ScrollController();

  MainTable({required this.portfolioAssets, required this.currencies, required this.scaffoldKey});

  num getCurrenciesTotal(Map<String, Map<String, dynamic>> data) => data.entries.map((entry) => entry.value['totalRub'] as num).sum;

  num getPortfolioTotal(List<PortfolioAsset> data) => data.map((asset) => asset.worth!).sum;

  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.profit!).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) => data.map((asset) => asset.worth! - asset.worth! / (1 + asset.todayPriceChange! / 100)).sum;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;

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
              child: PortfolioTable(
                portfolioAssets: portfolioAssets,
                currencies: currencies,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

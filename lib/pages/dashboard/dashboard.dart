import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
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
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  bool firstLoaded = false;

  void setOrientationMode({bool canLandscape = true}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      if (canLandscape) DeviceOrientation.landscapeRight,
      if (canLandscape) DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBuilder(
      builder: (context, isConnected, status) {
        if ((status != ConnectivityStatus.none) && (status != null)) {
          if (!firstLoaded) {
            print('FIRST DATA LOAD');
            context.read<DashboardState>().loadDataState = context.read<DashboardState>().loadData();
            firstLoaded = true;
          }
          return mainBody();
        } else
          return DashboardShimmer();
      },
    );
  }

  Widget mainBody() {
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
            portfolios = context.read<DashboardState>().portfolios;
            setOrientationMode(canLandscape: portfolios.length != 0);

            if (portfolios.length == 0) {
              return AddNewPortfolio(title: 'Добавьте свой первый портфель', isSeparatePage: false);
            } else {
              selectedPortfolio = context.read<DashboardState>().selectedPortfolio;
              return PageWrapper(
                routeName: routeName,
                scaffoldKey: scaffoldKey,
                body: DashboardScreen(
                  portfolioAssets: selectedPortfolio.assets!,
                  currencies: selectedPortfolio.curercies!,
                  scaffoldKey: scaffoldKey,
                ),
              );
            }
          }
        } else {
          return PageWrapper(
            routeName: routeName,
            body: DashboardShimmer(),
          );
        }
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final List<PortfolioAsset> portfolioAssets;
  final List<PortfolioCurrency> currencies;
  final GlobalKey<ScaffoldState> scaffoldKey;

  DashboardScreen({required this.portfolioAssets, required this.currencies, required this.scaffoldKey});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController scrollController = ScrollController();
  late Map<String, bool> colFilter;

  num getCurrenciesTotal(List<PortfolioCurrency> data) => data.map((currency) => currency.totalRub!).sum;

  num getPortfolioTotal(List<PortfolioAsset> data) => data.map((asset) => asset.worth!).sum;

  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.profit!).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) => data.map((asset) => asset.worth! - asset.worth! / (1 + asset.todayPriceChange! / 100)).sum;

  void updateColumnFilter() => setState(() {});

  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;

    // Логичнее было бы использовать context.watch в PortfolioTable вместо colFilter и updateColumnFilter здесь, однако
    colFilter = AppResponsive.isMobile(context) ? context.read<TableState>().mobileColumnFilter : context.read<TableState>().columnFilter;

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
                drawerKey: widget.scaffoldKey,
                portfolioTotal: getPortfolioTotal(widget.portfolioAssets) + getCurrenciesTotal(widget.currencies), // активы + кэш
              ),
            ),
            SliverToBoxAdapter(
              child: SubHeader(
                portfolioTotal: getPortfolioTotal(widget.portfolioAssets), // изменения считаются относительно стоимости активов без учета свободных денег
                portfolioTodayChange: getPortfolioTodayChange(widget.portfolioAssets),
                portfolioAllTimeChange: getPortfolioAllTimeChange(widget.portfolioAssets),
                updateColumnFilter: updateColumnFilter,
              ),
            ),
            SliverToBoxAdapter(
              child: PortfolioTable(
                portfolioAssets: widget.portfolioAssets,
                currencies: widget.currencies,
                colFilter: colFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:connectivity/connectivity.dart';
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
  ConnectivityResult connection = ConnectivityResult.none;
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;

  @override
  void initState() {
    super.initState();
    try {
      context.read<DashboardState>().loadDataState = context.read<DashboardState>().loadData();
    } catch (e) {
      print('Unable to load data');
      print('Reason: ${e.toString()}');
    }
  }

  void setOrientationMode({bool canLandscape = true}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      if (canLandscape) DeviceOrientation.landscapeRight,
      if (canLandscape) DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    connection = context.watch<ConnectivityResult>();
  }

  @override
  Widget build(BuildContext context) {
    if (connection == ConnectivityResult.none) {
      return SafeArea(child: DashboardShimmer());
    } else {
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
                  body: MainTable(
                    portfolioAssets: selectedPortfolio.assets!,
                    currencies: selectedPortfolio.curercies!,
                    scaffoldKey: scaffoldKey,
                  ),
                );
              }
            }
          } else {
            return SafeArea(child: DashboardShimmer());
          }
        },
      );
    }
  }
}

class MainTable extends StatelessWidget {
  final List<PortfolioAsset> portfolioAssets;
  final List<PortfolioCurrency> currencies;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController = ScrollController();

  MainTable({required this.portfolioAssets, required this.currencies, required this.scaffoldKey});

  num getCurrenciesTotal(List<PortfolioCurrency> data) => data.map((currency) => currency.totalRub!).sum;

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

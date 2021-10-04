import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/home_page_wrapper/page_wrapper.dart';
import 'package:track_wealth/pages/dashboard/header/subheader.dart';
import 'package:track_wealth/pages/shimmers/shimmers.dart';

import 'header/header.dart';
import 'portfolio/add_portfolio.dart';
import 'portfolio/portfolio.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  Future<String>? _loadData;
  late PortfolioState dashboardState;

  void setOrientationMode({bool canLandscape = true}) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      if (canLandscape) DeviceOrientation.landscapeRight,
      if (canLandscape) DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    print("Build DashboardPage");

    return ConnectivityBuilder(
      builder: (context, isConnected, status) {
        if ((status != ConnectivityStatus.none) && (status != null)) {
          return mainBody();
        } else
          return DashboardShimmer();
      },
    );
  }

  Widget mainBody() {
    dashboardState = context.watch<PortfolioState>();
    // при reload ребилдится виджет, поэтому loadDataState снова загружать не нужно
    dashboardState.loadDataState ??= dashboardState.loadData();
    _loadData = dashboardState.loadDataState;

    return FutureBuilder(
      future: _loadData,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else {
            portfolios = dashboardState.portfolios;
            setOrientationMode(canLandscape: portfolios.length != 0);

            if (portfolios.length == 0) {
              Future.microtask(() => Navigator.pushNamed(
                    context,
                    '/dashboard/add_portfolio',
                    arguments: AddPortfolioArgs(title: 'Добавьте свой первый портфель', isInitial: false),
                  )); // Перенаправляем после выполнения build
              return Container();
            } else {
              selectedPortfolio = dashboardState.selectedPortfolio;

              return PageWrapper(
                scaffoldKey: scaffoldKey,
                selectedPortfolio: selectedPortfolio,
              );
            }
          }
        } else {
          return SafeArea(
            child: DashboardShimmer(),
          );
        }
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final ScrollController scrollController = ScrollController();
  final Portfolio selectedPortfolio;
  final GlobalKey<ScaffoldState> scaffoldKey;

  DashboardScreen({required this.selectedPortfolio, required this.scaffoldKey});

  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.unrealizedPnl!).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) => data.map((asset) => asset.worth! - asset.worth! / (1 + asset.todayPriceChange! / 100)).sum;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      margin: EdgeInsets.only(top: 0),
      color: bgColor,
      child: RefreshIndicator(
        color: Theme.of(context).iconTheme.color,
        edgeOffset: 45,
        displacement: 30,
        onRefresh: context.read<PortfolioState>().reloadData,
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
              flexibleSpace: Header(drawerKey: scaffoldKey),
            ),
            if (selectedPortfolio.assets!.length > 0)
              SliverToBoxAdapter(
                child: SubHeader(
                  portfolioAssetsTotal: selectedPortfolio.assetsTotal!, // изменения считаются относительно стоимости активов без учета свободных денег
                  portfolioTodayChange: getPortfolioTodayChange(selectedPortfolio.assets!),
                  portfolioAllTimeChange: getPortfolioAllTimeChange(selectedPortfolio.assets!),
                ),
              ),
            SliverToBoxAdapter(
              child: PortfolioTable(
                portfolioAssets: selectedPortfolio.assets!,
                currencies: selectedPortfolio.currencies!, //.where((c) => c.value != 0).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/core/portfolio/portfolio.dart';
import 'package:track_wealth/core/portfolio/portfolio_stock.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/orientation.dart';
import 'package:track_wealth/core/widgets/home_page_wrapper/page_wrapper.dart';
import 'package:track_wealth/core/widgets/shimmers.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'add_portfolio/add_portfolio.dart';
import 'portfolio/service/portfolio.dart';
import 'portfolio/ui/header/header.dart';
import 'portfolio/ui/header/subheader.dart';
import 'portfolio/ui/portfolio.dart';

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

    // ! initital load
    try {
      dashboardState.loadDataState ??= dashboardState.loadData(
        loadSelected: true,
        loadAssetsAndCurrencies: true,
        loadStocksMarketData: true,
        loadCurrenciesMarketData: true,
        loadTrades: true,
      );

      _loadData = dashboardState.loadDataState;
    } on DioError catch (e) {
      print('INTERNET CONNECTION ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Проверьте соединение с интернетом')));
    }

    // TODO handle timeout error
    return FutureBuilder(
      future: _loadData,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return SnackBar(content: Text(snapshot.error.toString()));
          } else {
            // Push to add new portfolio page
            portfolios = dashboardState.portfolios;
            setOrientationMode(canLandscape: portfolios.length != 0);

            if (portfolios.length == 0) {
              Future.microtask(() => Navigator.pushNamed(
                    context,
                    '/dashboard/add_portfolio',
                    arguments: AddPortfolioArgs(title: 'Добавьте свой первый портфель', isFirstPortfolio: true),
                  ).then((v) => setOrientationMode(canLandscape: true))); // Перенаправляем после выполнения build
              return Container();
            } else {
              selectedPortfolio = dashboardState.selectedPortfolio;

              return PageWrapper(
                scaffoldKey: scaffoldKey,
                portfolios: portfolios,
                selectedPortfolio: selectedPortfolio,
              );
            }
          }
        } else {
          // Loading state
          return SafeArea(
            child: DashboardShimmer(),
          );
        }
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Portfolio selectedPortfolio;
  final GlobalKey<ScaffoldState> scaffoldKey;

  DashboardScreen({required this.selectedPortfolio, required this.scaffoldKey});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin<DashboardScreen> {
  final ScrollController scrollController = ScrollController();
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  num getPortfolioAllTimeChange(List<PortfolioStock> data) => data.map((stock) => stock.unrealizedPnl!).sum;

  num getPortfolioTodayChange(List<PortfolioStock> data) => data.map((stock) => stock.worth! - stock.worth! / (1 + stock.todayPriceChange! / 100)).sum;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      color: bgColor,
      child: SmartRefresher(
        controller: _refreshController,
        header: WaterDropMaterialHeader(backgroundColor: AppColor.indigo),
        // onRefresh: () => context.read<PortfolioState>().reloadData(
        //       loadSelected: false,
        //       loadAssetsAndCurrencies: false,
        //       loadStocksMarketData: true,
        //       loadCurrenciesMarketData: true,
        //       loadTrades: false,
        //     ),
        onRefresh: () async {
          try {
            await context.read<PortfolioState>().loadData(
                  loadSelected: false,
                  loadAssetsAndCurrencies: false,
                  loadStocksMarketData: true,
                  loadCurrenciesMarketData: true,
                  loadTrades: false,
                );
          } on DioError catch (e) {
            print('INTERNET CONNECTION ERROR: $e');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Проверьте соединение с интернетом')));
          }

          setState(() {}); // TODO: check if works without reloading with shimmer
          _refreshController.refreshCompleted();
        },
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
              flexibleSpace: Header(drawerKey: widget.scaffoldKey),
            ),
            if (widget.selectedPortfolio.stocks!.length > 0)
              SliverToBoxAdapter(
                child: SubHeader(
                  portfolioStocksTotal: widget.selectedPortfolio.stocksTotal!, // изменения считаются относительно стоимости активов без учета свободных денег
                  portfolioTodayChange: getPortfolioTodayChange(widget.selectedPortfolio.stocks!),
                  portfolioAllTimeChange: getPortfolioAllTimeChange(widget.selectedPortfolio.stocks!),
                ),
              ),
            SliverToBoxAdapter(
              child: PortfolioTable(
                portfolioStocks: widget.selectedPortfolio.stocks!,
                currencies: widget.selectedPortfolio.currencies!, //.where((c) => c.value != 0).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'package:track_wealth/pages/dashboard/header/subheader.dart';

import 'header/header.dart';
import 'portfolio/portfolio.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String routeName = 'Портфель';
  late Future<List<List<Object>>> _loadData;

  final ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();

  List<PortfolioAsset> portfolioAssets = [];
  List<Map<String, dynamic>> currensies = [];

  @override
  void initState() {
    super.initState();
    _loadData = loadData();
  }

  num getCurrenciesTotal(List<Map<String, dynamic>> currenciesData) => currenciesData.map((currency) => currency['totalRub'] as num).sum;

  num getPortfolioTotal(List<PortfolioAsset> data) => data.map((asset) => asset.worth).sum;

  num getPortfolioAllTimeChange(List<PortfolioAsset> data) => data.map((asset) => asset.profit).sum;

  num getPortfolioTodayChange(List<PortfolioAsset> data) {
    return data.map((asset) => asset.worth - asset.worth / (1 + asset.todayPriceChange / 100)).sum;
  }

  Future<List<List<Object>>> loadData({forced: false}) async {
    List<List<Object>> data = await Future.wait([
      context.read<DashboardState>().getPortfolioAssets(forced: forced),
      context.read<DashboardState>().getCurrencies(forced: forced),
    ]);

    return data;
  }

  Future<void> reloadData() async {
    setState(() {
      _loadData = loadData(forced: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;

    return PageWrapper(
      routeName: routeName,
      drawerKey: drawerKey,
      body: FutureBuilder(
        future: _loadData,
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            } else {
              return Container(
                margin: EdgeInsets.only(top: AppResponsive.isMobile(context) ? 0 : 10),
                color: bgColor,
                child: RefreshIndicator(
                  onRefresh: reloadData,
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverAppBar(
                        toolbarHeight: 45,
                        expandedHeight: 45,
                        collapsedHeight: 45,
                        backgroundColor: bgColor,
                        pinned: true,
                        leading: Container(),
                        flexibleSpace: Header(
                          drawerKey: drawerKey,
                          portfolioTotal: getPortfolioTotal(snapshot.data![0]) + getCurrenciesTotal(snapshot.data![1]), // активы + кэш
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SubHeader(
                          portfolioTotal: getPortfolioTotal(snapshot.data![0]), // изменения считаются относительно стоимости активов без учета свободных денег
                          portfolioTodayChange: getPortfolioTodayChange(snapshot.data![0]),
                          portfolioAllTimeChange: getPortfolioAllTimeChange(snapshot.data![0]),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Portfolio(
                          portfolioAssets: snapshot.data![0],
                          currencies: snapshot.data![1],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            return Container(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}

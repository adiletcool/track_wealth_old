import 'package:flutter/material.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:track_wealth/common/models/portfolio_trade.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:grouped_list/grouped_list.dart';

class TradesPage extends StatefulWidget {
  final List<Trade>? trades;

  const TradesPage(this.trades);
  @override
  _TradesPageState createState() => _TradesPageState(trades);
}

class _TradesPageState extends State<TradesPage> with AutomaticKeepAliveClientMixin<TradesPage> {
  final List<Trade>? trades;
  late Color textColor;
  late Color bgColor;
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  _TradesPageState(this.trades);

  void _onLoading() async {
    bool isLoadedMore = await context.read<PortfolioState>().loadMoreTrades();

    if (isLoadedMore) {
      setState(() {});
      _refreshController.loadComplete();
    } else
      _refreshController.loadNoData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);
    textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

    return Container(
      color: bgColor,
      child: SmartRefresher(
        controller: _refreshController,
        enablePullDown: false,
        enablePullUp: true,
        onLoading: _onLoading,
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          noDataText: "Больше сделок нет",
          idleText: "Потяните, чтобы загрузить больше сделок",
          canLoadingText: "Загрузить больше сделок",
          loadingText: "Загрузка...",
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 45,
              expandedHeight: 45,
              collapsedHeight: 45,
              backgroundColor: bgColor,
              pinned: true,
              leading: Container(),
              flexibleSpace: Text('FILtER'),
            ),
            SliverGroupedListView<Trade, String>(
              elements: trades ?? [],
              itemComparator: (t1, t2) => t1.date.compareTo(t2.date),
              groupBy: (t) => DateFormat.yMMMd('ru').format(DateTime.parse(t.date)),
              order: GroupedListOrder.DESC,
              itemBuilder: (context, trade) => trade.build(context),
              groupSeparatorBuilder: (String groupByValue) => getDateHeader(groupByValue),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(date, style: TextStyle(color: textColor, fontSize: 15)),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

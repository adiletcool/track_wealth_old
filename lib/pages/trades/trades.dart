import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:track_wealth/common/models/portfolio_trade.dart';
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

  final ScrollController scrollController = ScrollController();
  _TradesPageState(this.trades);
  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);
    textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

    return Container(
      color: bgColor,
      child: CustomScrollView(
        controller: scrollController,
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
          SliverFillRemaining(
            hasScrollBody: true,
            child: SmartRefresher(
              scrollController: scrollController,
              enablePullDown: false,
              enablePullUp: true,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              footer: ClassicFooter(
                loadStyle: LoadStyle.ShowWhenLoading,
                idleText: "Потяните, чтобы загрузить больше сделок",
                canLoadingText: "Загрузить больше сделок",
                loadingText: "Загрузка...",
              ),
              child: GroupedListView<Trade, String>(
                shrinkWrap: true,
                elements: trades ?? [],
                groupBy: (t) => DateFormat.yMMMd('ru').format(DateTime.parse(t.date)),
                useStickyGroupSeparators: true,
                order: GroupedListOrder.DESC,
                stickyHeaderBackgroundColor: AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.indigo),
                groupSeparatorBuilder: (String groupByValue) => getDateHeader(groupByValue),
                itemBuilder: (context, trade) => trade.build(context),
              ),
            ),
          ),
        ],
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

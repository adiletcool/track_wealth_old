import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/decorations.dart';
import 'package:track_wealth/core/util/delayed_scrolldown.dart';
import 'package:track_wealth/core/util/portfolio_helpers.dart';
import 'package:track_wealth/features/auth/service/auth_helpers.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/portfolio.dart';

//TODO: добавить попап с подтверждением сделки

class AddPortfolioArgs {
  final String title;
  final bool isFirstPortfolio;

  const AddPortfolioArgs({required this.title, required this.isFirstPortfolio});
}

class AddPortfolioPage extends StatefulWidget {
  final AddPortfolioArgs args;

  const AddPortfolioPage(this.args);

  @override
  _AddPortfolioPageState createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  String broker = 'Не выбран';
  bool marginTrading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final nameFormKey = GlobalKey<FormState>();
  ScrollController scrollController = ScrollController();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedCurrency = 'Рубли';
  Map<String, String> currencies = {
    'RUB': 'Рубли',
    'USD000UTSTOM': 'Доллары',
    'EUR_RUB__TOM': 'Евро',
  };

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: !widget.args.isFirstPortfolio // Если не новый пользователь
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
              )
            : IconButton(
                icon: Icon(Icons.logout_rounded, color: Theme.of(context).iconTheme.color),
                onPressed: () => userLogout(context),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: createPortfolio,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: ListView(
              controller: scrollController,
              children: [
                Center(child: Lottie.asset('assets/animations/add_portfolio.json', height: MediaQuery.of(context).size.height * .20, reverse: true)),
                Text(
                  widget.args.title,
                  style: TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                Divider(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Название', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
                    SizedBox(height: 6),
                    Form(
                      key: nameFormKey,
                      child: TextFormField(
                        onTap: () => delayedScrollDown(scrollController),
                        validator: (name) => validatePortfolioName(context, name),
                        controller: nameController,
                        decoration: myInputDecoration.copyWith(hintText: 'Основной портфель*', counterText: ''),
                        style: TextStyle(fontSize: 18),
                        maxLength: 40,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Описание', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
                    SizedBox(height: 6),
                    TextFormField(
                      onTap: () => delayedScrollDown(scrollController),
                      controller: descController,
                      decoration: myInputDecoration.copyWith(hintText: 'Расскажите об этом портфеле', counterText: ''),
                      style: TextStyle(fontSize: 18),
                      maxLength: 400,
                      maxLines: 5,
                      minLines: 1,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                brokerDropdown(),
                marginTradingSettings(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget brokerDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Брокер', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
      SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: roundedBoxDecoration.copyWith(border: Border.all(width: 1, color: AppColor.darkGrey)),
        child: DropdownButton<String>(
          dropdownColor: AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.grey),
          hint: const Text('Брокер', style: TextStyle(fontSize: 20)),
          underline: Container(),
          isExpanded: true,
          value: broker,
          onChanged: (newBroker) => setState(() => broker = newBroker ?? broker),
          items: availableBrokers.map((b) => DropdownMenuItem<String>(child: Text(b), value: b)).toList(),
        ),
      ),
    ]);
  }

  Widget marginTradingSettings() {
    return SwitchListTile(
      title: Text('Маржинальная торговля'),
      value: marginTrading,
      onChanged: (v) => setState(() => marginTrading = v),
      activeColor: AppColor.selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      isThreeLine: true,
      subtitle: Text('\u2022 Короткие позиции (шорт)\n' + '\u2022 Маржинальное плечо'),
    );
  }

  Future<void> createPortfolio() async {
    bool hasConnection = await Connectivity().checkConnection();
    final snackBar = SnackBar(content: Text('Нет соединения с интернетом'));
    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (nameFormKey.currentState!.validate()) {
      String name = nameController.text != '' ? nameController.text.trim() : 'Основной портфель';
      String? decription = descController.text.isEmpty ? null : descController.text;

      await context.read<PortfolioState>().addUserPortfolio(
            name: name,
            broker: broker,
            desc: decription,
            marginTrading: marginTrading,
          );
      context.read<PortfolioState>().reloadData(
            loadSelected: true,
            loadAssetsAndCurrencies: true,
            loadStocksMarketData: false, // там нет stocks
            loadCurrenciesMarketData: true, // там везде value = 0
            loadTrades: false,
          );
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
    }
  }
}

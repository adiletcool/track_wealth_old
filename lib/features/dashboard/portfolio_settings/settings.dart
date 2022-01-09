import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/core/portfolio/portfolio.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/decorations.dart';
import 'package:track_wealth/core/util/portfolio_helpers.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/portfolio.dart';

class PortfolioSettingsAgrs {
  final portfolioName;

  const PortfolioSettingsAgrs(this.portfolioName);
}

class PortfolioSettingsPage extends StatefulWidget {
  final PortfolioSettingsAgrs args;

  const PortfolioSettingsPage(this.args);

  @override
  _PortfolioSettingsPageState createState() => _PortfolioSettingsPageState();
}

class _PortfolioSettingsPageState extends State<PortfolioSettingsPage> {
  late Portfolio portfolio;
  late String openDate;
  late bool marginTrading;
  String? broker;

  final descController = TextEditingController();
  late final String portfolioName;
  late Color settingsNameColor;

  @override
  void initState() {
    super.initState();
    portfolioName = widget.args.portfolioName;
    portfolio = context.read<PortfolioState>().portfolios.firstWhere((p) => p.name == portfolioName);

    descController.text = portfolio.description ?? '';
    openDate = DateFormat('d MMM y в H:m', 'ru_RU').format(portfolio.openDate.toDate());
    broker = portfolio.broker;
    marginTrading = portfolio.marginTrading;
  }

  Widget myRoundedContainer({required Widget child, Color? color}) {
    color ??= AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey);
    return Container(
      decoration: roundedBoxDecoration.copyWith(color: color),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }

  Widget getTitle() {
    return myRoundedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Название', style: TextStyle(color: settingsNameColor)),
          SizedBox(height: 6),
          Text(portfolio.name, style: TextStyle(fontSize: 17)),
        ],
      ),
    );
  }

  Widget getEditableSettings() {
    return myRoundedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Описание', style: TextStyle(color: settingsNameColor)),
          SizedBox(height: 6),
          TextFormField(
            controller: descController,
            decoration: myInputDecoration.copyWith(
              hintText: 'Расскажите об этом портфеле',
              counterText: '',
              hintStyle: TextStyle(color: settingsNameColor),
            ),
            maxLength: 400,
            maxLines: 7,
            minLines: 1,
          ),
          SizedBox(height: 20),
          getBrokerDropdown(),
          SizedBox(height: 10),
          marginTradingSettings(),
        ],
      ),
    );
  }

  Widget getBrokerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Брокер', style: TextStyle(color: settingsNameColor)),
        SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: roundedBoxDecoration.copyWith(border: Border.all(width: 1, color: AppColor.darkGrey)),
          child: DropdownButton<String>(
            underline: Container(),
            isExpanded: true,
            value: broker,
            onChanged: (newBroker) => setState(() => broker = newBroker ?? broker),
            items: availableBrokers.map((b) => DropdownMenuItem<String>(child: Text(b), value: b)).toList(),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ],
    );
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

  Widget getCreationDate() {
    return myRoundedContainer(
      color: AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey),
      child: Text(
        'Создан: $openDate',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);
    Color textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);
    settingsNameColor = AppColor.themeBasedColor(context, AppColor.greyTitle, AppColor.indigo);

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Настройки портфеля',
            style: TextStyle(color: textColor),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: goBack,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.done_rounded, size: 26, color: textColor),
              onPressed: saveChanges,
            )
          ]),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    getTitle(),
                    SizedBox(height: 10),
                    getEditableSettings(),
                    SizedBox(height: 10),
                    getCreationDate(),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: roundedBoxDecoration.copyWith(color: AppColor.redBlood),
                      child: SizedBox(
                        height: 45,
                        child: TextButton(
                          child: Text('Удалить', style: TextStyle(fontSize: 17, color: Colors.white)),
                          onPressed: deletePortfolioDialog,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool hasSettingsChanged() {
    return ![
      descController.text == (portfolio.description ?? ''),
      broker == portfolio.broker,
      marginTrading == portfolio.marginTrading,
    ].every((hasChanged) => hasChanged);
  }

  Future<void> saveChanges() async {
    if (hasSettingsChanged()) {
      await portfolio.updateSettings(
        context,
        newDesc: descController.text,
        newBroker: broker,
        newMarginTrading: marginTrading,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Изменения сохранены')));
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
    } else {
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
    }
  }

  void goBack() {
    if (!hasSettingsChanged()) {
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                'Изменения не будут сохранены. Продолжить?',
                style: TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  child: Text('Ок', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
                ),
                TextButton(
                  child: Text('Отмена', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          });
    }
  }

  void deletePortfolioDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(
              'Вы уверены, что хотите удалить портфель? Все данные об этом портфеле будут удалены.',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Да',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  context.read<PortfolioState>().deletePortfolio(portfolio.name);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Портфель (${portfolio.name}) удален.')));
                  Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
                },
              ),
              TextButton(
                child: Text('Отмена'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/decorations.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

class PortfolioSettingsAgrs {
  final name;

  PortfolioSettingsAgrs(this.name);
}

class PortfolioSettingsPage extends StatefulWidget {
  final String name;

  const PortfolioSettingsPage({Key? key, required this.name}) : super(key: key);
  @override
  _PortfolioSettingsPageState createState() => _PortfolioSettingsPageState();
}

class _PortfolioSettingsPageState extends State<PortfolioSettingsPage> {
  late Portfolio portfolio;
  late String openDate;
  final descController = TextEditingController();
  String? broker;

  // bool initialized = false;
  late Color settingsNameColor;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    portfolio = context.read<PortfolioState>().portfolios.firstWhere((p) => p.name == widget.name);

    descController.text = portfolio.description ?? '';
    openDate = DateFormat('d MMM y H:m', 'ru_RU').format(portfolio.openDate.toDate());
    broker = portfolio.broker;
  }

  Widget myRoundedContainer({required Widget child, Color? color}) {
    color ??= AppColor.themeBasedColor(context, Color(0xff21212B), Color(0xffF9F9FB));
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

  Widget getCreationDate() {
    return myRoundedContainer(
      color: AppColor.themeBasedColor(context, Color(0xff272732), Color(0xffF7F7FC)),
      child: Text(
        'Cоздан: $openDate',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, Color(0xff181820), AppColor.white);
    Color textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);
    settingsNameColor = AppColor.themeBasedColor(context, Color(0xffA3A3A3), Color(0xff64668A));

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
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: AppResponsive.isDesktop(context) ? 600 : null,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                getTitle(),
                SizedBox(height: 20),
                getEditableSettings(),
                SizedBox(height: 10),
                getCreationDate(),
                SizedBox(height: 10),
                Spacer(),
                Container(
                  decoration: roundedBoxDecoration.copyWith(color: Color(0xffE00019)),
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
        ),
      ),
    );
  }

  bool hasSettingsChanged() {
    return ![
      descController.text == (portfolio.description ?? ''),
      broker == portfolio.broker,
    ].every((hasChanged) => hasChanged);
  }

  Future<void> saveChanges() async {
    if (hasSettingsChanged()) {
      await context.read<PortfolioState>().changePortfolioSettings(
            portfolio.name,
            newDesc: descController.text,
            newBroker: broker,
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

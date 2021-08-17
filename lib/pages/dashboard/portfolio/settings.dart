import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:provider/provider.dart';

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
  final nameController = TextEditingController();
  final descController = TextEditingController();
  String? broker;
  final nameFormKey = GlobalKey<FormState>();

  // bool initialized = false;

  @override
  void initState() {
    super.initState();
    portfolio = context.read<DashboardState>().portfolios.firstWhere((p) => p.name == widget.name);

    nameController.text = portfolio.name;
    descController.text = portfolio.description ?? '';
    openDate = DateFormat('d MMM y H:m', 'ru_RU').format(portfolio.openDate.toDate());
    broker = portfolio.broker;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, Colors.black, AppColor.white);
    Color textColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

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
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Название', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
                  SizedBox(height: 6),
                  Form(
                    key: nameFormKey,
                    child: TextFormField(
                      validator: (name) => validatePortfolioName(context, name, exceptName: portfolio.name),
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
                    controller: descController,
                    decoration: myInputDecoration.copyWith(hintText: 'Расскажите об этом портфеле', counterText: ''),
                    style: TextStyle(fontSize: 18),
                    maxLength: 400,
                    maxLines: 7,
                    minLines: 1,
                  ),
                ],
              ),
              SizedBox(height: 20),
              brokerDropdown(),
              SizedBox(height: 20),
              Text(
                'Cоздан: $openDate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Divider(color: Colors.grey),
              SizedBox(height: 20),
              Container(
                decoration: roundedBoxDecoration.copyWith(color: Colors.red),
                child: TextButton(
                  child: Text('Удалить', style: TextStyle(fontSize: 18, color: bgColor)),
                  onPressed: deletePortfolioDialog,
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
      nameController.text == portfolio.name,
      descController.text == (portfolio.description ?? ''),
      broker == portfolio.broker,
    ].every((hasChanged) => hasChanged);
  }

  Future<void> saveChanges() async {
    if (hasSettingsChanged()) {
      if (nameFormKey.currentState!.validate()) {
        await context.read<DashboardState>().changePortfolioSettings(
              portfolio.name,
              newName: nameController.text == portfolio.name ? null : nameController.text,
              newDesc: descController.text,
              newBroker: broker,
            );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Изменения сохранены')));
        Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
      }
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
                  context.read<DashboardState>().deletePortfolio(portfolio.name);
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

  Widget brokerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Брокер', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
        SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: roundedBoxDecoration.copyWith(border: Border.all(width: 1, color: AppColor.darkGrey)),
          child: DropdownButton<String>(
            hint: const Text('Брокер', style: TextStyle(fontSize: 20)),
            underline: Container(),
            isExpanded: true,
            value: broker,
            onChanged: (newBroker) => setState(() => broker = newBroker ?? broker),
            items: availableBrokers.map((b) => DropdownMenuItem<String>(child: Text(b), value: b)).toList(),
          ),
        ),
      ],
    );
  }
}

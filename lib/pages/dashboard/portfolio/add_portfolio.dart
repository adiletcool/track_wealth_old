import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:provider/provider.dart';

class AddPortfolioPage extends StatefulWidget {
  final String title;
  final bool isSeparatePage;

  const AddPortfolioPage({this.title = 'Создание нового портфеля', this.isSeparatePage = true});
  @override
  _AddPortfolioPageState createState() => _AddPortfolioPageState(title);
}

class _AddPortfolioPageState extends State<AddPortfolioPage> {
  String broker = 'Не выбран';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  final String title;

  final nameFormKey = GlobalKey<FormState>();
  ScrollController scrollController = ScrollController();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedCurrency = 'Рубли';
  Map<String, String> currencies = {
    'RUB': 'Рубли',
    'USD000UTSTOM': 'Доллары',
    'EUR_RUB__TOM': 'Евро',
  };

  _AddPortfolioPageState(this.title);

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, Colors.black, AppColor.white);

    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.all(10),
          child: ListView(
            controller: scrollController,
            children: [
              Stack(
                children: [
                  Center(child: Lottie.asset('assets/animations/add_portfolio.json', height: MediaQuery.of(context).size.height * .3, reverse: true)),
                  // Если не новый пользователь
                  if (widget.isSeparatePage)
                    Positioned(
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
                      ),
                    ),
                  // Если новый пользователь
                  if (!widget.isSeparatePage)
                    Positioned(
                      right: 1,
                      child: IconButton(
                        icon: Icon(
                          Icons.logout_rounded,
                        ),
                        onPressed: () => userLogout(context),
                      ),
                    ),
                ],
              ),
              Text(
                title,
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Название', style: TextStyle(fontSize: 16, color: AppColor.darkGrey)),
                  SizedBox(height: 6),
                  Form(
                    key: nameFormKey,
                    child: TextFormField(
                      onTap: scrollDown,
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
                    onTap: scrollDown,
                    controller: descController,
                    decoration: myInputDecoration.copyWith(hintText: 'Расскажите об этом портфеле', counterText: ''),
                    style: TextStyle(fontSize: 18),
                    maxLength: 400,
                    maxLines: 7,
                    minLines: 1,
                  ),
                ],
              ),
              SizedBox(height: 10),
              brokerDropdown(),
              SizedBox(height: 40),
              createPortfolioButton(),
            ],
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

  Widget createPortfolioButton() {
    return Column(children: [
      ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(AppColor.selected),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Text(
            'Добавить',
            style: TextStyle(fontSize: 20, color: AppColor.white),
            textAlign: TextAlign.center,
          ),
        ),
        onPressed: createPortfolio,
      ),
    ]);
  }

  Future<void> createPortfolio() async {
    bool hasConnection = await Connectivity().checkConnection();
    final snackBar = SnackBar(content: Text('Нет соединения с интернетом'));
    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (nameFormKey.currentState!.validate()) {
      String name = nameController.text != '' ? nameController.text.trim() : 'Основной портфель';
      String? decription = descController.text.isEmpty ? null : descController.text;

      String currency = currencies.entries.firstWhere((e) => e.value == selectedCurrency).key;

      await context.read<DashboardState>().addUserPortfolio(name: name, broker: broker, currency: currency, desc: decription);
      context.read<DashboardState>().reloadData();
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
    }
  }

  Future<void> scrollDown() async {
    Future.delayed(Duration(milliseconds: 300)).then(
      (value) => scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:provider/provider.dart';

class AddNewPortfolio extends StatefulWidget {
  final String title;
  final bool isSeparatePage;

  const AddNewPortfolio({this.title = 'Создание нового портфеля', this.isSeparatePage = true});
  @override
  _AddNewPortfolioState createState() => _AddNewPortfolioState(title);
}

class _AddNewPortfolioState extends State<AddNewPortfolio> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController brokerController = TextEditingController();

  final String title;
  final nameFormKey = GlobalKey<FormState>();
  ScrollController scrollController = ScrollController();

  String selectedCurrency = 'Рубли';
  Map<String, String> currencies = {
    'RUB': 'Рубли',
    'USD000UTSTOM': 'Доллары',
    'EUR_RUB__TOM': 'Евро',
  };

  _AddNewPortfolioState(this.title);

  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : AppColor.white;

    return Scaffold(
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
                  if (widget.isSeparatePage)
                    Positioned(
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                ],
              ),
              Text(
                title,
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Form(
                key: nameFormKey,
                child: TextFormField(
                  onTap: scrollDown,
                  validator: validateName,
                  controller: nameController,
                  decoration: myInputDecoration.copyWith(hintText: 'Основной портфель*', counterText: ''),
                  style: TextStyle(fontSize: 20),
                  maxLength: 40,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                onTap: scrollDown,
                controller: descController,
                decoration: myInputDecoration.copyWith(hintText: 'Описание', counterText: ''),
                style: TextStyle(fontSize: 20),
                maxLength: 400,
                maxLines: 7,
                minLines: 1,
              ),
              SizedBox(height: 20),
              Text(
                'Основная валюта',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: AppColor.selected),
                  borderRadius: BorderRadius.circular(11.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Row(
                    children: currencies.values.map((name) => currencyButton(name)).toList(),
                  ),
                ),
              ),
              SizedBox(height: 50),
              createPortfolioButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget currencyButton(String name) {
    return Expanded(
      child: Container(
        color: selectedCurrency == name ? AppColor.selected : null,
        padding: const EdgeInsets.all(10),
        child: InkWell(
          child: Text(
            name,
            style: TextStyle(fontSize: 18, color: selectedCurrency == name ? Colors.white : null),
            textAlign: TextAlign.center,
          ),
          onTap: () => setState(() => selectedCurrency = name),
        ),
      ),
    );
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
        // onTap: createPortfolio,
      ),
    ]);
  }

  String? validateName(String? name) {
    if (name!.isEmpty) name = 'Основной портфель';
    name = name.trim();
    if (name.length < 3) return 'Имя должно содержать не менее трех символов';
    List<Portfolio> portfolios = context.read<DashboardState>().portfolios;
    bool hasSameName = portfolios.any((portfolio) => portfolio.name == name);
    if (hasSameName) {
      return 'Портфель с таким именем уже существует';
    }
    return null;
  }

  Future<void> createPortfolio() async {
    if (nameFormKey.currentState!.validate()) {
      String name = nameController.text != '' ? nameController.text.trim() : 'Основной портфель';
      String? decription = descController.text.isEmpty ? null : descController.text;
      String? broker = brokerController.text.isEmpty ? null : brokerController.text;

      String currency = currencies.entries.firstWhere((e) => e.value == selectedCurrency).key;

      await context.read<DashboardState>().addUserPortfolio(name: name, broker: broker, currency: currency, desc: decription);
      if (!widget.isSeparatePage)
        context.read<DashboardState>().reloadData();
      else
        Navigator.pushNamed(context, '/dashboard');
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

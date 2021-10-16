import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/models/portfolio_trade.dart';
import 'package:track_wealth/common/models/search_stock_model.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/decorations.dart';
import 'package:track_wealth/common/static/formatters.dart';
import 'stock_search/searchable_dropdown.dart';
import 'package:collection/collection.dart';

class AddOperationPage extends StatefulWidget {
  @override
  _AddOperationPageState createState() => _AddOperationPageState();
}

class _AddOperationPageState extends State<AddOperationPage> {
  late Portfolio portfolio;
  late num rubAvailable;
  late num usdAvailable;
  late num eurAvailable;

  late Color bgColor;
  late Color textColor;

  final Map<String, List<String>> actions = {
    'stocks': ['buy', 'sell', 'dividends'],
    'money': ["deposit", "withdraw", "revenue", "expense"],
  };

  late String actionType; // stocks / money
  late List<String> selectedActions; // ['buy', 'sell', 'dividends'] / ["deposit", "withdraw", "revenue", "expense"]
  late String action; // buy / sell / ...

  SearchStock? selectedStock; // Н-р, Stock("sber:moex", Сбербанк)
  int selectedStockInPortfolio = 0; // количество (шт) выбранных через поиск акций в портфеле, получаю через getQuantityCounterText

  ScrollController dialogScrollController = ScrollController();

  //* Общие параметры
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TextEditingController noteController = TextEditingController();

  late num? operationTotal;

  //* acttionType == 'stocks', action == 'buy' | 'sell'
  GlobalKey<FormState> searchFormKey = GlobalKey<FormState>();

  GlobalKey<FormState> priceFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> quantityFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> feeFormKey = GlobalKey<FormState>();

  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController feeController = TextEditingController(); // text: '0.00'

  String quantityLabel = "Количество, шт";

  //* acttionType == 'money'
  GlobalKey<FormState> moneyFormKey = GlobalKey<FormState>();
  TextEditingController moneyController = TextEditingController();
  late PortfolioCurrency selectedCurrency;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initializeDateFormatting('ru_RU');

    portfolio = context.read<PortfolioState>().selectedPortfolio;

    rubAvailable = portfolio.currencies!.firstWhere((c) => c.code == 'RUB').value;
    usdAvailable = portfolio.currencies!.firstWhere((c) => c.code == 'USD000UTSTOM').value;
    eurAvailable = portfolio.currencies!.firstWhere((c) => c.code == 'EUR_RUB__TOM').value;

    actionType = actions.keys.first; // stocks / money
    selectedActions = actions[actionType]!; // ['buy', 'sell', 'dividends'] / ["deposit", "withdraw", "revenue", "expense"]
    action = selectedActions.first; // 'buy' / 'sell' / 'dividends' / "deposit" / "withdraw" / "revenue" / "expense"

    selectedCurrency = portfolio.currencies!.first;
  }

  void changeAction(String newAction) {
    if (action != newAction) setState(() => action = newAction);
  }

  void changeActionType(String newActionType) {
    if (actionType != newActionType) {
      setState(() {
        actionType = newActionType;
        selectedActions = actions[actionType]!;
        action = selectedActions.first;
      });
    }
  }

  void changeSelectedStock(SearchStock? newSelectedStock) {
    if (selectedStock != newSelectedStock) {
      print(selectedStock);
      print(newSelectedStock);
      print('newSelectedStock: $newSelectedStock');
      setState(() {
        selectedStock = newSelectedStock;
        priceController.text = selectedStock?.price?.toString() ?? '';
      });
    }
  }

  void changeSelectedCurrency(PortfolioCurrency newCurrency) {
    if (selectedCurrency != newCurrency) setState(() => selectedCurrency = newCurrency);
  }

  onPriceQuantityChanged() {
    // рассчитываем доступное для покупки / продажи количество акций
    // num? price = num.tryParse(priceController.text);
    // int? quantity = int.tryParse(quantityController.text);
  }

  Widget getOperationSummary() {
    List<Widget> children = [];

    switch (actionType) {
      case 'stocks':
        switch (action) {
          case 'buy':
          case 'sell':
            num? price = num.tryParse(priceController.text);
            int? quantity = int.tryParse(quantityController.text);
            num? fee = num.tryParse(feeController.text);
            if (price != null && quantity != null) {
              fee ??= 0;
              operationTotal = price * quantity + fee * (action == 'buy' ? 1 : -1);
            } else
              operationTotal = null;

            children.addAll([
              if (operationTotal != null) footerListTile(operationTotal!),
              footerListTile(rubAvailable, title: 'Доступно:'),
            ]);
            break;
          default:
            break;
        }
        break;
      case 'money':
        operationTotal = num.tryParse(moneyController.text);

        children.addAll([
          footerListTile(selectedCurrency.value, title: 'Доступно:', symbol: selectedCurrency.symbol),
          if (operationTotal != null) footerListTile(operationTotal!, symbol: selectedCurrency.symbol),
        ]);

        break;
      default:
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget footerListTile(num operationTotal, {String title: 'Итого:', String symbol = '₽'}) {
    return ListTile(
      title: Text(title),
      trailing: Text('${MyFormatter.numFormat(operationTotal)} ' + symbol),
      contentPadding: const EdgeInsets.all(0),
      minVerticalPadding: 0,
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
    );
  }

  @override
  Widget build(BuildContext context) {
    bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);
    textColor = AppColor.themeBasedColor(context, Colors.white, AppColor.black);
    String pageTitle = actionsTitle[action] ?? action;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: simpleAppBar(
        context,
        title: ListTile(
          title: Text(pageTitle, style: TextStyle(fontSize: 20, color: textColor)),
          subtitle: Text(portfolio.name),
          contentPadding: const EdgeInsets.all(0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: confirmOperation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 5),
            buttonsRow(buttons: actions.keys, selectedValue: actionType, onTap: changeActionType),
            SizedBox(height: 20),
            buttonsRow(buttons: selectedActions, selectedValue: action, onTap: changeAction),
            Divider(height: 10, indent: 40, endIndent: 40),
            Expanded(
              child: ListView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: dialogScrollController,
                children: [
                  SizedBox(height: 10),

                  getOperationFields(), // пресет операций
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [datePicker(), timePicker()],
                  ),
                  SizedBox(height: 20),
                  noteTextField(),
                  SizedBox(height: 20),
                  getOperationSummary(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? validateSearch() {
    if (selectedStock == null) return 'Выберите акцию';
    return null;
  }

  String? validateNum(String? value, {String onNull = 'Введите цену'}) {
    if ([null, ''].contains(value))
      return onNull;
    else if (num.parse(value!) == 0) return 'Введите положительное число';
    return null;
  }

  String? validateInt(String? value, {String onNull = 'Введите количество'}) {
    if ([null, ''].contains(value))
      return onNull;
    else if (int.parse(value!) == 0) return 'Введите положительное число';
    return null;
  }

  String getQuantityCounterText() {
    /// Возвращет информацию о количестве акций в 1 лоте + количестве штук в портфеле, если есть
    selectedStockInPortfolio = portfolio.stocks!.firstWhereOrNull((a) => a.shortName == selectedStock!.shortName)?.quantity ?? 0;
    String counterText = '1 лот = ${selectedStock?.lotSize} шт. '; // TODO int formatter

    counterText += "${selectedStockInPortfolio == 0 ? '' : ' У вас $selectedStockInPortfolio шт.'}";

    return counterText;
  }

  Future<void> confirmOperation() async {
    // хватает ли денег (при покупке)
    // если продажа, хватает ли акций
    // сохранять в tradeHistory
    // менять stocks (quantity, meanPrice), все остальное пересчитывается тут
    switch (actionType) {
      case 'stocks':
        String snackBarText;
        bool canPop = false;

        switch (action) {
          case 'buy':
          case 'sell':
            bool searchOk = searchFormKey.currentState!.validate();
            bool priceOk = priceFormKey.currentState!.validate();
            bool quantityOk = quantityFormKey.currentState!.validate();

            if (searchOk && priceOk && quantityOk) {
              num price = num.parse(priceController.text);
              int quantity = int.parse(quantityController.text);
              num fee = feeController.text == '' ? 0 : num.parse(feeController.text);

              StockTrade trade = StockTrade(
                date: DateTime.now().toString(),
                action: action,
                currencyCode: 'RUB',
                note: noteController.text,
                secId: selectedStock!.secId,
                shortName: selectedStock!.shortName,
                boardId: selectedStock!.primaryBoardId,
                price: price,
                quantity: quantity,
                fee: fee,
              );

              if (action == 'buy') {
                AddOperationResult result = await portfolio.buyOperation(context, trade);

                if (result.type == ResultType.ok) {
                  snackBarText = 'Куплено ${selectedStock!.secId}: $quantity шт. по $price руб.\n'
                      'Итого: ${MyFormatter.numFormat(operationTotal!)}';
                  canPop = true;
                } else if (result.type == ResultType.notEnoughCash) {
                  snackBarText = 'Недостаточно денежных средств.\n'
                      'Сумма сделки: ${MyFormatter.numFormat(result.opeartionTotal!, decimals: 2)}.\n'
                      'Доступно: ${MyFormatter.numFormat(result.cashAvailable!, decimals: 2)}';
                } else
                  snackBarText = 'Что-то пошло не так...';
              } else if (action == 'sell') {
                AddOperationResult result = await portfolio.sellOperation(context, trade);

                if (result.type == ResultType.ok) {
                  snackBarText = 'Продано ${selectedStock!.secId}: $quantity шт. по $price руб.\n'
                      'Итого: $operationTotal';
                  canPop = true;
                } else if (result.type == ResultType.notEnoughStocks) {
                  int stocksAvailable = result.stocksAvailable!;
                  snackBarText = 'У вас недостаточно акций.\n'
                      'Количество на продажу: ${MyFormatter.intFormat(quantity)}.\n'
                      'Доступно: ${MyFormatter.intFormat(stocksAvailable)} шт.';
                } else
                  snackBarText = 'Что-то пошло не так...';
              } else
                throw 'Unknown action $action of actionType $actionType';

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarText)));
              if (canPop) Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
            }
            break;
          // TODO add dividends trade
          // case 'dividends':
          //   return;
          default:
            throw 'Unknown action $action';
        }
        break;
      case 'money':
        String snackBarText;
        bool canPop = false;
        bool moneyOk = moneyFormKey.currentState!.validate();

        if (moneyOk) {
          MoneyTrade trade = MoneyTrade(
            date: DateTime.now().toString(),
            action: action,
            currencyCode: selectedCurrency.code,
            operationTotal: operationTotal!,
            note: noteController.text,
          );

          switch (action) {
            case 'deposit':
            case 'revenue':
              String _snackT = action == 'deposit' ? 'Внесено: ' : 'Доход';
              await portfolio.revenueOperation(context, selectedCurrency, trade);
              snackBarText = _snackT + '${MyFormatter.numFormat(operationTotal!)} ${selectedCurrency.symbol}';
              canPop = true;
              break;

            // TODO: does not updates, try to listen to currencies // loadstate
            case 'withdraw':
            case 'expense':
              String _snackT = action == 'withdraw' ? 'Вывод: ' : 'Расход: ';

              AddOperationResult result = await portfolio.expenseOperation(context, selectedCurrency, trade);
              if (result.type == ResultType.ok) {
                snackBarText = _snackT + '${MyFormatter.numFormat(operationTotal!)} ${selectedCurrency.symbol}';
                canPop = true;
              } else if (result.type == ResultType.notEnoughCash) {
                snackBarText = 'Недостаточно средств.\n' +
                    _snackT +
                    '${MyFormatter.numFormat(operationTotal!)} ${selectedCurrency.symbol}\n'
                        'Доступно ${MyFormatter.numFormat(selectedCurrency.value)} ${selectedCurrency.symbol}';
              } else
                snackBarText = 'Что-то пошло не так...';
              break;
            default:
              throw 'Unknown action $action';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarText)));
          if (canPop) Navigator.pop(context);
        }
        break;
      default:
        return;
    }
  }

  Widget getOperationFields() {
    switch (actionType) {
      case 'stocks':
        switch (action) {
          case 'buy':
          case 'sell':
            return Column(
              children: [
                StockSearchField(onSelect: changeSelectedStock, preSelected: selectedStock, formKey: searchFormKey, validate: validateSearch),
                SizedBox(height: 20),
                myTextField(
                  formKey: priceFormKey,
                  controller: priceController,
                  validate: validateNum,
                  label: "Цена",
                  suffixText: '₽',
                  onlyInteger: selectedStock?.priceDecimals == 0 ? true : false,
                  decimalRange: selectedStock?.priceDecimals ?? 6,
                  onChanged: (v) => setState(() {}),
                ),
                SizedBox(height: 20),
                myTextField(
                  formKey: quantityFormKey,
                  controller: quantityController,
                  validate: validateInt,
                  label: quantityLabel,
                  suffixText: 'шт',
                  onlyInteger: true,
                  counterText: selectedStock == null ? '' : getQuantityCounterText(),
                  onChanged: (v) => setState(() {}),
                  onTap: () => delayedScrollDown(dialogScrollController),
                ),
                SizedBox(height: 20),
                myTextField(
                  formKey: feeFormKey,
                  controller: feeController,
                  label: "Комиссия",
                  suffixText: '₽',
                  onChanged: (v) => setState(() {}),
                  onTap: () => delayedScrollDown(dialogScrollController),
                ),
              ],
            );
          default:
            return Text('not implemented yet');
        }
      case 'money':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: myTextField(
                formKey: moneyFormKey,
                controller: moneyController,
                validate: (value) => validateNum(value, onNull: 'Введите сумму'),
                label: "Сумма",
                onChanged: (v) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<PortfolioCurrency>(
                borderRadius: BorderRadius.circular(20),
                value: selectedCurrency,
                alignment: Alignment.centerRight,
                underline: Container(),
                onChanged: (c) => changeSelectedCurrency(c!),
                dropdownColor: AppColor.themeBasedColor(
                  context,
                  HSLColor.fromColor(bgColor).withLightness(.15).toColor(),
                  bgColor,
                ),
                items: portfolio.currencies!
                    .map(
                      (e) => DropdownMenuItem<PortfolioCurrency>(child: Text(e.name), value: e),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      default:
        return Text('not implemented yet');
    }
  }

  Widget buttonsRow({required Iterable<String> buttons, required String selectedValue, required Function(String value) onTap}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: AppColor.themeBasedColor(context, AppColor.bgDark, AppColor.greyTitle)),
        borderRadius: BorderRadius.circular(11.0),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons
            .map(
              (e) => Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: InkWell(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: e == selectedValue ? AppColor.selected : AppColor.white,
                      ),
                      child: Text(
                        actionsTitle[e]!,
                        style: TextStyle(color: e == selectedValue ? AppColor.white : AppColor.lightBlue),
                      ),
                    ),
                    onTap: () => onTap(e),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget myTextField({
    required Key formKey,
    required TextEditingController controller,
    required String label,
    String? Function(String? value)? validate,
    bool onlyInteger = false,
    String suffixText: '',
    String counterText = '',
    int decimalRange = 2,
    void Function(String)? onChanged,
    void Function()? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          decoration: myInputDecoration.copyWith(
            labelText: label,
            suffixText: suffixText,
            counterText: counterText,
          ),
          validator: validate,
          maxLength: 12,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          maxLines: 1,
          inputFormatters: [
            onlyInteger ? FilteringTextInputFormatter.digitsOnly : DecimalTextInputFormatter(decimalRange: decimalRange),
          ],
          onChanged: onChanged,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget sampleTextButton({required IconData icon, required String label, void Function()? onPressed}) {
    return SizedBox(
      height: 42.5,
      child: TextButton.icon(
        icon: Icon(icon, color: AppColor.selected),
        label: Text(label, style: TextStyle(color: AppColor.selected, fontSize: 17)),
        onPressed: onPressed,
      ),
    );
  }

  Widget datePicker() {
    return sampleTextButton(
      icon: Icons.calendar_today_rounded,
      label: DateFormat.yMMMd('ru').format(selectedDate),
      onPressed: () {
        showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2030),
        ).then((DateTime? newDate) {
          if (newDate != null) {
            setState(() => selectedDate = newDate);
          }
        });
      },
    );
  }

  Widget timePicker() {
    return sampleTextButton(
      icon: Icons.schedule_rounded,
      label: selectedTime.format(context),
      onPressed: () {
        showTimePicker(
          context: context,
          initialTime: selectedTime,
        ).then((TimeOfDay? newTime) {
          if (newTime != null) {
            setState(() => selectedTime = newTime);
          }
        });
      },
    );
  }

  Widget noteTextField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: noteController,
        onTap: () => delayedScrollDown(dialogScrollController),
        maxLength: 500,
        decoration: myInputDecoration.copyWith(counterText: '', labelText: 'Заметка'),
      ),
    );
  }
}

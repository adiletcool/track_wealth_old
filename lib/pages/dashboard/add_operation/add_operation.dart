import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/models/search_asset_model.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/decorations.dart';
import 'package:track_wealth/common/static/formatters.dart';
import 'asset_search/searchable_dropdown.dart';
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
    'Акции': ['Купить', 'Продать', 'Дивиденды'],
    'Деньги': ["Внести", "Вывести", "Доход", "Расход"],
  };

  final Map<String, String> appBarTitle = {'Купить': "Покупка", "Продать": "Продажа"};

  late String actionType; // Акции / Деньги
  late List<String> selectedActions; // ['Купить', 'Продать', 'Дивиденд'] / ["Внести", "Вывести", "Доход", "Расход"]
  late String action; // Купить / Внести / ...

  SearchAsset? selectedAsset; // Н-р, Asset("sber:moex", Сбербанк)
  int selectedAssetInPortfolio = 0; // количество (шт) выбранных через поиск акций в портфеле, получаю через getQuantityCounterText

  ScrollController dialogScrollController = ScrollController();

  //* Общие параметры
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TextEditingController noteController = TextEditingController();

  late num? operationTotal;

  //* acttionType == 'Акции', action == 'Купить' | 'Продать'
  GlobalKey<FormState> searchFormKey = GlobalKey<FormState>();

  GlobalKey<FormState> priceFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> quantityFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> feeFormKey = GlobalKey<FormState>();

  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController feeController = TextEditingController(); // text: '0.00'

  String quantityLabel = "Количество, шт";

  //* acttionType == 'Деньги'
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

    actionType = actions.keys.first; // Акции / Деньги
    selectedActions = actions[actionType]!; // ['Купить', 'Продать', 'Дивиденд'] / ["Внести", "Вывести", "Доход", "Расход"]
    action = selectedActions.first; // 'Купить' / 'Продать' / 'Дивиденд' / "Внести" / "Вывести" / "Доход" / "Расход"

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

  void changeSelectedAsset(SearchAsset? newSelectedAsset) {
    if (selectedAsset != newSelectedAsset) {
      print(selectedAsset);
      print(newSelectedAsset);
      print('newSelectedAsset: $newSelectedAsset');
      setState(() {
        selectedAsset = newSelectedAsset;
        priceController.text = selectedAsset?.price?.toString() ?? '';
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
      case 'Акции':
        switch (action) {
          case 'Купить':
          case 'Продать':
            num? price = num.tryParse(priceController.text);
            int? quantity = int.tryParse(quantityController.text);
            num? fee = num.tryParse(feeController.text);
            if (price != null && quantity != null) {
              fee ??= 0;
              operationTotal = price * quantity + fee * (action == 'Купить' ? 1 : -1);
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
      case 'Деньги':
        num? operationTotal = num.tryParse(moneyController.text);

        children.addAll([
          footerListTile(selectedCurrency.value, title: 'Доступно:', symbol: selectedCurrency.symbol),
          if (operationTotal != null) footerListTile(operationTotal, symbol: selectedCurrency.symbol),
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
    String pageTitle = appBarTitle[action] ?? action;

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
    if (selectedAsset == null) return 'Выберите акцию';
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
    selectedAssetInPortfolio = portfolio.assets!.firstWhereOrNull((a) => a.shortName == selectedAsset!.shortName)?.quantity ?? 0;
    String counterText = '1 лот = ${selectedAsset?.lotSize} шт. ';

    counterText += "${selectedAssetInPortfolio == 0 ? '' : ' У вас $selectedAssetInPortfolio шт.'}";

    return counterText;
  }

  Future<void> confirmOperation() async {
    // хватает ли денег (при покупке)
    // если продажа, хватает ли акций
    // сохранять в tradeHistory
    // менять assets (quantity, meanPrice), все остальное пересчитывается тут
    switch (actionType) {
      case 'Акции':
        String snackBarText;
        bool canPop = false;

        switch (action) {
          case 'Купить':
            bool searchOk = searchFormKey.currentState!.validate();
            bool priceOk = priceFormKey.currentState!.validate();
            bool quantityOk = quantityFormKey.currentState!.validate();

            if (searchOk && priceOk && quantityOk) {
              num price = num.parse(priceController.text);
              int quantity = int.parse(quantityController.text) * ((action == 'Продать') ? -1 : 1);
              num fee = feeController.text == '' ? 0 : num.parse(feeController.text);

              AddOperationResult result = await portfolio.buyOperation(context, selectedAsset!, price, quantity, fee);

              if (result.type == ResultType.ok) {
                snackBarText = 'Куплено ${selectedAsset!.secId}: $quantity шт. по $price руб.\n'
                    'Итого: ${MyFormatter.numFormat(operationTotal!)}';
                canPop = true;
              } else if (result.type == ResultType.notEnoughCash) {
                snackBarText = 'Недостаточно денежных средств.\n'
                    'Сумма сделки: ${MyFormatter.numFormat(result.opeartionTotal!, decimals: 2)}.\n'
                    'Доступно: ${MyFormatter.numFormat(result.cashAvailable!, decimals: 2)}';
              } else
                snackBarText = 'Что-то пошло не так...';

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarText)));
              if (canPop) Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
            }
            break;
          case 'Продать':
            bool searchOk = searchFormKey.currentState!.validate();
            bool priceOk = priceFormKey.currentState!.validate();
            bool quantityOk = quantityFormKey.currentState!.validate();

            if (searchOk && priceOk && quantityOk) {
              num price = num.parse(priceController.text);
              int quantity = int.parse(quantityController.text);
              num fee = feeController.text == '' ? 0 : num.parse(feeController.text);

              AddOperationResult result = await portfolio.sellOperation(context, selectedAsset!, price, quantity, fee);

              if (result.type == ResultType.ok) {
                snackBarText = 'Продано ${selectedAsset!.secId}: $quantity шт. по $price руб.\nИтого: $operationTotal';
                canPop = true;
              } else if (result.type == ResultType.notEnoughAssets) {
                int assetsAvailable = result.assetsAvailable!;
                snackBarText = 'У вас недостаточно акций.\n'
                    'Количество на продажу: ${MyFormatter.intFormat(quantity)}.\n'
                    'Доступно: ${MyFormatter.intFormat(assetsAvailable)} шт.';
              } else
                snackBarText = 'Что-то пошло не так...';

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarText)));
              if (canPop) Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
            }
            break;
          case 'Дивиденд':
            return;
          default:
            throw 'Unknown action $action';
        }
        break;
      case 'Деньги':
        String snackBarText;
        bool canPop = false;
        bool moneyOk = moneyFormKey.currentState!.validate();

        if (moneyOk) {
          num amount = num.parse(moneyController.text);

          switch (action) {
            case 'Внести':
              await portfolio.depositOperation(context, selectedCurrency, amount);
              snackBarText = 'Внесено: ${MyFormatter.numFormat(amount)} ${selectedCurrency.symbol}';
              canPop = true;
              break;
            case 'Вывести':
              AddOperationResult result = await portfolio.withdrawalOperation(context, selectedCurrency, amount);
              if (result.type == ResultType.ok) {
                snackBarText = 'Снято: ${MyFormatter.numFormat(amount)} ${selectedCurrency.symbol}';
                canPop = true;
              } else if (result.type == ResultType.notEnoughCash) {
                snackBarText = 'Недостаточно средств.\n'
                    'Вывод: ${MyFormatter.numFormat(amount)} ${selectedCurrency.symbol}\n'
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
      case 'Акции':
        switch (action) {
          case 'Купить':
          case 'Продать':
            return Column(
              children: [
                AssetSearchField(selectedAssetCallback: changeSelectedAsset, preSelectedAsset: selectedAsset, formKey: searchFormKey, validate: validateSearch),
                SizedBox(height: 20),
                myTextField(
                  formKey: priceFormKey,
                  controller: priceController,
                  validate: validateNum,
                  label: "Цена",
                  suffixText: '₽',
                  onlyInteger: selectedAsset?.priceDecimals == 0 ? true : false,
                  decimalRange: selectedAsset?.priceDecimals ?? 6,
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
                  counterText: selectedAsset == null ? '' : getQuantityCounterText(),
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
      case 'Деньги':
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
                        e,
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

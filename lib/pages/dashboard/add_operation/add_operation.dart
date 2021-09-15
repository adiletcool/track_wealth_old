import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/search_asset_model.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'asset_search/searchable_dropdown.dart';
import 'package:collection/collection.dart';

class AddOperationPage extends StatefulWidget {
  @override
  _AddOperationPageState createState() => _AddOperationPageState();
}

class _AddOperationPageState extends State<AddOperationPage> {
  late Portfolio portfolio;
  late num rubAvailable;

  final Map<String, List<String>> actions = {
    'Акции': ['Купить', 'Продать', 'Дивиденд'],
    'Деньги': ["Внести", "Вывести", "Доход", "Расход"],
  };

  late String actionType; // Акции / Деньги
  late List<String> selectedActions; // ['Купить', 'Продать', 'Дивиденд'] / ["Внести", "Вывести", "Доход", "Расход"]
  late String action; // Купить / Внести / ...

  SearchAsset? selectedAsset; // Н-р, Asset("sber:moex", Сбербанк)
  int selectedAssetInPortfolio = 0; // количество (шт) выбранных через поиск акций в портфеле, получаю через getQuantityCounterText

  ScrollController dialogScrollController = ScrollController();

  // Общие параметры
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TextEditingController noteController = TextEditingController();

  // acttionType == 'Акции', action == 'Купить' | 'Продать'
  GlobalKey<FormState> searchFormKey = GlobalKey<FormState>();

  GlobalKey<FormState> priceFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> quantityFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> feeFormKey = GlobalKey<FormState>();

  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController feeController = TextEditingController(); // text: '0.00'

  // acttionType == 'Деньги'
  GlobalKey<FormState> moneyFormKey = GlobalKey<FormState>();
  TextEditingController moneyController = TextEditingController();
  late Map<String, dynamic> selectedCurrency;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initializeDateFormatting('ru_RU');

    portfolio = context.read<PortfolioState>().selectedPortfolio;
    rubAvailable = portfolio.currencies!.firstWhere((c) => c.code == 'RUB').value;

    actionType = actions.keys.first; // Акции / Деньги
    selectedActions = actions[actionType]!; // ['Купить', 'Продать', 'Дивиденд'] / ["Внести", "Вывести", "Доход", "Расход"]
    action = selectedActions.first;

    selectedCurrency = newUserCurrencies.first;
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

  void changeSelectedCurrency(String code) {
    if (selectedCurrency['code'] != code) {}
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, Colors.black, AppColor.white);
    Color textColor = AppColor.themeBasedColor(context, Colors.white, AppColor.black);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: simpleAppBar(
        context,
        title: Text(
          'Добавить операцию',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.done_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: confirmOperation,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: AppResponsive.isDesktop(context) ? 600 : null,
            child: SingleChildScrollView(
              controller: dialogScrollController,
              child: Column(
                children: [
                  SizedBox(height: 5),
                  buttonsRow(buttons: actions.keys, selectedValue: actionType, onTap: changeActionType),
                  SizedBox(height: 20),
                  buttonsRow(buttons: selectedActions, selectedValue: action, onTap: changeAction),
                  SizedBox(height: 20),
                  getOperationPreset(), // пресет операций
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [datePicker(), timePicker()],
                  ),
                  SizedBox(height: 20),
                  noteTextField(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? validateSearch() {
    if (selectedAsset == null) return 'Выберите акцию';
    return null;
  }

  String? validatePrice(String? value) {
    if ([null, ''].contains(value))
      return 'Введите цену';
    else if (num.parse(value!) == 0) return 'Введите положительное число';
    return null;
  }

  String? validateQuantity(String? value) {
    if ([null, ''].contains(value))
      return 'Введите количество';
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
    // TODO: добавить функционал в addOperation для акций -> проверять:
    // хватает ли денег (при покупке)
    // если продажа, хватает ли акций
    // сохранять в tradeHistory
    // менять assets (quantity, meanPrice), все остальное пересчитывается тут
    switch (actionType) {
      case 'Акции':
        switch (action) {
          case 'Купить':
          case 'Продать':
            bool searchOk = searchFormKey.currentState!.validate();
            bool priceOk = priceFormKey.currentState!.validate();
            bool quantityOk = quantityFormKey.currentState!.validate();

            if (searchOk && priceOk && quantityOk) {
              num price = num.parse(priceController.text);
              int quantity = int.parse(quantityController.text) * ((action == 'Продать') ? -1 : 1);
              num fee = feeController.text == '' ? 0 : num.parse(feeController.text);

              num purchaseAmount = price * quantity;

              String snackBarText;

              //* смотрим, хватает ли денег для покупки
              if (purchaseAmount > rubAvailable) {
                snackBarText = 'Недостаточно денежных средств.\n'
                    'Сумма сделки: ${purchaseAmount.toStringAsFixed(2)}. Доступно: ${rubAvailable.toStringAsFixed(2)}';
              } else {
                OperationType _type = action == 'Купить' ? OperationType.buy : OperationType.sell;
                AddOperationResult result = portfolio.addOperation(_type, selectedAsset!, price, quantity, fee);

                switch (result.type) {
                  case ResultType.notEnoughAssets:
                    Map<String, dynamic>? resData = result.data;
                    int assetsAvailable = resData!['assetsAvailable'];
                    snackBarText = 'У вас недостаточно акций. \n'
                        'Количество на продажу: $quantity. Доступно: $assetsAvailable шт.';
                    break;
                  case ResultType.ok:
                    snackBarText = (action == 'Купить' ? 'Куплено' : 'Продано') + ' ${selectedAsset!.secId}: $quantity шт. по $price руб.\nИтого: ';
                    break;
                  default:
                    throw 'Unknow result type ${result.type}';
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackBarText)));
            }
            break;
          case 'Дивиденд':
            return;
          default:
            throw 'Unknown action $action';
        }
        break;
      case 'Деньги':
        switch (action) {
          case 'Внести':
            print('Внести');
            break;
          default:
        }
        break;
      default:
        return;
    }
  }

  Widget getOperationPreset() {
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
                  validate: validatePrice,
                  label: "Цена",
                  suffixText: '₽',
                  onlyInteger: selectedAsset?.priceDecimals == 0 ? true : false,
                  decimalRange: selectedAsset?.priceDecimals ?? 6,
                ),
                SizedBox(height: 20),
                Tooltip(
                  message: tooltips['Количество']!,
                  textStyle: TextStyle(color: Colors.black87),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColor.grey),
                  child: myTextField(
                    formKey: quantityFormKey,
                    controller: quantityController,
                    validate: validateQuantity,
                    label: "Количество, шт",
                    suffixText: 'шт',
                    onlyInteger: true,
                    counterText: selectedAsset == null ? '' : getQuantityCounterText(),
                  ),
                ),
                SizedBox(height: 20),
                myTextField(
                  formKey: feeFormKey,
                  controller: feeController,
                  label: "Комиссия",
                  suffixText: '₽',
                ),
              ],
            );
          default:
            return Text('not implemented yet');
        }
      case 'Деньги':
        return Column(
          children: [
            myTextField(
              formKey: moneyFormKey,
              controller: moneyController,
              validate: validatePrice,
              label: "Сумма",
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
        border: Border.all(width: 1, color: Color(0xff255980)),
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
                        style: TextStyle(color: e == selectedValue ? AppColor.white : Color(0xff255980)),
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
        maxLines: 5,
        maxLength: 500,
        minLines: 1,
        decoration: myInputDecoration.copyWith(counterText: '', labelText: 'Заметка'),
      ),
    );
  }
}

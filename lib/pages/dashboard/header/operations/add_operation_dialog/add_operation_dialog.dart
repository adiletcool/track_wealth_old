import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:track_wealth/common/constants.dart';

import 'asset_search/asset_model.dart';
import 'asset_search/searchable_dropdown.dart';

class AddOperationDialog extends StatefulWidget {
  @override
  _AddOperationDialogState createState() => _AddOperationDialogState();
}

class _AddOperationDialogState extends State<AddOperationDialog> {
  final Map<String, List<String>> actions = {
    'Акции': ['Купить', 'Продать'],
    'Деньги': ["Внести", "Вывести", "Доход", "Расход"],
  };

  late String actionType; // Акции / Деньги
  late List<String> selectedActions; // ['Купить', 'Продать'] / ["Внести", "Вывести", "Доход", "Расход"]
  late String action; // Купить / Внести

  Asset? selectedAsset; // Н-р, Asset("sber:moex", Сбербанк)

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  GlobalKey<FormState> priceFormKey = GlobalKey<FormState>();
  TextEditingController priceController = TextEditingController();

  GlobalKey<FormState> quantityFormKey = GlobalKey<FormState>();
  TextEditingController quantityController = TextEditingController();

  GlobalKey<FormState> feeFormKey = GlobalKey<FormState>();
  TextEditingController feeController = TextEditingController(); // text: '0.00'

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
    actionType = actions.keys.first; // Акции / Деньги
    selectedActions = actions[actionType]!; // ['Купить', 'Продать'] / ["Внести", "Вывести", "Доход", "Расход"]
    action = selectedActions.first;
  }

  void changeAction(String newAction) {
    if (action != newAction) setState(() => action = newAction);
  }

  void changeActionType(String newActionType) {
    if (actionType != newActionType)
      setState(() {
        actionType = newActionType;
        selectedActions = actions[actionType]!;
        action = selectedActions.first;
      });
  }

  void changeSelectedAsset(Asset newSelectedAsset) {
    // Future<void> ... async
    if (selectedAsset != newSelectedAsset)
      setState(() {
        selectedAsset = newSelectedAsset;
        // TODO await price, lotSize, priceDecimals
        selectedAsset!.price = 100.125;
        selectedAsset!.lotSize = 10;
        selectedAsset!.priceDecimals = 3;
        priceController.text = newSelectedAsset.price.toString();
      });
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Валидатор для selectedAsset(а не значение поля) и selectedDate
    //TODO: Валидатор для значения полей цены и количества
    return AlertDialog(
      insetPadding: const EdgeInsets.all(0),
      backgroundColor: Colors.transparent,
      content: Container(
        width: MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width : 600,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColor.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Добавить операцию',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    iconSize: 28,
                    color: AppColor.selectedDrawerItem,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  //! actionType Акции / Деньги
                  buttonsRow(buttons: actions.keys, selectedValue: actionType, onTap: changeActionType),
                  //! actions ['Купить', 'Продать'] / ["Внести", "Вывести", "Доход", "Расход"]
                  buttonsRow(buttons: selectedActions, selectedValue: action, onTap: changeAction),
                  //!
                  if (actionType == actions.keys.first) //! search for assets
                    SizedBox(
                      child: AssetSearchField(selectedAssetCallback: changeSelectedAsset, preSelectedAsset: selectedAsset),
                      height: 50,
                    ),
                ],
              ),
              SizedBox(height: 20),
              if (actionType == actions.keys.first)
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    // SizedBox(width: 20),
                    myTextField(
                      formKey: priceFormKey,
                      controller: priceController,
                      label: "Цена",
                      suffixText: '₽',
                      decimalRange: selectedAsset?.priceDecimals ?? 6,
                    ),
                    Tooltip(
                      message: 'Размер лота * Количество лотов',
                      textStyle: TextStyle(color: Colors.black87),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColor.grey),
                      child: myTextField(
                        formKey: quantityFormKey,
                        controller: quantityController,
                        label: "Количество",
                        suffixText: 'шт',
                        onlyInteger: true,
                        counterText: selectedAsset?.lotSize == null ? '' : "1 лот = ${selectedAsset?.lotSize} шт.",
                      ),
                    ),
                    myTextField(
                      formKey: feeFormKey,
                      controller: feeController,
                      label: "Комиссия",
                      suffixText: '₽',
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    height: 42.5,
                    child: TextButton.icon(
                      icon: Icon(Icons.calendar_today_rounded),
                      label: Text(DateFormat.yMMMd('ru').format(selectedDate)),
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
                    ),
                  ),
                  SizedBox(
                    height: 42.5,
                    child: TextButton.icon(
                      icon: Icon(Icons.schedule_rounded),
                      label: Text(selectedTime.format(context)),
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
                    ),
                  )
                ],
              ),
              SizedBox(height: 50),
              Text('Заметка'),
              Text('Начислить/Списать checkbox'),
              Text('image placeholder'),
            ],
          ),
        ),
      ),
    );
  }

  Container buttonsRow({required Iterable<String> buttons, required String selectedValue, required Function(String value) onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.grey,
        border: Border.all(width: 1, color: AppColor.selectedDrawerItem),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons
            .map(
              (e) => InkWell(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: e == buttons.first
                        ? BorderRadius.only(bottomLeft: Radius.circular(10), topLeft: Radius.circular(10))
                        : e == buttons.last
                            ? BorderRadius.only(bottomRight: Radius.circular(10), topRight: Radius.circular(10))
                            : null,
                    color: e == selectedValue ? AppColor.selectedDrawerItem : AppColor.grey,
                  ),
                  child: Text(
                    e,
                    style: TextStyle(color: selectedValue == e ? AppColor.white : AppColor.selectedDrawerItem),
                  ),
                ),
                onTap: () => onTap(e),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget myTextField({
    required Key formKey,
    required TextEditingController controller,
    double width = 150,
    required String label,
    bool onlyInteger = false,
    String suffixText: '',
    String counterText = '',
    int decimalRange = 2,
  }) {
    return Container(
      width: width,
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          decoration: myInputDecoration.copyWith(
            labelText: label,
            suffixText: suffixText,
            counterText: counterText,
          ),
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
}

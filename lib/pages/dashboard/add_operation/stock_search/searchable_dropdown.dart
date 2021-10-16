import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_typeahead/flutter_typeahead.dart";
import 'package:track_wealth/common/models/search_stock_model.dart';
import 'package:track_wealth/common/static/decorations.dart';

class StockSearchField extends StatefulWidget {
  final void Function(SearchStock? selectedAsset) onSelect;
  final SearchStock? preSelected;
  final GlobalKey<FormState> formKey;
  final String? Function() validate;

  StockSearchField({required this.onSelect, required this.formKey, required this.validate, this.preSelected});

  @override
  _StockSearchFieldState createState() => _StockSearchFieldState();
}

class _StockSearchFieldState extends State<StockSearchField> {
  final TextEditingController typeAheadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preSelected != null) typeAheadController.text = widget.preSelected!.secId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: assetTypeAhead(formKey: widget.formKey, controller: typeAheadController),
    );
  }

  Widget assetTypeAhead({required Key formKey, required TextEditingController controller}) {
    return Form(
      key: formKey,
      child: TypeAheadFormField<SearchStock>(
        validator: (query) => widget.validate(),
        textFieldConfiguration: TextFieldConfiguration(
          onChanged: (query) => widget.onSelect(null),
          controller: controller,
          decoration: myInputDecoration.copyWith(
            suffixIcon: Icon(Icons.arrow_drop_down),
            labelText: "Название/тикер компании",
            hintText: "Сбербанк",
          ),
        ),
        suggestionsCallback: (String query) async => getSearchSuggestion(query),
        itemBuilder: (BuildContext context, SearchStock asset) => searchItemBuilder(context, asset),
        onSuggestionSelected: onSuggesionSelected,
        hideOnEmpty: true,
        noItemsFoundBuilder: (BuildContext context) => Container(),
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          constraints: BoxConstraints(maxHeight: 280),
          borderRadius: BorderRadius.circular(10),
        ),
        hideOnLoading: true,
      ),
    );
  }

  Widget searchItemBuilder(BuildContext context, SearchStock asset) {
    return ListTile(
      title: Text(asset.shortName),
      subtitle: Text(
        "${asset.name}",
        maxLines: 2,
        overflow: TextOverflow.fade,
      ),
    );
  }

  Future<void> onSuggesionSelected(SearchStock selectedAsset) async {
    typeAheadController.text = selectedAsset.secId;
    await selectedAsset.getStockData();
    widget.onSelect(selectedAsset);
  }

  Future<List<SearchStock>> getSearchSuggestion(String query) async {
    if (query.length >= 2) {
      var url = "https://iss.moex.com/iss/securities.json";
      Map<String, String> params = {"q": query, "iss.meta": "off"};

      var response = await Dio().get(url, queryParameters: params);

      List result = response.data["securities"]["data"];
      return SearchStock.fromListOfLists(result);
    }
    print("search is empty");
    return [];
  }
}

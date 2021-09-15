import "dart:async";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_typeahead/flutter_typeahead.dart";
import "package:track_wealth/common/constants.dart";
import 'package:track_wealth/common/models/search_asset_model.dart';

class AssetSearchField extends StatefulWidget {
  final void Function(SearchAsset? selectedAsset) selectedAssetCallback;
  final SearchAsset? preSelectedAsset;
  final GlobalKey<FormState> formKey;
  final String? Function() validate;

  AssetSearchField({required this.selectedAssetCallback, required this.formKey, required this.validate, this.preSelectedAsset});

  @override
  _AssetSearchFieldState createState() => _AssetSearchFieldState();
}

class _AssetSearchFieldState extends State<AssetSearchField> {
  final TextEditingController typeAheadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedAsset != null) typeAheadController.text = widget.preSelectedAsset!.secId;
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
      child: TypeAheadFormField<SearchAsset>(
        validator: (query) => widget.validate(),
        textFieldConfiguration: TextFieldConfiguration(
          onChanged: (query) => widget.selectedAssetCallback(null),
          controller: controller,
          decoration: myInputDecoration.copyWith(
            suffixIcon: Icon(Icons.arrow_drop_down),
            labelText: "Название/тикер компании",
            hintText: "Сбербанк",
          ),
        ),
        suggestionsCallback: (String query) async => getSearchSuggestion(query),
        itemBuilder: (BuildContext context, SearchAsset asset) => searchItemBuilder(context, asset),
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

  Widget searchItemBuilder(BuildContext context, SearchAsset asset) {
    return ListTile(
      title: Text(asset.shortName),
      subtitle: Text(
        "${asset.name})",
        maxLines: 2,
        overflow: TextOverflow.fade,
      ),
    );
  }

  Future<void> onSuggesionSelected(SearchAsset selectedAsset) async {
    typeAheadController.text = selectedAsset.secId;
    await selectedAsset.getStockData();
    widget.selectedAssetCallback(selectedAsset);
  }

  Future<List<SearchAsset>> getSearchSuggestion(String query) async {
    if (query.length >= 2) {
      var url = "https://iss.moex.com/iss/securities.json";
      Map<String, String> params = {"q": query, "iss.meta": "off"};

      var response = await Dio().get(url, queryParameters: params);

      List result = response.data["securities"]["data"];
      return SearchAsset.fromListOfLists(result);
    }
    print("search is empty");
    return [];
  }
}

import 'dart:convert';

import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/widgets/data_grid_view.dart';
import 'free_product_selector.dart';

class PromoCodePage extends StatefulWidget {
  final dynamic appliesPromoProcedure;
  final dynamic transaction;
  final dynamic appliesPromo;
  PromoCodePage(
      {Key key,
      this.appliesPromoProcedure,
      this.transaction,
      this.appliesPromo})
      : super(key: UniqueKey());
  @override
  _PromoCodePageState createState() => _PromoCodePageState();
}

class _PromoCodePageState extends State<PromoCodePage> {
  final FocusNode _keyboardListenerFn = FocusNode();
  final GlobalKey<DataGridViewState> _gridViewPromoKey = GlobalKey();
  final formatDate = DateFormat("EEEE, d MMMM yyyy");
  var _itemLoops;

  _updateDataNew(String promoCode) async {
    List<Map<String, dynamic>> items = [];
    var fResponse = widget.appliesPromoProcedure;
    await Future.delayed(Duration(milliseconds: 1), () {
      if (fResponse != null) {
        List<dynamic> xItem = fResponse;
        xItem.forEach((f) {
          Map<String, dynamic> rowData = {};
          rowData["promo_name"] = f["promo_name"];
          rowData["valid_date"] = f["finish_date"];
          rowData["procedure"] = f["procedur"];
          rowData["promo_code"] = promoCode;
          rowData["benefit"] = f["benefit"];
          rowData["promo_id"] = f["promo_id"];
          rowData["is_procedure"] = rowData["is_procedure"];
          items.add(rowData);
        });
      }
      // items.add({});
      setState(() {
        widget.appliesPromoProcedure[''] = items;
        _gridViewPromoKey.currentState.reFocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardListenerFn,
      onKey: (onKeys) {
        if (!(onKeys is RawKeyUpEvent)) {
          return;
        }

        if (_keyboardListenerFn.hasFocus) {
          bool isControlPressed = onKeys.isControlPressed;

          if (onKeys.logicalKey == LogicalKeyboardKey.f12 ||
              (onKeys.isShiftPressed &&
                  onKeys.logicalKey == LogicalKeyboardKey.arrowDown) ||
              (isControlPressed &&
                  onKeys.isShiftPressed &&
                  onKeys.logicalKey == LogicalKeyboardKey.arrowDown)) {
            _gridViewPromoKey.currentState.focusToLastRowFirstColumn();
            return;
          }

          if (isControlPressed &&
              onKeys.logicalKey == LogicalKeyboardKey.arrowUp) {
            _gridViewPromoKey.currentState.focusToPreviosRow();
            return;
          }

          if (isControlPressed &&
              onKeys.logicalKey == LogicalKeyboardKey.arrowDown) {
            _gridViewPromoKey.currentState.focusToNextRow();
            return;
          }

          if (isControlPressed &&
              onKeys.logicalKey == LogicalKeyboardKey.arrowRight) {
            _gridViewPromoKey.currentState.focusToNextColumn();
            return;
          }

          if (isControlPressed &&
              onKeys.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _gridViewPromoKey.currentState.focusToPreviousColumn();
            return;
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Container(
            margin: const EdgeInsets.all(5.0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Builder(builder: (context) {
              List<DataGridColumn> columns = [];

              columns.add(DataGridColumn(
                header: "No",
                width: 40,
                readOnly: true,
                textAlign: TextAlign.center,
                onGetValue: (rowIndex) {
                  return "${rowIndex + 1}";
                },
                style: Theme.of(context).textTheme.caption,
              ));

              columns.add(DataGridColumn(
                field: "promo_name",
                header: "Promo Name",
                readOnly: true,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                field: "valid_date",
                header: "Valid Date",
                readOnly: true,
                columnType: DataGridColumnType.date,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                field: "procedure",
                header: "Procedure",
                readOnly: true,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                autoFocusable: true,
                field: "promo_code",
                header: "Promo Code",
                onSubmitted: (state, text, rowData) async {
                  setState(() {
                    _updateDataNew(text);
                  });
                  return true;
                },
              ));

              return DataGridView(
                key: _gridViewPromoKey,
                hightlightBackgroundColor: Colors.blue.shade100,
                dataSource: widget.appliesPromoProcedure,
                header: Container(
                  height: 80,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Input Promo Code',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline
                                                .copyWith(
                                                  fontWeight: FontWeight.w400,
                                                )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 1.0,
                        color: Theme.of(context).dividerColor,
                      ),
                    ],
                  ),
                ),
                columns: columns,
                footer: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            height: 10.0,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.all(8.0),
                                  child: OutlineButton.icon(
                                    icon: Icon(
                                      Icons.blur_circular,
                                      color: Colors.green,
                                    ),
                                    label: Text(
                                      "PROCESS",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    highlightedBorderColor: Colors.green,
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2),
                                    onPressed: () async {
                                      await _setPromoProcedure();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })),
      ),
    );
  }

  _setPromoProcedure() async {

    print(widget.transaction["sales_transaction_id"]);
    print(widget.appliesPromo["data"]["member_id"]);
    print(widget.appliesPromo["data"]["applies_promo"]);
    print(widget.appliesPromoProcedure);

    List<dynamic> fixedPromo = List();
    for(final promo in widget.appliesPromo["data"]["applies_promo"]) {
      if(!promo.containsKey("promo_id")){
        continue;
      }

      fixedPromo.add(promo);
    }

    var submissionData = {
      "sales_transaction_id": widget.transaction["sales_transaction_id"],
      "member_id": widget.appliesPromo["data"]["member_id"],
      "applies_promo": fixedPromo,
      "applies_promo_procedure": widget.appliesPromoProcedure,
    };

    print(json.encode(submissionData));

    final response =
        await Http.getData(endpoint: "pos.set_promo_procedure", data: submissionData);
    // setState(() {
    //   _itemLoops = response["data"];
    // });

    print(response);

    if (response["data"] != null && response["success"]) {
      List<dynamic> xData = response["data"]["applies_promo"];
      if (xData.length != 0) {
        xData.forEach((item) {
          switch (item["benefit"]) {
            case 1:
              _benefitFirst(item["promo_id"]);
              break;
            case 2:
              _benefitSecond(item["promo_id"]);
              break;
            case 3:
              _benefitThird();
              break;
            case 4:
              _benefitFourth();
              break;
            default:
          }
        });
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, true);
      }
    } else {
      Navigator.pop(context, true);
    }
  }

  //FIRST Benefit [DONE]
  _benefitFirst(var promoID) async {
    final freeProductResponse = await Http.getData(
        endpoint: "pos.get_free_product",
        data: {"promo_id": promoID, "member_id": _itemLoops["member_id"]});
    Map<String, dynamic> freeProductJson = {
      "free_product": jsonEncode(freeProductResponse["data"]["free_products"]),
    };
    if (freeProductResponse != null &&
        freeProductResponse["data"]["is_one_product"]) {
      var xResult = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => FreeProductsSelector(
                list: freeProductResponse["data"]["free_products"],
              ));

      if (xResult != null) {
        _setPromoBenefitFreeProduct(promoID, xResult["free_product"]);
      }
    } else {
      _setPromoBenefitFreeProduct(promoID, freeProductJson["free_product"]);
    }
  }

  //SECOND benefit [DONE]
  _benefitSecond(var promoID) async {
    print("2");
    final responseB = await Http.getData(
        endpoint: "pos.set_promo_benefit_disc_product",
        data: {
          "sales_transaction_id": widget.transaction["sales_transaction_id"],
          "promo_id": promoID,
          "member_id": _itemLoops["member_id"]
        });
    if (responseB != null && responseB["data"]["success"]) {
      Navigator.pop(context, true);
    }
  }

  //THIRD benefit [UNDONE {Kurang api belum jadi}]
  _benefitThird() async {
    print("3");
    final discNominalResponse = await Http.getData(
        endpoint: "pos.set_promo_benefit_disc_nominal", data: {});
    if (discNominalResponse != null && discNominalResponse["data"]["success"]) {
      Navigator.pop(context, true);
    }
  }

  //FOURTH benefit [UNDONE{API belum jadi}]
  _benefitFourth() async {
    print("4");
    final redeemResponse =
        await Http.getData(endpoint: "pos.get_cheap_redeem", data: {});
    if (redeemResponse != null && redeemResponse["data"]["success"]) {}
  }

  _setPromoBenefitFreeProduct(var promoId, var freeProducts) async {
    final freeProductsResponse = await Http.getData(
        endpoint: "pos.set_promo_benefit_free_product",
        data: {
          "sales_transaction_id": widget.transaction["sales_transaction_id"],
          "promo_id": promoId,
          "free_products": freeProducts
        });
    if (freeProductsResponse != null && freeProductsResponse["success"]) {
      Navigator.pop(context, true);
    }
  }
}

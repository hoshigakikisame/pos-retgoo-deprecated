import 'dart:async';

import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:pos_desktop/bloc/shift.dart';
import 'package:pos_desktop/bloc/transaction.dart';
import 'package:pos_desktop/consts/consts.dart';
import 'package:pos_desktop/dialogs/customer_dialog.dart';
import 'package:pos_desktop/dialogs/product_dialog.dart';
import 'package:pos_desktop/dialogs/referral_dialog.dart';
import 'package:pos_desktop/dialogs/shorcut_transaction_dialog.dart';
import 'package:pos_desktop/plugins/display.dart';
import 'package:pos_desktop/widgets/base_control_dialog.dart';
import 'package:pos_desktop/widgets/data_grid_view.dart';

class TransactionPage extends StatefulWidget {
  final dynamic transaction;
  final int template;
  TransactionPage({Key key, this.transaction, this.template})
      : super(key: UniqueKey());

  static TransactionPageState of(BuildContext context,
      [bool rootWidget = true]) {
    final TransactionPageState lastState = rootWidget
        ? context.findRootAncestorStateOfType<TransactionPageState>()
        : context.findAncestorStateOfType<TransactionPageState>();

    if (lastState == null) {
      print("TransactionPageState Is Null");
      return null;
    }

    return lastState;
  }

  @override
  TransactionPageState createState() => TransactionPageState();
}

class TransactionPageState extends State<TransactionPage> {
  final FocusNode _keyboardFocusNode = FocusNode();
  final GlobalKey<DataGridViewState> _gridViewKey = GlobalKey();
  final formatDate = DateFormat("EEEE, d MMMM yyyy");
  bool visibleReferrerHeader = true;
  bool _isEnabledButton = true;
  bool _isEnabledReferral = true;
  String labelBarcode = "Barcode";
  String currentPromos;
  String labelReferral = "SPG";

  @override
  void initState() {
    super.initState();
    _templateSetting();
    _getCurrentPromo();
    _initFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CustomerDisplay.print(
        "GRAND TOTAL:\r\nRP ${NumberFormat("#,##0").format(grandtotal)}");
  }

  _initFocus() {
    var states = DataGridView.of(context);

    if (states == null) {
      return;
    }

    states.focusToCell(0, 1);
  }

  _templateSetting() {
    if (!mounted) return;

    setState(() {
      switch (widget.template) {
        case 0:
          visibleReferrerHeader = false;
          _isEnabledReferral = false;
          break;
        case 1:
          visibleReferrerHeader = false;
          break;
        case 2:
          visibleReferrerHeader = true;
          labelBarcode = "Code";
          labelReferral = "Stylish";
          break;
        default:
      }
    });
  }

  _findProduct(String keyword) async {
    try {
      final response = await Http.getData(
        endpoint: "pos.find_product",
        data: {
          "keyword": keyword,
          "is_keyword_all": false,
          "category_id": null,
          "brand_id": null,
          "customer_id": widget.transaction["customer_id"],
        },
      );
      if (response != null && response["success"]) {
        return response["data"];
      }
    } catch (e) {}

    return [];
  }

  _findCustomer(String keyword) async {
    try {
      final response = await Http.getData(
        endpoint: "pos.find_customer",
        data: {
          "keyword": keyword,
        },
      );

      if (response != null && response["success"]) {
        return response["data"];
      }
    } catch (e) {}

    return [];
  }

  _findReferrer(String keyword) async {
    try {
      final response = await Http.getData(
        endpoint: "pos.find_referral",
        data: {
          "keyword": keyword,
        },
      );

      if (response != null && response["success"]) {
        return response["data"];
      }
    } catch (e) {}

    return [];
  }

  double get grandtotal {
    double result = 0.0;
    widget.transaction["items"].forEach((rowData) {
      double price = rowData["unit_price"] ?? 0.0;
      int qty =
          rowData["qty"] != null ? int.tryParse(rowData["qty"] ?? "0") ?? 0 : 0;
      result += price * qty;
    });
    return result;
  }

  double get qtytotal {
    double result = 0.0;
    widget.transaction["items"].forEach((rowData) {
      int qty =
          rowData["qty"] != null ? int.tryParse(rowData["qty"] ?? "0") ?? 0 : 0;
      result += qty;
    });
    return result;
  }

  _removeItem(var rowData) async {
    final response = await Http.getData(
      endpoint: "pos.remove_detail_cart",
      data: {
        "sales_transaction_detail_id": rowData["sales_transaction_detail_id"],
      },
    );

    if (response != null && response["success"]) {
      setState(() {
        (widget.transaction["items"] as List).remove(rowData);
        _refreshTransaction();
      });

      CustomerDisplay.print(
          "GRAND TOTAL:\r\nRP ${NumberFormat("#,##0").format(grandtotal)}");

      Future.delayed(Duration(milliseconds: 100), () {
        _gridViewKey.currentState.reFocus();
      });
    }
  }

  _setCustomer(dynamic customer) async {
    final response = await Http.getData(endpoint: "pos.set_customer", data: {
      "sales_transaction_id": widget.transaction["sales_transaction_id"],
      "customer_id": customer["customer_id"],
      "customer_code": customer["customer_code"],
      "customer_name": customer["customer_name"]
    });
    if (response != null && response["success"]) {
      List<Map<String, dynamic>> items = [];

      final responseF = await Http.getData(
        endpoint: "pos.get_detail_carts",
        data: {
          "sales_transaction_id": widget.transaction["sales_transaction_id"],
        },
      );

      Future.delayed(Duration(milliseconds: 1), () {
        if (responseF != null && responseF["success"]) {
          if (responseF["data"]["sales_transaction_details"] != null) {
            List<dynamic> refreshedItem =
                responseF["data"]["sales_transaction_details"];

            refreshedItem.forEach((item) {
              Map<String, dynamic> rowData = {};

              rowData["sales_transaction_id"] =
                  widget.transaction["sales_transaction_id"];
              rowData["sales_transaction_detail_id"] =
                  item["ret_sales_transaction_detail_id"];
              rowData["uom_id"] = item["ret_uom_id"];
              rowData["unit"] = item["ret_uom_name"];
              rowData["product_id"] = item["ret_product_id"];
              rowData["unit_price"] =
                  ((item["ret_default_unit_price"] ?? 0.0) as num)?.toDouble();
              rowData["employee_id"] = item["ret_employee_id"];
              rowData["barcode"] = item["ret_product_qrcode"];
              rowData["item"] = item["ret_product_name"];
              rowData["qty"] =
                  (item["ret_qty"] as num).toDouble().round().toString();
              rowData["tax_id"] = item["ret_tax_id"];
              rowData["is_included_tax"] = item["ret_is_included_tax"];
              rowData["uom_product_id"] = item["ret_uom_product_id"];
              rowData["qty_convert"] = item["ret_qty_convert"] as num;
              rowData["referral"] = item["ret_employee_name"];
              items.add(rowData);
            });
          }
        }
        items.add({});
        setState(() {
          widget.transaction["customer_name"] =
              response["data"]["customer_name"];
          widget.transaction["customer_id"] = response["data"]["customer_id"];
          widget.transaction["customer_code"] =
              response["data"]["customer_code"];
          widget.transaction["items"] = items;
        });
      });
    }
  }

  _displayData(rowData) {
    String itemName = rowData["item"];
    String qtyString = rowData["qty"].toString();
    double price = rowData["unit_price"] ?? 0.0;
    int qty = rowData["qty"] != null ? int.tryParse(rowData["qty"]) ?? 0 : 0;
    final st = price * qty;
    if (itemName != null) {
      if (itemName.length > 20) {
        itemName = itemName.substring(0, 19);
      }
    }
    CustomerDisplay.print(
      "${itemName?.toUpperCase()}\r\n$qtyString x ${NumberFormat("0").format(price)} = ${NumberFormat("0").format(st)}",
    );
    Future.delayed(Duration(seconds: 3), () {
      CustomerDisplay.print(
          "GRAND TOTAL:\r\nRP ${NumberFormat("#,##0").format(grandtotal)}");
    });
  }

  _setReferralHeader(dynamic referralHeader) async {
    final response = await Http.getData(endpoint: "pos.set_referral", data: {
      "sales_transaction_id": widget.transaction["sales_transaction_id"],
      "referral_id": referralHeader["employee_id"],
      "referral_code": referralHeader["employee_code"],
      "referral_name": referralHeader["employee_name"]
    });
    if (response != null && response["success"]) {
      setState(() {
        widget.transaction["referral_id"] = response["data"]["referral_id"];
        widget.transaction["referral_code"] = response["data"]["referral_code"];
        widget.transaction["referral_name"] = response["data"]["referral_name"];
      });
    }
  }

  _getCurrentPromo() async {
    final response = await Http.getData(endpoint: "pos.get_current_promo");
    if (response != null && response["success"]) {
      dynamic responseApi = response["data"]["promos"];
      String singleString = "";
      List<String> iterableString = List();

      responseApi.forEach((mapX) {
        Map<String, dynamic> iteratorMap = mapX;
        iterableString.add(iteratorMap.containsKey("ret_promo_name")
            ? iteratorMap["ret_promo_name"]
            : "");
      });

      iterableString.forEach((stringItem) {
        int index = iterableString.indexOf(stringItem);
        if (index == iterableString.length - 1) {
          singleString = singleString + stringItem;
        } else {
          singleString = singleString + stringItem + '    ';
        }
      });
      if (mounted)
        setState(() {
          if (singleString == "") {
            currentPromos = "Tidak ada promo!";
          } else {
            currentPromos = singleString;
          }
        });
    }
  }

  _refreshTransaction() async {
    List<Map<String, dynamic>> items = [];

    final responseF = await Http.getData(
      endpoint: "pos.get_detail_carts",
      data: {
        "sales_transaction_id": widget.transaction["sales_transaction_id"],
      },
    );

    Future.delayed(Duration(milliseconds: 1), () {
      if (responseF != null && responseF["success"]) {
        if (responseF["data"]["sales_transaction_details"] != null) {
          List<dynamic> refreshedItem =
              responseF["data"]["sales_transaction_details"];

          refreshedItem.forEach((item) {
            Map<String, dynamic> rowData = {};

            rowData["sales_transaction_id"] =
                widget.transaction["sales_transaction_id"];
            rowData["sales_transaction_detail_id"] =
                item["ret_sales_transaction_detail_id"];
            rowData["uom_id"] = item["ret_uom_id"];
            rowData["unit"] = item["ret_uom_name"];
            rowData["product_id"] = item["ret_product_id"];
            rowData["unit_price"] =
                ((item["ret_default_unit_price"] ?? 0.0) as num)?.toDouble();
            rowData["employee_id"] = item["ret_employee_id"];
            rowData["barcode"] = item["ret_product_qrcode"];
            rowData["item"] = item["ret_product_name"];
            rowData["qty"] =
                (item["ret_qty"] as num).toDouble().round().toString();
            rowData["tax_id"] = item["ret_tax_id"];
            rowData["is_included_tax"] = item["ret_is_included_tax"];
            rowData["uom_product_id"] = item["ret_uom_product_id"];
            rowData["qty_convert"] = item["ret_qty_convert"] as num;
            rowData["referral"] = item["ret_employee_name"];
            items.add(rowData);
          });
        }
      }

      items.add({});
      setState(() {
        widget.transaction["items"] = items;
        _gridViewKey.currentState.reFocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      onKey: (ev) {
        if (!(ev is RawKeyUpEvent)) {
          return;
        }

        if (_keyboardFocusNode.hasFocus) {
          bool isControlPressed = ev.isControlPressed;

          if (ev.logicalKey == LogicalKeyboardKey.delete) {
            var rowData = _gridViewKey.currentState.getSelectedRowData();

            if (rowData != null &&
                rowData["sales_transaction_detail_id"] != null) {
              _removeItem(rowData);
            }
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f12 ||
              (ev.isShiftPressed &&
                  ev.logicalKey == LogicalKeyboardKey.arrowDown) ||
              (isControlPressed &&
                  ev.isShiftPressed &&
                  ev.logicalKey == LogicalKeyboardKey.arrowDown)) {
            _gridViewKey.currentState.focusToLastRowFirstColumn();
            return;
          }

          if (isControlPressed && ev.logicalKey == LogicalKeyboardKey.arrowUp) {
            _gridViewKey.currentState.focusToPreviosRow();
            return;
          }

          if (isControlPressed &&
              ev.logicalKey == LogicalKeyboardKey.arrowDown) {
            _gridViewKey.currentState.focusToNextRow();
            return;
          }

          if (isControlPressed &&
              ev.logicalKey == LogicalKeyboardKey.arrowRight) {
            _gridViewKey.currentState.toNextColumn();
            return;
          }

          if (isControlPressed &&
              ev.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _gridViewKey.currentState.focusToPreviousColumn();
            return;
          }
        }

        if (ev.logicalKey == LogicalKeyboardKey.home) {
          if (_isEnabledButton) {
            _selectCustomer();
            _isEnabledButton = false;
          }
          return;
        }
        if (ev.logicalKey == LogicalKeyboardKey.end) {
          if (_isEnabledReferral && visibleReferrerHeader) {
            _selectReferral();
            _isEnabledReferral = false;
          }
          return;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
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

            columns.add(
              DataGridColumn(
                autoFocusable: true,
                field: "barcode",
                header: labelBarcode,
                width: 180,
                suffix: SizedBox(
                  width: 24.0,
                  height: 14.0,
                  child: IconButton(
                    icon: Icon(Icons.more_horiz),
                    padding: const EdgeInsets.all(0.0),
                    iconSize: 18.0,
                    onPressed: () {},
                  ),
                ),
                onSubmitted: (state, text, rowData) async {
                  if (_isEnabledButton) {
                    setState(() {
                      _isEnabledButton = false;
                    });
                    final List response = await _findProduct(text);

                    if (response.isEmpty) {
                      setState(() {
                        _isEnabledButton = true;
                      });
                      return false;
                    }

                    var item;
                    if (response.length == 1) {
                      item = response.elementAt(0);
                    } else {
                      item = await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) => WillPopScope(
                          onWillPop: () async {
                            return _isEnabledButton = true;
                          },
                          child: BaseControlDialog(
                            isUsingDefaultContainer: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  "Choose Item",
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(
                                  height: 8.0,
                                ),
                                Expanded(
                                  child: ProductSelectionDialog(
                                    list: response,
                                    text: text,
                                  ),
                                ),
                                SizedBox(
                                  height: 8.0,
                                ),
                                Container(
                                  height: 1.0,
                                  color: Theme.of(context).dividerColor,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    FlatButton(
                                      child: Text("CANCEL"),
                                      onPressed: () {
                                        _isEnabledButton = true;
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (item != null) {
                      setState(() {
                        _isEnabledButton = true;
                      });
                      for (int i = 0;
                          i < widget.transaction["items"].length;
                          i++) {
                        final rowData1 =
                            widget.transaction["items"].elementAt(i);

                        if (rowData1["product_id"] == item["ret_product_id"] &&
                            rowData1["uom_id"] == item["ret_uom_id"]) {
                          if (useAutoIncrement) {
                            Future.delayed(Duration(milliseconds: 100), () {
                              setState(() async {
                                var qtyX = rowData1["qty"] != null
                                    ? double.parse(rowData1["qty"]).round() + 1
                                    : 1;
                                rowData1["qty"] = qtyX.toString();

                                final responseX = await Http.getData(
                                  endpoint: "pos.add_detail_cart",
                                  data: rowData1,
                                );
                                if (responseX != null && responseX["success"]) {
                                  _displayData(rowData1);
                                  rowData1["sales_transaction_detail_id"] =
                                      responseX["data"]
                                          ["sales_transaction_detail_id"];
                                }
                                setState(() {});
                                Future.delayed(Duration(milliseconds: 100), () {
                                  _gridViewKey.currentState.reFocus();
                                });
                              });
                            });
                            rowData.clear();
                            return false;
                          } else {
                            if (widget.transaction["items"].indexOf(rowData1) !=
                                widget.transaction["items"].indexOf(rowData)) {
                              rowData.clear();
                            }
                            return false;
                          }
                        }
                      }

                      rowData["sales_transaction_id"] =
                          widget.transaction["sales_transaction_id"];
                      rowData["product_id"] = item["ret_product_id"];
                      rowData["uom_id"] = item["ret_uom_id"];
                      rowData["tax_id"] = item["ret_tax_id"];
                      rowData["is_included_tax"] = item["ret_is_included_tax"];
                      rowData["uom_product_id"] = item["ret_uom_product_id"];
                      rowData["qty_convert"] =
                          (item["ret_qty_convert"] as num).toDouble();
                      rowData["unit_price"] =
                          (item["ret_default_unit_price"] as num).toDouble();
                      rowData["employee_id"] = lastReferrerID;

                      rowData["barcode"] = item["ret_product_qrcode"];
                      rowData["item"] = item["ret_product_name"];
                      rowData["unit"] = item["ret_uom_name"];
                      rowData["referral"] = lastReferrerName;
                      rowData["qty"] = item["ret_qty"] != null
                          ? rowData["qty"] += 1
                          : 1.toString();

                      final responseXY = await Http.getData(
                        endpoint: "pos.add_detail_cart",
                        data: rowData,
                      );

                      if (responseXY != null && responseXY["success"]) {
                        _displayData(rowData);
                        rowData["sales_transaction_detail_id"] =
                            responseXY["data"]["sales_transaction_detail_id"];
                        setState(() {});
                        return true;
                      }

                      return true;
                    }
                  }
                  return false;
                },
              ),
            );
            columns.add(
              DataGridColumn(
                field: "item",
                header: "Item",
                readOnly: true,
              ),
            );
            if (widget.template == 1 || widget.template == 2) {
              columns.add(
                DataGridColumn(
                  field: "referral",
                  header: labelReferral,
                  autoFocusable: lastReferrerName != null ? false : true,
                  suffix: SizedBox(
                    width: 24.0,
                    height: 14.0,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      padding: const EdgeInsets.all(0.0),
                      iconSize: 18.0,
                      onPressed: () {
                        var rowData =
                            _gridViewKey.currentState.getSelectedRowData();
                        if (rowData != null) {
                          setState(() async {
                            rowData["employee_id"] = null;
                            rowData["referral"] = null;

                            final response = await Http.getData(
                              endpoint: "pos.add_detail_cart",
                              data: rowData,
                            );
                            if (response != null && response["success"]) {
                              _displayData(rowData);
                              rowData["sales_transaction_detail_id"] =
                                  response["data"]
                                      ["sales_transaction_detail_id"];
                            }
                            setState(() {});
                          });
                        }
                      },
                    ),
                  ),
                  onSubmitted: (state, text, rowData) async {
                    if (_isEnabledReferral) {
                      setState(() {
                        _isEnabledReferral = false;
                      });
                      final List response = await _findReferrer(text);

                      if (response.isEmpty) {
                        setState(() {
                          _isEnabledReferral = true;
                        });
                        return false;
                      }

                      var item;
                      if (response.length == 1) {
                        item = response.elementAt(0);
                      } else {
                        item = await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => WillPopScope(
                            onWillPop: () async {
                              return _isEnabledReferral = true;
                            },
                            child: Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Material(
                                type: MaterialType.card,
                                borderRadius: BorderRadius.circular(8.0),
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Text(
                                        "Choose Referral",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline,
                                      ),
                                      SizedBox(
                                        height: 16.0,
                                      ),
                                      Expanded(
                                        child: ReferrarSelectionDialog(
                                          list: response,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 8.0,
                                      ),
                                      Container(
                                        height: 1.0,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          FlatButton(
                                            child: Text("CANCEL"),
                                            onPressed: () {
                                              _isEnabledReferral = true;
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      if (item != null) {
                        setState(() {
                          _isEnabledReferral = true;
                        });
                        rowData["employee_id"] = item["employee_id"];

                        rowData["referral"] = item["employee_name"];
                        lastReferrerName = item["employee_name"];
                        lastReferrerID = item["employee_id"];
                        final response = await Http.getData(
                          endpoint: "pos.add_detail_cart",
                          data: rowData,
                        );

                        if (response != null && response["success"]) {
                          _displayData(rowData);
                          rowData["sales_transaction_detail_id"] =
                              response["data"]["sales_transaction_detail_id"];
                          setState(() {});
                        }
                        return true;
                      }
                    }
                    return false;
                  },
                ),
              );
            }
            columns.add(
              DataGridColumn(
                field: "qty",
                header: "Qty",
                width: 80,
                autoFocusable: !useAutoIncrement,
                // readOnly: true,
                textAlign: TextAlign.center,
                inputFormaters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (state, value, rowData) async {
                  final response = await Http.getData(
                    endpoint: "pos.add_detail_cart",
                    data: rowData,
                  );

                  if (response != null && response["success"]) {
                    _displayData(rowData);
                    rowData["sales_transaction_detail_id"] =
                        response["data"]["sales_transaction_detail_id"];
                    setState(() {});
                    return true;
                  } else {
                    await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text(
                                'Information!',
                                style: Theme.of(context)
                                    .textTheme
                                    .title
                                    .copyWith(color: Colors.blueAccent),
                              ),
                              content: Text(response["data"],
                                  style: Theme.of(context)
                                      .textTheme
                                      .subhead
                                      .copyWith(color: Colors.black)),
                              actions: <Widget>[
                                FlatButton(
                                  child: new Text(
                                    "Close",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ));
                    _refreshTransaction();
                  }

                  return false;
                },
              ),
            );
            columns.add(
              DataGridColumn(
                field: "unit",
                header: "Unit",
                width: 100,
                readOnly: true,
                textAlign: TextAlign.center,
              ),
            );
            columns.add(
              DataGridColumn(
                field: "unit_price",
                header: "Price",
                width: 150,
                readOnly: true,
                columnType: DataGridColumnType.numberDouble,
                displayFormat: "#,##0",
                textAlign: TextAlign.right,
                prefix: Text(
                  "Rp.",
                  style: Theme.of(context).textTheme.caption,
                ),
                style: Theme.of(context).textTheme.body2.copyWith(
                      fontFamily: "Rubik",
                    ),
              ),
            );
            columns.add(
              DataGridColumn(
                field: "total",
                header: "Total",
                readOnly: true,
                width: 200,
                textAlign: TextAlign.right,
                displayFormat: "#,##0",
                columnType: DataGridColumnType.numberDouble,
                prefix: Text(
                  "Rp.",
                  style: Theme.of(context).textTheme.caption,
                ),
                style: Theme.of(context).textTheme.body2.copyWith(
                      fontFamily: "Rubik",
                    ),
                onGetValue: (index) {
                  var rowData = widget.transaction["items"][index];

                  double price = rowData["unit_price"] ?? 0.0;
                  int qty = rowData["qty"] != null
                      ? int.tryParse(rowData["qty"]) ?? 0
                      : 0;
                  return price * qty;
                },
              ),
            );

            columns.add(DataGridColumn(
                field: "",
                header: "Action",
                readOnly: true,
                width: 130,
                builder: (context, row, column, rowData) {
                  if (rowData == null ||
                      rowData["sales_transaction_detail_id"] == null) {
                    return Container();
                  }

                  return SizedBox(
                    width: 120,
                    child: FlatButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text("Remove"),
                      onPressed: () {
                        if (rowData != null &&
                            rowData["sales_transaction_detail_id"] != null) {
                          _removeItem(rowData);
                        }
                      },
                    ),
                  );
                }));

            return DataGridView(
              key: _gridViewKey,
              dataSource: widget.transaction["items"],
              hightlightBackgroundColor: Colors.blue.shade100,
              header: Container(
                height: 80,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                child: Table(
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  columnWidths: {
                                    0: FixedColumnWidth(50),
                                    1: FixedColumnWidth(5),
                                  },
                                  children: <TableRow>[
                                    TableRow(
                                      children: <Widget>[
                                        Text("Trx"),
                                        Text(":"),
                                        Text(
                                          widget.transaction[
                                              "transaction_number"],
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: <Widget>[
                                        Text("Shift"),
                                        Text(":"),
                                        Text(
                                          shiftNumber ?? shiftID,
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: <Widget>[
                                        Text("Date"),
                                        Text(":"),
                                        Text(
                                          formatDate.format(shiftDate) ?? "-",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            Visibility(
                              visible: visibleReferrerHeader,
                              child: Container(
                                width: 300,
                                child: Table(
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  columnWidths: {
                                    0: FixedColumnWidth(80),
                                    1: FixedColumnWidth(5),
                                    2: FixedColumnWidth(5),
                                  },
                                  children: <TableRow>[
                                    TableRow(
                                      children: <Widget>[
                                        Text("Referrer"),
                                        Text(":"),
                                        Text(" "),
                                        OutlineButton(
                                          child: widget.transaction[
                                                      "referral_name"] !=
                                                  null
                                              ? Text(
                                                  widget.transaction[
                                                      "referral_name"],
                                                  maxLines: 1,
                                                )
                                              : Text(
                                                  "SELECT",
                                                  maxLines: 1,
                                                ),
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                          onPressed: () async {
                                            if (_isEnabledReferral) {
                                              _selectReferral();
                                              _isEnabledReferral = false;
                                            }
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            Container(
                              // child: Text(
                              //   "totalQty",
                              // ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        "Items:",
                                      ),
                                      SizedBox(
                                        width: 4.0,
                                      ),
                                      Text(
                                        "${NumberFormat("#,##0").format(qtytotal)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .display1
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .title
                                                  .color,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 53,
                                              fontFamily: "Rubik",
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            Container(
                              width: 300,
                              child: Table(
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: {
                                  0: FixedColumnWidth(80),
                                  1: FixedColumnWidth(5),
                                  2: FixedColumnWidth(5),
                                },
                                children: <TableRow>[
                                  TableRow(
                                    children: <Widget>[
                                      Text("Customer"),
                                      Text(":"),
                                      Text(" "),
                                      OutlineButton(
                                        child: widget.transaction[
                                                    "customer_name"] !=
                                                null
                                            ? Text(widget
                                                .transaction["customer_name"])
                                            : Text("SELECT"),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                        onPressed: () async {
                                          if (_isEnabledButton) {
                                            _selectCustomer();
                                            _isEnabledButton = false;
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                ],
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
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.all(20.0),
                              child: FlatButton.icon(
                                icon: Icon(Icons.help_outline),
                                label: Text("Help (F7)"),
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) =>
                                        ShortcutDialogTransaction()),
                              ),
                            ),
                          ],
                        )),
                        Expanded(
                          child: Container(
                              height: 100.0,
                              width: 100.0,
                              padding: const EdgeInsets.all(10.0),
                              child: Marquee(
                                text: currentPromos ?? "Tidak ada promo!",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                blankSpace: 20.0,
                                pauseAfterRound: Duration(seconds: 2),
                                accelerationCurve: Curves.linear,
                                decelerationDuration:
                                    Duration(milliseconds: 500),
                                decelerationCurve: Curves.easeOut,
                              )),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.only(
                                  right: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "GRAND TOTAL",
                                      style: Theme.of(context).textTheme.title,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          "Rp.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle,
                                        ),
                                        SizedBox(
                                          width: 4.0,
                                        ),
                                        Text(
                                          "${NumberFormat("#,##0").format(grandtotal)}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .display1
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .title
                                                    .color,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: "Rubik",
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
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
          }),
        ),
      ),
    );
  }

  _selectReferral() async {
    final List response = await _findReferrer("");
    if (response.isEmpty) {
      setState(() {
        _isEnabledReferral = true;
      });
      return false;
    }
    var item;
    if (response.length == 1) {
      item = response.elementAt(0);
    } else {
      item = await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) => WillPopScope(
          onWillPop: () async {
            return _isEnabledReferral = true;
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Material(
              type: MaterialType.card,
              borderRadius: BorderRadius.circular(8.0),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Choose Referrer",
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Expanded(
                        child: new ReferrarSelectionDialog(
                      list: response,
                    )),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      height: 1.0,
                      color: Theme.of(context).dividerColor,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FlatButton(
                          child: Text("CANCEL"),
                          onPressed: () {
                            _isEnabledReferral = true;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (item != null) {
        _setReferralHeader(item);
        setState(() {
          _isEnabledReferral = true;
        });
        return true;
      }
    }
    return false;
  }

  _selectCustomer() async {
    final List response = await _findCustomer("");
    if (response.isEmpty) {
      setState(() {
        _isEnabledButton = true;
      });
      return false;
    }
    var item;
    if (response.length == 1) {
      item = response.elementAt(0);
    } else {
      item = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => WillPopScope(
          onWillPop: () async {
            return _isEnabledButton = true;
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Material(
              type: MaterialType.card,
              borderRadius: BorderRadius.circular(8.0),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      "Choose Customer",
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Expanded(
                        child: CustomerSelectionDialog(
                      list: response,
                    )),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      height: 1.0,
                      color: Theme.of(context).dividerColor,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FlatButton(
                          child: Text("CANCEL"),
                          onPressed: () {
                            _isEnabledButton = true;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (item != null) {
        _setCustomer(item);
        setState(() {
          _isEnabledButton = true;
        });
        return true;
      }
    }
    return false;
  }

  activate() {
    _gridViewKey.currentState.reFocus();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/bloc/shift.dart';
import 'package:pos_desktop/widgets/data_grid_view.dart';

class CheapRedeemPage extends StatefulWidget {
  final dynamic transaction;
  CheapRedeemPage({Key key, this.transaction}) : super(key: UniqueKey());
  @override
  _CheapRedeemPageState createState() => _CheapRedeemPageState();
}

class _CheapRedeemPageState extends State<CheapRedeemPage> {
  final FocusNode _keyboardListenerFn = FocusNode();
  final GlobalKey<DataGridViewState> _gridViewPromoKey = GlobalKey();
  final formatDate = DateFormat("EEEE, d MMMM yyyy");

  _updateData(String promoCode) async {
    List<Map<String, dynamic>> items = [];
    var responseF = widget.transaction;
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
            rowData["promo_code"] = promoCode;
            items.add(rowData);
          });
        }
      }
      items.add({});
      setState(() {
        widget.transaction["items"] = items;
        _gridViewPromoKey.currentState.reFocus();
      });
    });
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
                  field: "promo_code",
                  header: "Promo Code",
                  textAlign: TextAlign.center,
                  onSubmitted: (state, text, rowData) async {
                    setState(() {
                      _updateData(text);
                    });
                    return true;
                  }));

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
                  textAlign: TextAlign.center));

              columns.add(DataGridColumn(
                field: "item",
                header: "Item",
                readOnly: true,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                field: "qty",
                header: "Qty",
                width: 100,
                readOnly: true,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                field: "unit",
                header: "Unit",
                width: 100,
                readOnly: true,
                textAlign: TextAlign.center,
              ));

              columns.add(DataGridColumn(
                field: "unit_price",
                header: "Price",
                width: 150,
                readOnly: true,
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
              ));

              columns.add(DataGridColumn(
                field: "total",
                header: "Total",
                readOnly: true,
                textAlign: TextAlign.right,
                displayFormat: "#,##0",
                width: 200,
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
              ));

              return DataGridView(
                key: _gridViewPromoKey,
                hightlightBackgroundColor: Colors.blue.shade100,
                dataSource: widget.transaction["items"],
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
                              Container(
                                width: 300,
                                child: Table(
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  columnWidths: {
                                    0: FixedColumnWidth(50),
                                  },
                                  children: <TableRow>[
                                    TableRow(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.only(
                                            right: 16.0,
                                            bottom: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Text(
                                                "GRAND TOTAL",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .title,
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
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .title
                                                                  .color,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontFamily: "Rubik",
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                                      print(widget.transaction);
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
}

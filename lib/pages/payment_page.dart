import 'dart:convert';

import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import 'package:pos_desktop/dialogs/shortcut_payment_dialog.dart';
import 'package:pos_desktop/pages/payments/other_expense.dart';
import 'package:pos_desktop/pages/payments/voucher.dart';
import 'package:pos_desktop/pages/print_page.dart';
import 'package:pos_desktop/plugins/display.dart';
import 'package:pos_desktop/plugins/printers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'payments/non_cash.dart';

class PaymentPage extends StatefulWidget {
  final dynamic payment;
  final String transactionId;
  PaymentPage({@required this.payment, this.transactionId});
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _txtSubTotal = TextEditingController();
  TextEditingController _txtOtherExpenses = TextEditingController();
  TextEditingController _txtCash = TextEditingController();
  TextEditingController _txtNonCash = TextEditingController();
  TextEditingController _txtVoucher = TextEditingController();
  TextEditingController _txtDonation = TextEditingController();
  TextEditingController _txtPaymentRefund = TextEditingController();
  TextEditingController _txtWidthPrint = TextEditingController();
  FocusNode _fnKeyboard = FocusNode();
  FocusNode _fnDonation = FocusNode();
  FocusNode _fnCash = FocusNode();
  double change;
  double grandTotalPayment = 0;
  var widthPrint;
  bool _isEnabledButton = true;
  var vouchersData;
  bool _enableClose = true;

  @override
  void initState() {
    _setValueMultiInput();
    _getWidthPrint();
    _setValue();
    _grandTotal();
    super.initState();
  }

  @override
  void dispose() {
    _txtSubTotal.dispose();
    _txtOtherExpenses.dispose();
    _txtCash.dispose();
    _txtNonCash.dispose();
    _txtVoucher.dispose();
    _txtDonation.dispose();
    _txtPaymentRefund.dispose();
    _txtWidthPrint.dispose();
    _fnDonation.dispose();
    _fnCash.dispose();
    _fnKeyboard.dispose();
    super.dispose();
  }

  _setValueMultiInput() async {
    // OTHEREXPENSES SETVALUE
    double totalOtherExpenses = 0;
    final otherExpensesData =
        await Http.getData(endpoint: "pos.get_other_expenses", data: {
      "sales_transaction_id": widget.transactionId,
    });
    if (otherExpensesData != null && otherExpensesData["success"]) {
      setState(() {
        var list = otherExpensesData["data"]["other_expenses"];
        list.forEach((item) {
          totalOtherExpenses += item["ret_other_expense_amount"];
        });
        _txtOtherExpenses.text =
            NumberFormat("#,##0").format(totalOtherExpenses ?? 0).toString();
        _grandTotal();
      });
    }

    // NONCASH SETVALUE
    double totalNonCash = 0;
    final nonCashData =
        await Http.getData(endpoint: "pos.get_non_cash_payment", data: {
      "sales_transaction_id": widget.transactionId,
    });

    if (nonCashData != null && nonCashData["success"]) {
      setState(() {
        var list = nonCashData["data"]["non_cash_payments"];
        list.forEach((item) {
          totalNonCash += item["ret_non_cash_payment_amount"];
        });
        _txtNonCash.text =
            NumberFormat("#,##0").format(totalNonCash ?? 0).toString();
        if (totalNonCash != 0) {
          _change();
        }
      });
    }

    //VOUCHER SETVALUE
    double totalVoucher = 0;
    final voucherData = await Http.getData(
        endpoint: "pos.get_vouchers",
        data: {"sales_transaction_id": widget.transactionId});

    if (voucherData != null && voucherData["success"]) {
      setState(() {
        var list = voucherData["data"]["vouchers"];
        list.forEach((item) {
          totalVoucher += item["ret_voucher_amount"];
        });
        _txtVoucher.text =
            NumberFormat("#,##0").format(totalVoucher ?? 0).toString();
        if (totalVoucher != 0) {
          _change();
        }
      });
    }
    CustomerDisplay.print(
        "GRAND TOTAL:\r\nRP ${NumberFormat("#,##0").format(grandTotalPayment)}");
  }

  _setValue() {
    _txtSubTotal.text = NumberFormat("#,##0")
        .format(widget.payment["data"]["amount_total"])
        .toString();
    _txtOtherExpenses.text = NumberFormat("#,##0").format(0).toString();

    _txtCash.text = NumberFormat("#,##0").format(0).toString();
    _txtNonCash.text = NumberFormat("#,##0").format(0).toString();
    _txtVoucher.text = NumberFormat("#,##0").format(0).toString();
    _txtDonation.text = NumberFormat("#,##0").format(0).toString();
    _txtPaymentRefund.text = NumberFormat("#,##0").format(0).toString();
  }

  _change() {
    if (_formKey.currentState.validate()) {
      double cash = double.parse(_txtCash.text.replaceAll(",", ""));
      double nonCash = double.parse(_txtNonCash.text.replaceAll(",", ""));
      double voucher = double.parse(_txtVoucher.text.replaceAll(",", ""));
      double donation = double.parse(_txtDonation.text.replaceAll(",", ""));
      if (grandTotalPayment != null) {
        CustomerDisplay.print(
            "GRAND TOTAL:\r\nRP ${NumberFormat("#,##0").format(grandTotalPayment)}");
        setState(() {
          double selisihVoucher = voucher - grandTotalPayment;
          if (selisihVoucher < 0) {
            change = (cash + nonCash - donation) + selisihVoucher;
          } else {
            selisihVoucher = 0;
            change = ((cash + nonCash) - donation) - selisihVoucher;
          }

          _txtPaymentRefund.text = NumberFormat("#,##0").format(change);
        });
      }
    }
  }

  _grandTotal() {
    var subTotal = _txtSubTotal.text.replaceAll(",", "");
    var otherExpenses = _txtOtherExpenses.text.replaceAll(",", "");
    double grandTotal;
    setState(() {
      grandTotal = double.parse(subTotal) + double.parse(otherExpenses ?? 0);
      grandTotalPayment = grandTotal;
    });
  }

  _getWidthPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String conf = prefs.getString("printWidth");

    if (conf != null) {
      Map<String, dynamic> configJson = json.decode(conf);
      setState(() {
        widthPrint = configJson["width_print"];
      });
    } else {
      widthPrint = 32;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _fnKeyboard,
      onKey: (key) {
        if (!(key is RawKeyUpEvent)) {
          return;
        }

        if (key.logicalKey == LogicalKeyboardKey.f8) {
          _showShortcutInformation();
          return;
        }

        if (key.logicalKey == LogicalKeyboardKey.f9) {
          _dialogOtherExpenses();
          return;
        }

        if (key.logicalKey == LogicalKeyboardKey.f10) {
          _dialogNonCash();
          return;
        }

        if (key.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (_fnCash.hasFocus) {
            _cashKeyDown();
            return;
          }

          if (_fnDonation.hasFocus) {
            _donationEnterKeyDown();
            return;
          }
        }

        if (key.logicalKey == LogicalKeyboardKey.f11) {
          _dialogVoucher();
          return;
        }

        if (key.isControlPressed &&
            key.logicalKey == LogicalKeyboardKey.arrowDown) {
          FocusScope.of(context).requestFocus(_fnDonation);
          return;
        }

        if (key.isControlPressed &&
            key.logicalKey == LogicalKeyboardKey.arrowUp) {
          FocusScope.of(context).requestFocus(_fnCash);
          return;
        }

        if (_fnKeyboard.hasFocus &&
            key.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            _enableClose = true;
          });
        }
      },
      child: Scaffold(
        body: WillPopScope(
          onWillPop: () => _closePayment(),
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Material(
              type: MaterialType.card,
              borderRadius: BorderRadius.circular(8.0),
              clipBehavior: Clip.antiAlias,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Row(
                    children: <Widget>[
                      Container(
                        color: Theme.of(context).accentColor,
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(
                                  bottom: 20.0,
                                  left: 10.0,
                                  right: 10.0,
                                  top: 20.0),
                              width: MediaQuery.of(context).size.width,
                              child: FlatButton.icon(
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "CLOSE",
                                    style: Theme.of(context)
                                        .textTheme
                                        .body1
                                        .copyWith(color: Colors.white),
                                  ),
                                  onPressed: () => Navigator.of(context).pop()),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            bottom: 20.0, left: 15.0, right: 15.0, top: 25.0),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "Payment",
                                    style: Theme.of(context)
                                        .textTheme
                                        .display1
                                        .copyWith(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Theme.of(context).accentColor),
                                  ),
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Container(
                                      child: FlatButton.icon(
                                        icon: Icon(Icons.help_outline),
                                        label: Text("Help (F8)"),
                                        onPressed: () {
                                          _showShortcutInformation();
                                        },
                                      ),
                                    ),
                                  ],
                                ))
                              ],
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Container(
                              height: 1.0,
                              color: Theme.of(context).dividerColor,
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Container(
                              width: 300,
                              child: Table(
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: {
                                  0: FixedColumnWidth(80),
                                  1: FixedColumnWidth(5),
                                  2: FixedColumnWidth(5)
                                },
                                children: <TableRow>[
                                  TableRow(
                                    children: <Widget>[
                                      Text("Customer",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subhead),
                                      Text(":",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subhead),
                                      Text(" "),
                                      Center(
                                          child: Text(
                                              widget.payment["data"]
                                                          ["customer_name"] !=
                                                      null
                                                  ? widget.payment["data"]
                                                      ["customer_name"]
                                                  : "-",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subhead))
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    //SUB TOTAL
                                    Container(
                                      padding: EdgeInsets.all(5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "Sub Total",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subhead,
                                                ),
                                                SizedBox(
                                                  height: 3.0,
                                                ),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.3,
                                                  child: TextFormField(
                                                    controller: _txtSubTotal,
                                                    readOnly: true,
                                                    textAlign: TextAlign.right,
                                                    decoration: InputDecoration(
                                                        prefixText: "Rp. ",
                                                        contentPadding:
                                                            EdgeInsets.all(
                                                                12.0),
                                                        border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        1.0))),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                          )
                                        ],
                                      ),
                                    ),
                                    //OTHER EXPENSES
                                    Container(
                                      padding: EdgeInsets.all(5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "Other Expenses",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subhead,
                                                ),
                                                SizedBox(
                                                  height: 3.0,
                                                ),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.3,
                                                  child: TextFormField(
                                                    readOnly: true,
                                                    controller:
                                                        _txtOtherExpenses,
                                                    textAlign: TextAlign.right,
                                                    decoration: InputDecoration(
                                                        prefixText: "Rp. ",
                                                        contentPadding:
                                                            EdgeInsets.all(
                                                                12.0),
                                                        border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        1.0))),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () async {
                                                _dialogOtherExpenses();
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    //GRAND TOTAL
                                    Container(
                                      padding: EdgeInsets.all(5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "Grand Total",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .title,
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    Text(
                                                      "Rp.",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .title,
                                                    ),
                                                    SizedBox(
                                                      width: 4.0,
                                                    ),
                                                    Text(
                                                      "${NumberFormat("#,##0").format(grandTotalPayment)}",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline
                                                          .copyWith(
                                                            color: Theme.of(
                                                                    context)
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
                                          Container(
                                            width: 50,
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                                Expanded(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        //CASH PAYMENT
                                        Container(
                                          padding: EdgeInsets.all(5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      "Cash",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subhead,
                                                    ),
                                                    SizedBox(
                                                      height: 3.0,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: TextFormField(
                                                        autofocus: true,
                                                        controller: _txtCash,
                                                        focusNode: _fnCash,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration: InputDecoration(
                                                            prefixText: "Rp. ",
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            1.0))),
                                                        inputFormatters: <
                                                            TextInputFormatter>[
                                                          BlacklistingTextInputFormatter(
                                                              RegExp(
                                                                  "[a-zA-Z]")),
                                                          ThousandsFormatter()
                                                        ],
                                                        validator: (text) {
                                                          if (text.isEmpty) {
                                                            return "cannot be empty";
                                                          }
                                                          return null;
                                                        },
                                                        onEditingComplete: () {
                                                          _cashKeyDown();
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                              )
                                            ],
                                          ),
                                        ),
                                        //NON CASH
                                        Container(
                                          padding: EdgeInsets.all(5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      "Non Cash",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subhead,
                                                    ),
                                                    SizedBox(
                                                      height: 3.0,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: TextFormField(
                                                        readOnly: true,
                                                        controller: _txtNonCash,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration: InputDecoration(
                                                            prefixText: "Rp. ",
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            1.0))),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.add_circle,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    _dialogNonCash();
                                                  },
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        //VOUCHER PAYMENT
                                        Container(
                                          padding: EdgeInsets.all(5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      "Voucher",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subhead,
                                                    ),
                                                    SizedBox(
                                                      height: 3.0,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: TextFormField(
                                                        readOnly: true,
                                                        controller: _txtVoucher,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration: InputDecoration(
                                                            prefixText: "Rp. ",
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            1.0))),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.add_circle,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    _dialogVoucher();
                                                  },
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        //DONATION PAYMENT
                                        Container(
                                          padding: EdgeInsets.all(5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      "Donation",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subhead,
                                                    ),
                                                    SizedBox(
                                                      height: 3.0,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: TextFormField(
                                                        controller:
                                                            _txtDonation,
                                                        focusNode: _fnDonation,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration: InputDecoration(
                                                            prefixText: "Rp. ",
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            1.0))),
                                                        inputFormatters: <
                                                            TextInputFormatter>[
                                                          BlacklistingTextInputFormatter(
                                                              RegExp(
                                                                  "[a-zA-Z]")),
                                                          ThousandsFormatter()
                                                        ],
                                                        onFieldSubmitted:
                                                            (text) {
                                                          _donationEnterKeyDown();
                                                          FocusScope.of(context)
                                                              .unfocus();
                                                        },
                                                        validator: (text) {
                                                          if (text.isEmpty) {
                                                            return "cannot be empty";
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                              )
                                            ],
                                          ),
                                        ),
                                        //CHANGE PAYMENT
                                        Container(
                                          padding: EdgeInsets.all(5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      "Change",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subhead
                                                          .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                    SizedBox(
                                                      height: 3.0,
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.3,
                                                      child: TextFormField(
                                                        controller:
                                                            _txtPaymentRefund,
                                                        readOnly: true,
                                                        textAlign:
                                                            TextAlign.right,
                                                        decoration: InputDecoration(
                                                            prefixText: "Rp. ",
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            1.0))),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 50,
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                // Container(
                                //   margin: EdgeInsets.all(5.0),
                                //   width:
                                //       MediaQuery.of(context).size.width * 0.1,
                                //   height:
                                //       MediaQuery.of(context).size.height * 0.05,
                                //   child: OutlineButton.icon(
                                //     borderSide: BorderSide(
                                //         color: Colors.blue, width: 2),
                                //     highlightedBorderColor: Colors.blue,
                                //     icon: Icon(
                                //       Icons.payment,
                                //       color: Colors.blue,
                                //     ),
                                //     label: Text("Print Draft",
                                //         style: TextStyle(color: Colors.blue)),
                                //     onPressed: () {
                                //       CustomerDisplay.print(
                                //           "CHANGE :\r\nRP ${NumberFormat("#,##0").format(change)}");
                                //       // if (change > -1 && _isEnabledButton) {
                                //       //   _payment();
                                //       //   _isEnabledButton = false;
                                //       // }
                                //     },
                                //   ),
                                // ),
                                Container(
                                  margin: EdgeInsets.all(5.0),
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                  child: OutlineButton.icon(
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2),
                                    highlightedBorderColor: Colors.green,
                                    icon: Icon(
                                      Icons.payment,
                                      color: Colors.green,
                                    ),
                                    label: Text("PAY",
                                        style: TextStyle(color: Colors.green)),
                                    onPressed: () {
                                      CustomerDisplay.print(
                                          "CHANGE :\r\nRP ${NumberFormat("#,##0").format(change)}");
                                      if (change > -1 && _isEnabledButton) {
                                        _payment();
                                        _isEnabledButton = false;
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  width: 50,
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }

  _dialogOtherExpenses() async {
    var otherExpenses = await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) => OtherExpenses(
              transactionId: widget.transactionId,
            ));

    if (otherExpenses != null) {
      setState(() {
        _enableClose = false;
        _txtOtherExpenses.text =
            NumberFormat("#,##0").format(otherExpenses ?? 0);
        FocusScope.of(context).requestFocus(_fnCash);
        _grandTotal();
        _change();
      });
    }
  }

  _dialogNonCash() async {
    var nonCashDialog = await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) => NonCash(
              transactionId: widget.transactionId,
              grandTotal: grandTotalPayment.toString(),
            ));

    if (nonCashDialog != null) {
      setState(() {
        _enableClose = false;
        _txtNonCash.text = NumberFormat("#,##0").format(nonCashDialog);
        FocusScope.of(context).requestFocus(_fnCash);
        _change();
      });
    }
  }

  _dialogVoucher() async {
    var voucherDialog = await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) => Voucher(
              transactionId: widget.transactionId,
              grandTotal: grandTotalPayment.toString(),
            ));

    if (voucherDialog != null) {
      setState(() {
        _enableClose = false;
        _txtVoucher.text =
            NumberFormat("#,##0").format(voucherDialog["total_voucher"]);
        FocusScope.of(context).requestFocus(_fnCash);
        _change();
        vouchersData = voucherDialog["vouchers"];
      });
    }
  }

  _updateVoucherIsUsed(List<dynamic> vouchers) async {
    List<Map<String, dynamic>> voucherReq = List();
    vouchers?.forEach((voucher) {
      Map<String, dynamic> v = voucher;
      Map<String, dynamic> toRequest = {
        "voucher_code": v["ret_voucher_code"] ?? ""
      };
      voucherReq.add(toRequest);
    });

    final response = await Http.getData(
        endpoint: "pusat/pos.update_is_used_voucher",
        data: {
          "customer_name": widget.payment["customer_name"],
          "vouchers": voucherReq
        });
    print(response);
  }

  _payment() async {
    var cashX = _txtCash.text.replaceAll(",", "");
    var donationX = _txtDonation.text.replaceAll(",", "");
    final response = await Http.getData(endpoint: "pos.submit_cart", data: {
      "sales_transaction_id": widget.transactionId,
      "payment_amount_cash": double.parse(cashX),
      "donation_amount": double.parse(donationX),
      "change_amount": change
    });

    if (response != null && response["success"]) {
      final responseX = await Http.getData(endpoint: "print.get_print", data: {
        "sales_trx_id": widget.transactionId,
        "print_width": widthPrint ?? 32
      });
      if (responseX != null) {
        _payPrint(responseX["data"]);
        _updateVoucherIsUsed(vouchersData);
        var itemShow = await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => WillPopScope(
            onWillPop: () async {
              Navigator.pop(context, true);
              _isEnabledButton = true;
              return;
            },
            child: Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: PrintPage(
                  transactionId: widget.transactionId,
                  dataPrint: responseX["data"],
                )),
          ),
        );
        if (itemShow != null) {
          Navigator.pop(context, itemShow);
        }
        setState(() {
          _isEnabledButton = true;
        });
      }
    }
  }

  Future<bool> _closePayment() async {
    final response = await Http.getData(
        endpoint: "pos.rollback_cart",
        data: {"sales_transaction_id": widget.transactionId});
    if (response["data"] == "Batal checkout" && _enableClose) {
      return true;
    } else {
      return false;
    }
  }

  _payPrint(dynamic dataPrint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('settingsPrint')) {
      String conf = prefs.getString("settingsPrint");
      Map<String, dynamic> configJson = json.decode(conf);
      setState(() {
        PrinterDocument("Struk")
          ..addText(dataPrint["print"])
          ..addFeed()
          ..addFeed()
          ..addFeed()
          ..cutPaper()
          ..finish()
          ..print(configJson["print_name"]);
      });
    }
  }

  _settingPrinter() async {
    final printers = await Printer.getPrinters();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Material(
          type: MaterialType.card,
          borderRadius: BorderRadius.circular(8.0),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Printer Width",
                  style: Theme.of(context).textTheme.headline,
                ),
                SizedBox(
                  height: 8.0,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: TextFormField(
                          autovalidate: true,
                          controller: _txtWidthPrint,
                          validator: (text) {
                            if (text.isEmpty) {
                              return "Cannot be Empty";
                            }
                            if (double.parse(_txtWidthPrint.text) < 32) {
                              return "value must not be less than 32";
                            }
                            return null;
                          },
                          textAlign: TextAlign.center,
                          inputFormatters: <TextInputFormatter>[
                            BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                          ],
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(5.0),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0))),
                          onFieldSubmitted: (text) async {
                            final formState = _formKey.currentState;
                            if (formState.validate()) {
                              formState.save();
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              Map<String, dynamic> configJson = {
                                "width_print": _txtWidthPrint.text
                              };
                              String jsonEncode = json.encode(configJson);
                              await prefs.setString("printWidth", jsonEncode);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16.0,
                ),
                Text(
                  "Choose Printer",
                  style: Theme.of(context).textTheme.headline,
                ),
                SizedBox(
                  height: 8.0,
                ),
                Expanded(
                    child: new SettingPrinter(
                  list: printers,
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
                      child: Text("CLOSE"),
                      onPressed: () {
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
    );
  }

  void _donationEnterKeyDown() {
    _change();
    if (change > -1 && _isEnabledButton) {
      Future.delayed(Duration(milliseconds: 500), () {
        CustomerDisplay.print(
            "CHANGE :\r\nRP ${NumberFormat("#,##0").format(change)}");
      });
      _payment();
      _isEnabledButton = false;
    }
  }

  void _cashKeyDown() {
    _change();
    var cashX = _txtCash.text.replaceAll(",", "");
    if (double.parse(cashX) > -1) {
      FocusScope.of(context).requestFocus(_fnDonation);
    }
  }

  _showShortcutInformation() async {
    await showDialog(
        context: context, builder: (context) => ShortcutPaymentDialog());
    FocusScope.of(context).requestFocus(_fnCash);
  }
}

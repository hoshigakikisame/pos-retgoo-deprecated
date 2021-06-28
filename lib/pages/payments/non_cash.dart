import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:pos_desktop/widgets/close_button_control.dart';
import 'package:pos_desktop/widgets/form_tile_box.dart';

class NonCash extends StatefulWidget {
  final String transactionId;
  final String grandTotal;
  NonCash({@required this.transactionId, this.grandTotal});
  @override
  _NonCashState createState() => _NonCashState();
}

class _NonCashState extends State<NonCash> {
  TextEditingController _txtCardNumberEdc = TextEditingController();
  TextEditingController _txtTraceNumberEdc = TextEditingController();
  TextEditingController _txtAmountEdc = TextEditingController();
  TextEditingController _txtAdminPercent = TextEditingController();
  TextEditingController _txtAdminAmount = TextEditingController();
  TextEditingController _txtAmountEdcInput = TextEditingController();
  FocusNode _fnCardNumber = FocusNode();
  FocusNode _fnTraceNumber = FocusNode();
  FocusNode _fnAmountEdc = FocusNode();
  FocusNode _fnAdminPercent = FocusNode();
  FocusNode _fnAdminAmount = FocusNode();
  FocusNode _fnKeyboard = FocusNode();
  List dataEdc = List();
  var _myChoose;
  double total = 0;
  List list = [];

  @override
  void initState() {
    _getEdc();
    super.initState();
    _getNonCashPayment();
  }

  @override
  void dispose() {
    _txtAdminPercent.dispose();
    _txtAdminAmount.dispose();
    _txtCardNumberEdc.dispose();
    _txtAmountEdc.dispose();
    _txtTraceNumberEdc.dispose();
    _txtAmountEdcInput.dispose();
    _fnCardNumber.dispose();
    _fnTraceNumber.dispose();
    _fnAmountEdc.dispose();
    _fnAdminPercent.dispose();
    _fnAdminAmount.dispose();
    super.dispose();
  }

  _getEdc() async {
    final response = await Http.getData(endpoint: "pos.get_edc");
    if (response != null && response["success"]) {
      setState(() {
        dataEdc = response["data"]["edc"];
      });
    }
  }

  _getAdminAmount() {
    if (_txtAmountEdc.text.isNotEmpty && _txtAdminPercent.text.isNotEmpty) {
      setState(() {
        var amountEdcX = _txtAmountEdc.text.replaceAll(",", "");
        double totalnew = total + double.parse(amountEdcX);
        double percent = double.parse(_txtAdminPercent.text);
        num totalAmount = totalnew * (percent / 100);
        _txtAdminAmount.text = totalAmount.round().toString();
        double amountEDCInput = totalnew + totalAmount.round();
        _txtAmountEdcInput.text = amountEDCInput.toString();
      });
    }
  }

  _getNonCashPayment() async {
    final result =
        await Http.getData(endpoint: "pos.get_non_cash_payment", data: {
      "sales_transaction_id": widget.transactionId,
    });

    if (result != null && result["success"]) {
      setState(() {
        list = result["data"]["non_cash_payments"];
        list.forEach((item) {
          total += item["ret_non_cash_payment_amount"];
        });
      });
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

        if (key.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (_fnCardNumber.hasFocus) {
            FocusScope.of(context).requestFocus(_fnTraceNumber);
            return;
          }

          if (_fnTraceNumber.hasFocus) {
            FocusScope.of(context).requestFocus(_fnAmountEdc);
            return;
          }

          if (_fnAmountEdc.hasFocus) {
            String text;
            FocusScope.of(context).requestFocus(_fnAdminPercent);
            _amountKeyDown();
            return;
          }

          if (_fnAdminPercent.hasFocus) {
            _fnAdminPercent.unfocus();
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, total);
          return false;
        },
        child: Dialog(
          child: Container(
            margin: EdgeInsets.all(20.0),
            width: MediaQuery.of(context).size.height * 1.1,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(
                    "Non Cash",
                    style: Theme.of(context).textTheme.headline.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Theme.of(context).accentColor),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "EDC",
                    inputter: DropdownButtonFormField(
                      hint: Text(
                        "Choose EDC",
                      ),
                      items: dataEdc.map((items) {
                        return DropdownMenuItem(
                          child: Text(
                              items["edc_code"] + " " + items["card_type"]),
                          value: items,
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        setState(() {
                          _myChoose = newVal;
                          _txtAdminPercent.text =
                              _myChoose["admin_percent"].toString();
                          _txtAmountEdc.text =
                              (double.parse(widget.grandTotal) - total)
                                  .toString();
                          _getAdminAmount();
                          FocusScope.of(context).requestFocus(_fnCardNumber);
                        });
                      },
                      value: _myChoose,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Card Number",
                    inputter: TextFormField(
                      autofocus: true,
                      focusNode: _fnCardNumber,
                      controller: _txtCardNumberEdc,
                      decoration: InputDecoration(
                          hasFloatingPlaceholder: false,
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter(RegExp("[0-9]")),
                      ],
                      onEditingComplete: () {
                        FocusScope.of(context).requestFocus(_fnTraceNumber);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Amount",
                    inputter: TextFormField(
                      focusNode: _fnAmountEdc,
                      controller: _txtAmountEdc,
                      decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () => _getAdminAmount(),
                            icon: Icon(Icons.check_circle_outline),
                          ),
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      inputFormatters: <TextInputFormatter>[
                        BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        ThousandsFormatter()
                      ],
                      onEditingComplete: () {
                        FocusScope.of(context).requestFocus(_fnCardNumber);
                      },
                      onChanged: (value) {
                        _getAdminAmount();
                      },
                      onFieldSubmitted: (text) {
                        _amountKeyDown();
                        _getAdminAmount();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Admin Percent",
                    inputter: TextFormField(
                      focusNode: _fnAdminPercent,
                      readOnly: true,
                      controller: _txtAdminPercent,
                      decoration: InputDecoration(
                        suffixText: "%",
                        contentPadding: EdgeInsets.all(8.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Admin Amount",
                    inputter: TextFormField(
                      focusNode: _fnAdminAmount,
                      readOnly: true,
                      controller: _txtAdminAmount,
                      inputFormatters: <TextInputFormatter>[
                        BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        ThousandsFormatter()
                      ],
                      decoration: InputDecoration(
                        prefixText: "Rp.",
                        contentPadding: EdgeInsets.all(8.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Input EDC Amount",
                    inputter: TextFormField(
                      // focusNode: _fnAdminAmount,
                      readOnly: true,
                      controller: _txtAmountEdcInput,
                      inputFormatters: <TextInputFormatter>[
                        BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        // ThousandsFormatter()
                      ],
                      decoration: InputDecoration(
                        prefixText: "Rp.",
                        contentPadding: EdgeInsets.all(8.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  FormTileBox(
                    label: "Trace Number",
                    inputter: TextFormField(
                      focusNode: _fnTraceNumber,
                      controller: _txtTraceNumberEdc,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      onEditingComplete: () {
                        FocusScope.of(context).requestFocus(_fnAmountEdc);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Container(),
                      ),
                      OutlineButton.icon(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                        label: Text(
                          "Add",
                          style: Theme.of(context)
                              .textTheme
                              .button
                              .copyWith(color: Colors.green),
                        ),
                        borderSide: BorderSide(color: Colors.green),
                        highlightedBorderColor: Colors.green,
                        onPressed: () {
                          var amountEdcX =
                              _txtAmountEdc.text.replaceAll(",", "");
                          double totalnew = total + double.parse(amountEdcX);
                          if (double.parse(widget.grandTotal) <
                              double.parse(amountEdcX)) {
                            _alertDialogInformation(
                                "Withdrawal amount cannot exceed grand total");
                            return false;
                          }
                          if (double.parse(widget.grandTotal) < totalnew) {
                            _alertDialogInformation(
                                "Withdrawal amount cannot exceed grand total");
                            return false;
                          }
                          _submitData();
                          return true;
                        },
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      CloseButtonControl(
                        onPressed: () async {
                          Navigator.pop(context, total);
                        },
                      ),
                      SizedBox(
                        width: 5,
                      )
                    ],
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          height: 200,
                          decoration:
                              BoxDecoration(border: Border.all(width: 0.5)),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: ListView.builder(
                                  itemCount: list.length,
                                  itemBuilder: (context, position) {
                                    final item = list.elementAt(position);
                                    return Card(
                                      child: ListTile(
                                        title: Text(item["ret_edc"]),
                                        subtitle: Text("Rp. " +
                                            NumberFormat("#,##0")
                                                .format(item[
                                                    "ret_non_cash_payment_amount"])
                                                .toString()),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          onPressed: () {
                                            var item = list.elementAt(position);
                                            _removeData(item);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      )
                    ],
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Divider(
                    height: 1.0,
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            "GRAND TOTAL",
                            style: Theme.of(context).textTheme.subtitle,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                "Rp.",
                                style: Theme.of(context).textTheme.subtitle,
                              ),
                              SizedBox(
                                width: 4.0,
                              ),
                              Text(
                                "${NumberFormat("#,##0").format(double.parse(widget.grandTotal) ?? 0)}",
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            "TOTAL",
                            style: Theme.of(context).textTheme.subtitle,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                "Rp.",
                                style: Theme.of(context).textTheme.subtitle,
                              ),
                              SizedBox(
                                width: 4.0,
                              ),
                              Text(
                                "${NumberFormat("#,##0").format(total)}",
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
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _amountKeyDown() {
    var amountEdcX = _txtAmountEdc.text.replaceAll(",", "");
    double totalnew = total + double.parse(amountEdcX);
    if (double.parse(widget.grandTotal) < double.parse(amountEdcX)) {
      _alertDialogInformation("Amount no more than Grand Total");
      return false;
    }
    if (double.parse(widget.grandTotal) < totalnew) {
      _alertDialogInformation("Amount no more than Grand Total");
      return false;
    }
    _submitData();
    return true;
  }

  _alertDialogInformation(String content) async {
    await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              return true;
            },
            child: AlertDialog(
              title: Text(
                'Information!',
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: Colors.blueAccent),
              ),
              content: Text(content,
                  style: Theme.of(context)
                      .textTheme
                      .subhead
                      .copyWith(color: Colors.black)),
              actions: <Widget>[
                new FlatButton(
                  child: new Text(
                    "Close",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });

    FocusScope.of(context).requestFocus(_fnCardNumber);
  }

  _submitData() async {
    var amountEdc = _txtAmountEdc.text.replaceAll(",", "");
    var amountEdcInput = _txtAmountEdcInput.text.replaceAll(",", "");
    final resultY = await Http.getData(endpoint: "pos.add_edc", data: {
      "sales_transaction_id": widget.transactionId,
      "edc_id": _myChoose["edc_id"],
      "card_number": _txtCardNumberEdc.text,
      "trace_number": _txtTraceNumberEdc.text,
      "amount": amountEdc,
      "amount_edc_input": amountEdcInput
    });
    if (resultY != null && resultY["success"]) {
      final result =
          await Http.getData(endpoint: "pos.get_non_cash_payment", data: {
        "sales_transaction_id": widget.transactionId,
      });
      setState(() {
        if (result != null && result["success"]) {
          list = result["data"]["non_cash_payments"];
        }
        // total += double.parse(amountEdc);
        total += double.parse(amountEdcInput);
        _txtCardNumberEdc.text = "";
        _txtTraceNumberEdc.text = "";
        _myChoose = null;
        _txtAmountEdc.text = "";
        _txtAdminAmount.text = "";
        _txtAdminPercent.text = "";
        _txtAmountEdcInput.text = "";
      });
    }
  }

  _removeData(dynamic itemSelected) async {
    final resultX = await Http.getData(endpoint: "pos.remove_edc", data: {
      "sales_transaction_edc_id": itemSelected["ret_non_cash_payment_id"]
    });
    if (resultX != null && resultX["success"]) {
      final result =
          await Http.getData(endpoint: "pos.get_non_cash_payment", data: {
        "sales_transaction_id": widget.transactionId,
      });
      setState(() {
        if (result != null) {
          list = result["data"]["non_cash_payments"];
          total = total - itemSelected["ret_non_cash_payment_amount"];
        }
      });
    }
  }
}

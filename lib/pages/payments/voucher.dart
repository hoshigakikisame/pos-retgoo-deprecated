import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/widgets/close_button_control.dart';
import 'package:pos_desktop/widgets/form_tile_box.dart';

class Voucher extends StatefulWidget {
  final String transactionId;
  final String grandTotal;
  Voucher({@required this.transactionId, this.grandTotal});
  @override
  _VoucherState createState() => _VoucherState();
}

class _VoucherState extends State<Voucher> {
  TextEditingController _txtVoucherCode = TextEditingController();
  TextEditingController _txtVoucherAmount = TextEditingController();
  FocusNode _fnVoucherCode = FocusNode();
  FocusNode _fnVoucherAmount = FocusNode();
  FocusNode _fnKeyboard = FocusNode();
  double total = 0;
  List list = [];
  bool validatePosition = true;
  String nameButton = "Validate";
  dynamic dataCallback;

  @override
  void initState() {
    super.initState();
    _getDataVoucher();
  }

  @override
  void dispose() {
    _txtVoucherCode.dispose();
    _txtVoucherAmount.dispose();
    _fnVoucherCode.dispose();
    _fnVoucherAmount.dispose();
    super.dispose();
  }

  _getDataVoucher() async {
    final getDataVoucher = await Http.getData(
        endpoint: "pos.get_vouchers",
        data: {"sales_transaction_id": widget.transactionId});

    if (getDataVoucher != null && getDataVoucher["success"]) {
      setState(() {
        list = getDataVoucher["data"]["vouchers"];
        list.forEach((item) {
          total += item["ret_voucher_amount"];
        });
        _jsonEndcodeCallback();
      });
    }
  }

  _jsonEndcodeCallback() async {
    Map<String, dynamic> dataToJson = {
      "total_voucher": total,
      "vouchers": list,
    };
    setState(() {
      dataCallback = dataToJson;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _fnKeyboard,
      onKey: (key) {
        if (!(key is RawKeyUpEvent)) {
          return;
        }
        if(key.logicalKey == LogicalKeyboardKey.numpadEnter){
          if(_fnVoucherCode.hasFocus){
            _voucherCodeKeyDown();
            FocusScope.of(context).requestFocus(_fnVoucherAmount);
          }
          if(_fnVoucherAmount.hasFocus){
            _fnVoucherAmount.unfocus();
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, dataCallback);
          return false;
        },
        child: Dialog(
          child: Container(
            margin: EdgeInsets.all(20.0),
            width: MediaQuery.of(context).size.height * 0.9,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(
                    "Voucher",
                    style: Theme.of(context).textTheme.headline.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).accentColor),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  FormTileBox(
                    label: "Voucher Code",
                    inputter: TextFormField(
                      autofocus: true,
                      focusNode: _fnVoucherCode,
                      controller: _txtVoucherCode,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(12.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      onFieldSubmitted: (text) {
                        _voucherCodeKeyDown();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  FormTileBox(
                    label: "Voucher Amount",
                    inputter: TextFormField(
                      readOnly: true,
                      focusNode: _fnVoucherAmount,
                      controller: _txtVoucherAmount,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(12.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                    ),
                  ),
                  SizedBox(
                    height: 15.0,
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
                          nameButton,
                          style: Theme.of(context)
                              .textTheme
                              .button
                              .copyWith(color: Colors.green),
                        ),
                        borderSide: BorderSide(color: Colors.green),
                        highlightedBorderColor: Colors.green,
                        onPressed: () async {
                          if (validatePosition) {
                            _validateVoucher();
                            validatePosition = false;
                            nameButton = "Add";
                          } else {
                            _addVoucher();
                            validatePosition = true;
                            nameButton = "Validate";
                          }
                        },
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      CloseButtonControl(
                        onPressed: () async {
                          Navigator.pop(context, dataCallback);
                        },
                      ),
                      SizedBox(
                        width: 5,
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          height: 300,
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
                                        title: Text(item["ret_voucher_code"]),
                                        subtitle: Text("Rp. " +
                                            NumberFormat("#,##0")
                                                .format(
                                                    item["ret_voucher_amount"])
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
                    height: 10.0,
                  ),
                  Divider(
                    height: 1.0,
                  ),
                  SizedBox(
                    height: 10.0,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _voucherCodeKeyDown() {
    if (validatePosition) {
      _validateVoucher();
      validatePosition = false;
    } else {
      _addVoucher();
      FocusScope.of(context).requestFocus(_fnVoucherCode);
      validatePosition = true;
    }
  }

  _validateVoucher() async {
    final validateVoucher = await Http.getData(
        endpoint: "pusat/pos.validate_voucher",
        data: {"voucher_code": _txtVoucherCode.text});
    print(validateVoucher);
    if (validateVoucher != null && validateVoucher["success"]) {
      setState(() {
        _txtVoucherAmount.text = NumberFormat("#,##0")
            .format(validateVoucher["data"]["voucher_amount"])
            .toString();
      });

      _alertDialogInformation(
          validateVoucher["data"]["message"] ?? "Validate voucher success");
      return false;
    }
    if (validateVoucher != null && !validateVoucher["success"]) {
      _alertDialogInformation(
          validateVoucher["data"] ?? "The voucher is expired");
    }
    validatePosition = true;
  }

  _addVoucher() async {
    var voucherAmount = _txtVoucherAmount.text.replaceAll(",", "");
    final addVoucher = await Http.getData(endpoint: "pos.add_voucher", data: {
      "sales_transaction_id": widget.transactionId,
      "voucher_code": _txtVoucherCode.text,
      "voucher_amount": voucherAmount
    });

    if (addVoucher != null && addVoucher["success"]) {
      final getDataVoucher = await Http.getData(
          endpoint: "pos.get_vouchers",
          data: {"sales_transaction_id": widget.transactionId});

      if (getDataVoucher != null && getDataVoucher["success"]) {
        var amountVoucher = _txtVoucherAmount.text.replaceAll(",", "");
        setState(() {
          list = getDataVoucher["data"]["vouchers"];
          total += double.parse(amountVoucher);

          _jsonEndcodeCallback();
          _txtVoucherCode.text = "";
          _txtVoucherAmount.text = "";
        });
      }
    }
  }

  _removeData(dynamic itemSelected) async {
    final removeVoucher = await Http.getData(
        endpoint: "pos.remove_voucher",
        data: {
          "sales_transaction_voucher_id":
              itemSelected["ret_sales_transaction_voucher_id"]
        });

    if (removeVoucher != null && removeVoucher["success"]) {
      final result = await Http.getData(endpoint: "pos.get_vouchers", data: {
        "sales_transaction_id": widget.transactionId,
      });
      if (result != null) {
        setState(() {
          list = result["data"]["vouchers"];
          total -= itemSelected["ret_voucher_amount"];
          _jsonEndcodeCallback();
        });
      }
    }
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
    FocusScope.of(context).requestFocus(_fnVoucherCode);
  }
}

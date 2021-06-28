import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:pos_desktop/widgets/close_button_control.dart';
import 'package:pos_desktop/widgets/form_tile_box.dart';

class OtherExpenses extends StatefulWidget {
  final String transactionId;
  OtherExpenses({@required this.transactionId});
  @override
  _OtherExpensesState createState() => _OtherExpensesState();
}

class _OtherExpensesState extends State<OtherExpenses> {
  TextEditingController _txtOtherExpenseName = TextEditingController();
  TextEditingController _txtOtherExpenseAmount = TextEditingController();
  FocusNode _fnOtherExpenseName = FocusNode();
  FocusNode _fnOtherExpenseAmount = FocusNode();
  FocusNode _fnKeyboard = FocusNode();

  double total = 0;
  List list = [];

  @override
  void initState() {
    super.initState();
    _getOtherExpenses();
  }

  @override
  void dispose() {
    _txtOtherExpenseName.dispose();
    _txtOtherExpenseAmount.dispose();
    _fnOtherExpenseName.dispose();
    _fnOtherExpenseAmount.dispose();
    super.dispose();
  }

  _getOtherExpenses() async {
    final result =
        await Http.getData(endpoint: "pos.get_other_expenses", data: {
      "sales_transaction_id": widget.transactionId,
    });
    if (result != null) {
      setState(() {
        list = result["data"]["other_expenses"];
        list.forEach((item) {
          total += item["ret_other_expense_amount"];
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
          if (_fnOtherExpenseName.hasFocus) {
            FocusScope.of(context).requestFocus(_fnOtherExpenseAmount);
            return;
          }
          if (_fnOtherExpenseAmount.hasFocus) {
            FocusScope.of(context).requestFocus(_fnOtherExpenseName);
            _submitData();
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
            width: MediaQuery.of(context).size.height * 0.9,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(
                    "Other Expense",
                    style: Theme.of(context).textTheme.headline.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).accentColor),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  FormTileBox(
                    label: "Other Expense Name",
                    inputter: TextFormField(
                      autofocus: true,
                      focusNode: _fnOtherExpenseName,
                      controller: _txtOtherExpenseName,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      inputFormatters: <TextInputFormatter>[
                        BlacklistingTextInputFormatter(RegExp("[0-9]")),
                      ],
                      onEditingComplete: () {
                        FocusScope.of(context)
                            .requestFocus(_fnOtherExpenseAmount);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  FormTileBox(
                    label: "Other Expense Amount",
                    inputter: TextFormField(
                      autofocus: true,
                      focusNode: _fnOtherExpenseAmount,
                      controller: _txtOtherExpenseAmount,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1.0))),
                      inputFormatters: <TextInputFormatter>[
                        BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        ThousandsFormatter()
                      ],
                      onEditingComplete: () {
                        FocusScope.of(context)
                            .requestFocus(_fnOtherExpenseName);
                      },
                      onFieldSubmitted: (text) {
                        _submitData();
                      },
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
                          "Add",
                          style: Theme.of(context)
                              .textTheme
                              .button
                              .copyWith(color: Colors.green),
                        ),
                        borderSide: BorderSide(color: Colors.green),
                        highlightedBorderColor: Colors.green,
                        onPressed: () async {
                          _submitData();
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
                                        title: Text(
                                            item["ret_other_expense_name"]),
                                        subtitle: Text("Rp. " +
                                            NumberFormat("#,##0")
                                                .format(item[
                                                    "ret_other_expense_amount"])
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
                                  color:
                                      Theme.of(context).textTheme.title.color,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Rubik",
                                ),
                          ),
                        ],
                      )
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

  _submitData() async {
    var otherExpenseAmount = _txtOtherExpenseAmount.text.replaceAll(",", "");
    final response =
        await Http.getData(endpoint: "pos.add_other_expense", data: {
      "sales_transaction_id": widget.transactionId,
      "other_expense_name": _txtOtherExpenseName.text,
      "other_expense_amount": otherExpenseAmount
    });

    if (response != null && response["success"]) {
      final result =
          await Http.getData(endpoint: "pos.get_other_expenses", data: {
        "sales_transaction_id": widget.transactionId,
      });
      setState(() {
        if (result != null) {
          list = result["data"]["other_expenses"];
        }
        total += double.parse(otherExpenseAmount);
        _txtOtherExpenseName.text = "";
        _txtOtherExpenseAmount.text = "";
      });
    }
  }

  _removeData(dynamic itemSelected) async {
    final resultX =
        await Http.getData(endpoint: "pos.remove_other_expense", data: {
      "sales_transaction_other_expense_id": itemSelected["ret_other_expense_id"]
    });
    if (resultX != null && resultX["success"]) {
      final result =
          await Http.getData(endpoint: "pos.get_other_expenses", data: {
        "sales_transaction_id": widget.transactionId,
      });
      setState(() {
        if (result != null) {
          setState(() {
            list = result["data"]["other_expenses"];
            total = total - itemSelected["ret_other_expense_amount"];
          });
        }
      });
    }
  }
}

import 'dart:convert';
import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:pos_desktop/bloc/shift.dart';
import 'package:pos_desktop/pages/home_page.dart';
import 'package:pos_desktop/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/pages/print_page.dart';
import 'package:pos_desktop/plugins/date_serializer.dart';
import 'package:pos_desktop/plugins/printers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenShiftPage extends StatefulWidget {
  @override
  _OpenShiftPageState createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  var _selectedCashDrawer;
  // TextEditingController _txtOpeningBalance = TextEditingController();
  TextEditingController _txtOpeningBalance = TextEditingController();
  FocusNode _fnKeyboard = FocusNode();
  FocusNode _fnOpeningBalance = FocusNode();

  @override
  void initState() {
    super.initState();
    _txtOpeningBalance.text = "0";
  }

  @override
  void dispose() {
    _txtOpeningBalance.text;
    _fnKeyboard.dispose();
    _fnOpeningBalance.dispose();
    super.dispose();
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
          if (_fnOpeningBalance.hasFocus) {
            _openShift();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: FutureBuilder(
            future: Http.getData(endpoint: "pos.get_profile"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final response = snapshot.data;
              if (response != null && response["success"]) {
                final user = response["data"];
                return Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Card(
                      elevation: 8.0,
                      child: Row(
                        children: <Widget>[
                          Container(
                            color: Theme.of(context).accentColor,
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.height,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 30.0, top: 30.0, right: 30.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      SizedBox(
                                        height: 20.0,
                                      ),
                                      Text(
                                        "Welcome Back",
                                        style: Theme.of(context)
                                            .textTheme
                                            .display1
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .cardColor),
                                      ),
                                      Text(
                                        user["employee_name"],
                                        style: Theme.of(context)
                                            .textTheme
                                            .display2
                                            .copyWith(
                                              color:
                                                  Theme.of(context).canvasColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 20.0, top: 30.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          FlatButton.icon(
                                            icon: Icon(Icons.arrow_back,
                                                color: Theme.of(context)
                                                    .canvasColor),
                                            label: Text(
                                              _selectedCashDrawer == null
                                                  ? "CHANGE ACCOUNT"
                                                  : "CHANGE CASHDRAWER",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .title
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .canvasColor),
                                            ),
                                            onPressed: () async {
                                              if (_selectedCashDrawer == null) {
                                                Http.removeAccessToken();
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginPage(),
                                                  ),
                                                );
                                              } else {
                                                setState(() {
                                                  _selectedCashDrawer = null;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 20.0,
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding:
                                  const EdgeInsets.only(left: 30.0, top: 70.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    height: 20.0,
                                  ),
                                  Container(
                                    height: 5.0,
                                    width: 55.0,
                                    color: Theme.of(context).accentColor,
                                  ),
                                  Text(
                                    "Please check in to continue",
                                    style: Theme.of(context).textTheme.title,
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.25),
                                  Expanded(
                                    child: Center(
                                      child: _selectedCashDrawer == null
                                          ? _buildCashDrawerSelection()
                                          : _buildOpenShift(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container();
            }),
      ),
    );
  }

  _buildCashDrawerSelection() {
    return Container(
      child: FutureBuilder(
        future: Http.getData(endpoint: "pos.get_cash_drawers"),
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data["success"]) {
            return GridView.builder(
              itemCount: snapshot.data["data"].length,
              itemBuilder: (context, position) {
                final item = snapshot.data["data"].elementAt(position);
                return Card(
                  elevation: 4.0,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCashDrawer = item;
                        _getOpeningBalance();
                      });
                    },
                    child: Center(
                      child: Text(item["cash_drawer_name"]),
                    ),
                  ),
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1.8,
              ),
            );
          }
          return Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  _buildOpenShift() {
    return Center(
      child: Container(
        width: 300,
        child: Form(
          autovalidate: true,
          child: Column(
            children: <Widget>[
              Text(
                _selectedCashDrawer["cash_drawer_name"],
                style: Theme.of(context).textTheme.display3,
              ),
              FutureBuilder(
                  future: Http.getData(
                      endpoint: "pos.get_last_closing_balance",
                      data: {"cash_drawer_id": _selectedCashDrawer["id"]}),
                  builder: (context, snapshot) {
                    return Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          autofocus: true,
                          inputFormatters: <TextInputFormatter>[
                            WhitelistingTextInputFormatter(RegExp("[0-9]")),
                            ThousandsFormatter()
                          ],
                          controller: _txtOpeningBalance,
                          focusNode: _fnOpeningBalance,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(12.0),
                            border: OutlineInputBorder(),
                            labelText: "Opening Balance",
                            prefixText: "Rp. ",
                            prefixIcon: Icon(Icons.payment),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onFieldSubmitted: (text) {
                            _openShift();
                          },
                        ),
                      ],
                    );
                  }),
              Container(
                width: 300.0,
                child: _selectedCashDrawer != null
                    ? OutlineButton.icon(
                        icon: Icon(
                          Icons.open_in_browser,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          "OPEN SHIFT",
                          style: Theme.of(context)
                              .textTheme
                              .button
                              .copyWith(color: Theme.of(context).primaryColor),
                        ),
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor, width: 2),
                        highlightedBorderColor: Theme.of(context).primaryColor,
                        onPressed: () {
                          _openShift();
                        },
                      )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _openShift() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var removePrecision = _txtOpeningBalance.text.replaceAll(",", "");
    await prefs.setString("opening_balance", removePrecision);
    final response = await Http.getData(endpoint: "pos.open_shift", data: {
      "cash_drawer_id": _selectedCashDrawer["id"],
      "last_closing_balance": 0,
      "opening_balance": removePrecision
    });

    if (response != null && response["success"]) {
      shiftID = response["data"]["shift_id"];
      shiftNumber = response["data"]["shift_number"];
      shiftDate = DateParser.deserializeString(response["data"]["shift_date"]);
      openingBalance = removePrecision;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  _getOpeningBalance() async {
    final responseB = await Http.getData(
      endpoint: "pos.get_last_closing_balance",
      data: {"cash_drawer_id": _selectedCashDrawer["id"]},
    );
    if (responseB != null && responseB["success"]) {
      _txtOpeningBalance = TextEditingController(
          text: NumberFormat("#,##0")
                  .format(responseB["data"]["closing_balance"])
                  .toString() ??
              "0");
    }
  }
}

class CloseShiftPage extends StatefulWidget {
  @override
  _CloseShiftPageState createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  final TextEditingController _txtDepositAmount = TextEditingController();
  final TextEditingController _txtClosingBalance = TextEditingController();
  final TextEditingController _txtGeneralExpenses = TextEditingController();
  final TextEditingController _txtDescription = TextEditingController();
  final FocusNode _fnClosingBalance = FocusNode();
  final FocusNode _fnDescription = FocusNode();
  final FocusNode _fnDepositAmount = FocusNode();
  final FocusNode _fnGeneralExpenses = FocusNode();
  final FocusNode _fnKeyboard = FocusNode();
  var _shiftSummary;
  var widthPrint;
  final GlobalKey<FormState> _closeShiftFormKey = GlobalKey<FormState>();
  int total = 0;

  @override
  void initState() {
    super.initState();
    _getWidthPrint();
    _txtDepositAmount.text = "0";
    _txtClosingBalance.text = "0";
    _txtGeneralExpenses.text = "0";

    _getShiftSummary();
  }

  @override
  void dispose() {
    _fnClosingBalance.dispose();
    _fnDepositAmount.dispose();
    _fnGeneralExpenses.dispose();
    _fnDescription.dispose();
    _txtDescription.dispose();
    _txtDepositAmount.dispose();
    _txtClosingBalance.dispose();
    _txtGeneralExpenses.dispose();
    super.dispose();
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
          if (_fnGeneralExpenses.hasFocus) {
            FocusScope.of(context).requestFocus(_fnDepositAmount);
          }
          if (_fnDepositAmount.hasFocus) {
            FocusScope.of(context).requestFocus(_fnClosingBalance);
          }
          if (_fnClosingBalance.hasFocus) {
            _closeAndSignOut();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: Container(
          child: Center(
            child: Card(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Close Shift",
                      style: Theme.of(context).textTheme.headline.copyWith(
                            color: Theme.of(context).textTheme.title.color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 8.0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildShiftSummary(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildCloseShiftInput(),
                        )
                      ],
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FlatButton.icon(
                          icon: Icon(Icons.arrow_back),
                          label: Text("BACK TO TRANSACTION"),
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                        ),
                        _shiftSummary != null
                            ? OutlineButton.icon(
                                icon: Icon(
                                  Icons.exit_to_app,
                                  color: Theme.of(context).primaryColor,
                                ),
                                label: Text(
                                  "CLOSE & SIGN OUT",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button
                                      .copyWith(
                                          color:
                                              Theme.of(context).primaryColor),
                                ),
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2),
                                highlightedBorderColor:
                                    Theme.of(context).primaryColor,
                                onPressed: () {
                                  _closeAndSignOut();
                                },
                              )
                            : Container(),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildCloseShiftInput() {
    return Container(
      margin: const EdgeInsets.only(left: 16.0),
      child: Form(
        key: _closeShiftFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "DEPOSIT",
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(
              height: 16.0,
            ),
            TextFormField(
              autofocus: true,
              controller: _txtGeneralExpenses,
              focusNode: _fnGeneralExpenses,
              cursorColor: Colors.red,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
                labelText: "General Expense",
                labelStyle: TextStyle(color: Colors.red),
                prefixText: "Rp. ",
                prefixIcon: Icon(
                  Icons.payment,
                  color: Colors.red,
                ),
              ),
              inputFormatters: [ThousandsFormatter()],
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_fnDescription);
              },
              validator: (text) {
                if (text.isEmpty) {
                  return "cannot be empty";
                }
                return null;
              },
            ),
            SizedBox(
              height: 16.0,
            ),
            TextFormField(
              controller: _txtDescription,
              focusNode: _fnDescription,
              cursorColor: Colors.blue,
              maxLength: 180,
              maxLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12.0),
                labelText: "General Expense Description",
                prefixIcon: Icon(
                  Icons.receipt,
                ),
              ),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_fnDepositAmount);
              },
            ),
            SizedBox(
              height: 16.0,
            ),
            TextFormField(
              controller: _txtDepositAmount,
              focusNode: _fnDepositAmount,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12.0),
                labelText: "Deposit Amount",
                prefixText: "Rp. ",
                prefixIcon: Icon(Icons.payment),
              ),
              inputFormatters: [ThousandsFormatter()],
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_fnClosingBalance);
              },
              validator: (text) {
                if (text.isEmpty) {
                  return "cannot be empty";
                }
                return null;
              },
            ),
            SizedBox(
              height: 16.0,
            ),
            TextFormField(
              focusNode: _fnClosingBalance,
              controller: _txtClosingBalance,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12.0),
                labelText: "Closing Balance",
                prefixText: "Rp. ",
                prefixIcon: Icon(Icons.payment),
              ),
              inputFormatters: [ThousandsFormatter()],
              onFieldSubmitted: (text) {
                _closeAndSignOut();
              },
              validator: (text) {
                if (text.isEmpty) {
                  return "cannot be empty";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  _getShiftSummary() async {
    final response = await Http.getData(
      endpoint: "pos.get_sales_amount_total",
      data: {"shift_id": shiftID},
    );

    if (response != null && response["success"]) {
      setState(() {
        _shiftSummary = response["data"];
        total = response["data"]["amount_non_cash"] +
            response["data"]["amount_cash"] +
            int.tryParse(openingBalance);
      });
    }
  }

  _buildShiftSummary() {
    if (_shiftSummary != null) {
      final data = _shiftSummary;

      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "SUMMARY",
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(
              height: 8.0,
            ),
            Table(
              columnWidths: {
                0: FixedColumnWidth(150),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Opening Balance",
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${openingBalance != "" ? NumberFormat("#,##0").format(int.tryParse(openingBalance)) : 0}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "CASH",
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${NumberFormat("#,##0").format(data["amount_cash"])}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "NON CASH",
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${NumberFormat("#,##0").format(data["amount_non_cash"])}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ]),
                TableRow(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 0.5,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  children: [
                    Container(),
                    Container(),
                  ],
                ),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "TOTAL",
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${NumberFormat("#,##0").format(total)}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  _closeAndSignOut() async {
    var _txtDepositeAmountX = _txtDepositAmount.text.replaceAll(",", "");
    var _txtClosingBalanceX = _txtClosingBalance.text.replaceAll(",", "");
    var _txtGeneralExpensesX = _txtGeneralExpenses.text.replaceAll(",", "");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("opening_balance")) {
      await prefs.remove("opening_balance");
    }

    if (_closeShiftFormKey.currentState.validate()) {
      final response = await Http.getData(endpoint: "pos.close_shift", data: {
        "shift_id": shiftID,
        "sales_amount": total,
        "amount_cash": _shiftSummary["amount_cash"],
        "amount_non_cash": _shiftSummary["amount_non_cash"],
        "deposit_amount": double.parse(_txtDepositeAmountX),
        "closing_balance": double.parse(_txtClosingBalanceX),
        "general_expense": double.parse(_txtGeneralExpensesX),
        "general_expense_des": _txtDescription.text ?? "",
      });

      if (response != null && response["success"]) {
        setState(() {
          _getPrintPage();
          Navigator.pop(context, true);
        });
      }
    }
  }

  _getPrintPage() async {
    final responseF = await Http.getData(
        endpoint: "print.get_print_close_shift",
        data: {"close_shift_id": shiftID, "print_width": widthPrint ?? 32});
    if (responseF != null && responseF["success"]) {
      _closeShiftPrint(responseF["data"]);
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: PrintShift(
              dataPrint: responseF["data"],
            )),
      );
    }
  }

  _getWidthPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String conf = prefs.getString("printWidth");
    Map<String, dynamic> configJson = json.decode(conf);
    setState(() {
      widthPrint = configJson["width_print"];
    });
  }

  _closeShiftPrint(dynamic dataPrint) async {
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
}

class PrintShift extends StatefulWidget {
  final dynamic dataPrint;
  PrintShift({@required this.dataPrint});
  @override
  _PrintShiftState createState() => _PrintShiftState();
}

class _PrintShiftState extends State<PrintShift> {
  final GlobalKey<FormState> _formKeyForm = GlobalKey<FormState>();
  TextEditingController _txtWidthPrint = TextEditingController();
  final FocusNode _fnKeyboard = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkWidthPrint();
  }

  _checkWidthPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('printWidth')) {
      String conf = prefs.getString("printWidth");
      Map<String, dynamic> configJson = json.decode(conf);
      if (configJson["width_print"] == null) {
        Map<String, dynamic> configJson = {"width_print": "32"};
        String jsonEncode = json.encode(configJson);
        await prefs.setString("printWidth", jsonEncode);
      } else {
        setState(() {
          _txtWidthPrint =
              TextEditingController(text: configJson["width_print"] ?? 32);
        });
      }
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
          _settingWidth();
        }
      },
      child: Material(
        type: MaterialType.card,
        borderRadius: BorderRadius.circular(1.0),
        clipBehavior: Clip.antiAlias,
        child: Container(
          // width: MediaQuery.of(context).size.width * 0.3,
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Text(
                  "Print",
                  style: Theme.of(context).textTheme.headline.copyWith(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                height: 1.0,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(
                  child: Center(
                      child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    color: Colors.grey.withOpacity(0.1),
                    child: Text(
                      widget.dataPrint["print"],
                      style: TextStyle(fontFamily: 'Tes'),
                    ),
                  ),
                ),
              ))),
              Container(
                height: 1.0,
                color: Theme.of(context).dividerColor,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width * 0.11,
                    child: OutlineButton.icon(
                      icon: Icon(
                        Icons.settings_applications,
                        color: Colors.blueAccent,
                      ),
                      label: Text(
                        "SET PRINTER",
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(color: Colors.blueAccent),
                      ),
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                      highlightedBorderColor: Colors.blueAccent,
                      onPressed: () {
                        _settingPrinter();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.11,
                    child: OutlineButton.icon(
                      icon: Icon(
                        Icons.print,
                        color: Colors.green,
                      ),
                      label: Text(
                        "PRINT",
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(color: Colors.green),
                      ),
                      borderSide: BorderSide(color: Colors.green, width: 2),
                      highlightedBorderColor: Colors.green,
                      onPressed: () {
                        getPrinters();
                        Http.removeAccessToken();
                        shiftID = null;
                        shiftNumber = null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.11,
                    child: OutlineButton.icon(
                      icon: Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      label: Text(
                        "CLOSE",
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(color: Colors.red),
                      ),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                      highlightedBorderColor: Colors.red,
                      onPressed: () {
                        Navigator.pop(context);
                        Http.removeAccessToken();
                        shiftID = null;
                        shiftNumber = null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  getPrinters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('settingsPrint')) {
      String conf = prefs.getString("settingsPrint");
      Map<String, dynamic> configJson = json.decode(conf);
      setState(() {
        PrinterDocument("Struk")
          ..addText(widget.dataPrint["print"])
          ..addFeed()
          ..addFeed()
          ..addFeed()
          ..cutPaper()
          ..finish()
          ..print(configJson["print_name"]);
      });
      Navigator.pop(context, 0);
    } else {
      _settingPrinter();
    }
  }

  _settingWidth() async {
    final formState = _formKeyForm.currentState;
    if (formState.validate()) {
      formState.save();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> configJson = {"width_print": _txtWidthPrint.text};
      String jsonEncode = json.encode(configJson);
      await prefs.setString("printWidth", jsonEncode);
      _refreshDataPrint();
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
            padding: const EdgeInsets.all(16.0),
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
                      key: _formKeyForm,
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
                          inputFormatters: [
                            WhitelistingTextInputFormatter(RegExp("[0-9]")),
                            BlacklistingTextInputFormatter(RegExp("[/\\\\]")),
                            BlacklistingTextInputFormatter(RegExp("[a-zA-z]"))
                          ],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(5.0),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0))),
                          onFieldSubmitted: (text) async {
                            _settingWidth();
                          },
                          onChanged: (text) {
                            _settingWidth();
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

  _refreshDataPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String conf = prefs.getString("printWidth");
    Map<String, dynamic> configJson = json.decode(conf);
    final response = await Http.getData(
        endpoint: "print.get_print_close_shift",
        data: {
          "close_shift_id": shiftID,
          "print_width": configJson["width_print"] ?? 32
        });
    if (response != null && response["success"]) {
      setState(() {
        widget.dataPrint["print"] = response["data"]["print"];
      });
    }
    Navigator.pop(context);
  }
}

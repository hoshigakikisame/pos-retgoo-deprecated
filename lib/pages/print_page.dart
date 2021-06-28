import 'dart:convert';
import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_desktop/plugins/display.dart';
import 'package:pos_desktop/plugins/printers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class PrintPage extends StatefulWidget {
  final String transactionId;
  final dynamic dataPrint;
  PrintPage({@required this.dataPrint, this.transactionId});
  @override
  _PrintPageState createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
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
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Text(
                  "Print",
                  style: Theme.of(context).textTheme.headline5.copyWith(
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
                    padding: EdgeInsets.all(10.0),
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
                        _cancelPrintPreview();
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

  _cancelPrintPreview() {
    Navigator.pop(context, true);
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
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Printer Width",
                  style: Theme.of(context).textTheme.headline5,
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
                          onChanged: (text) async {
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
                  style: Theme.of(context).textTheme.headline5,
                ),
                SizedBox(
                  height: 8.0,
                ),
                Expanded(
                    child: SettingPrinter(
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
      Navigator.pop(context, true);
    } else {
      _settingPrinter();
    }
  }

  _refreshDataPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String conf = prefs.getString("printWidth");
    Map<String, dynamic> configJson = json.decode(conf);
    final response = await Http.getData(endpoint: "print.get_print", data: {
      "sales_trx_id": widget.transactionId,
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

class SettingPrinter extends StatefulWidget {
  final List list;

  const SettingPrinter({Key key, this.list}) : super(key: key);
  @override
  _SettingPrinterState createState() => _SettingPrinterState();
}

class _SettingPrinterState extends State<SettingPrinter> {
  final FocusNode focusNode = FocusNode();
  int _currentIndex = 0;
  final AutoScrollController _controller = AutoScrollController();
  String positionPrint;

  @override
  void initState() {
    super.initState();
    _getDataPrint();
  }

  _getDataPrint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('settingsPrint')) {
      String conf = prefs.getString("settingsPrint");
      Map<String, dynamic> configJson = json.decode(conf);
      setState(() {
        positionPrint = configJson["print_name"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: 300,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemCount: widget.list.length,
              itemBuilder: (context, position) {
                final item = widget.list.elementAt(position);

                return AutoScrollTag(
                  key: ValueKey(position),
                  controller: _controller,
                  index: position,
                  child: ListTile(
                    leading: Icon(Icons.print),
                    selected: _currentIndex == position,
                    title: Text(item),
                    trailing: item == positionPrint
                        ? Icon(
                            Icons.check_circle_outline,
                            color: Colors.blueAccent,
                          )
                        : null,
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      Map<String, dynamic> configJson = {"print_name": item};
                      String jsonEncode = json.encode(configJson);
                      await prefs.setString("settingsPrint", jsonEncode);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

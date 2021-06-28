import 'dart:convert';

import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_desktop/bloc/shift.dart';
import 'package:pos_desktop/load_config.dart';
import 'package:pos_desktop/pages/home_page.dart';
import 'package:pos_desktop/pages/shift_page.dart';
import 'package:pos_desktop/plugins/date_serializer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _hidePassword = true;
  bool _isInProgress = false;
  TextEditingController _txtUsername = TextEditingController();
  TextEditingController _txtPassword = TextEditingController();
  final FocusNode _txtPasswordNode = FocusNode();
  final FocusNode _txtUsernameNode = FocusNode();
  final FocusNode _focusNode = FocusNode();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  var ipAddress;
  var dataSettingServer;

  @override
  void dispose() {
    _txtUsernameNode.dispose();
    _txtPasswordNode.dispose();
    _txtUsername.dispose();
    _txtPassword.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _getSettingServer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (x) {
        if (!(x is RawKeyUpEvent)) {
          return;
        }

        if (x.logicalKey == LogicalKeyboardKey.f1) {
          _settingServer();
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        key: _scaffoldKey,
        body: Center(
          child: Stack(
            children: <Widget>[
              Card(
                child: Container(
                  padding: EdgeInsets.all(32.0),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Container(
                      height: 350,
                      width: 350,
                      child: _isInProgress ? _buildProgress() : _buildInput(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(
            height: 8.0,
          ),
          Text("Authenticating"),
        ],
      ),
    );
  }

  _buildInput() {
    final InputDecoration decoration = InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.all(10.0),
    );

    return Form(
      autovalidate: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              "Welcome",
              style: Theme.of(context).textTheme.display1.copyWith(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text("please sign in to continue"),
            SizedBox(
              height: 16.0,
            ),
            TextFormField(
              autofocus: true,
              validator: (text) {
                if (text.isEmpty) {
                  return "cannot be empty";
                }

                RegExp exp = RegExp(r"^[a-zA-Z0-9_\-@]+$");
                if (!exp.hasMatch(text)) {
                  return "some characters are not accepted";
                }

                return null;
              },
              controller: _txtUsername,
              focusNode: _txtUsernameNode,
              decoration: decoration.copyWith(
                hintText: "Username",
                prefixIcon: Icon(Icons.person),
              ),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_txtPasswordNode);
              },
            ),
            SizedBox(
              height: 4.0,
            ),
            TextField(
              controller: _txtPassword,
              focusNode: _txtPasswordNode,
              obscureText: _hidePassword,
              decoration: decoration.copyWith(
                hintText: "password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _hidePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (text) {
                _doLogin();
              },
            ),
            SizedBox(
              height: 8.0,
            ),
            OutlineButton(
              child: Text(
                "SIGN IN",
                style: Theme.of(context)
                    .textTheme
                    .button
                    .copyWith(color: Theme.of(context).primaryColor),
              ),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
              highlightedBorderColor: Theme.of(context).primaryColor,
              onPressed: () => _doLogin(),
            ),
            SizedBox(
              height: 8.0,
            ),
            OutlineButton.icon(
              icon: Icon(
                Icons.settings,
                color: Colors.black87,
              ),
              label: Text(
                ipAddress != null ? ipAddress : "127.0.0.1",
                style: Theme.of(context)
                    .textTheme
                    .button
                    .copyWith(color: Colors.black),
              ),
              borderSide: BorderSide(color: Colors.black),
              highlightedBorderColor: Colors.black,
              onPressed: () => _settingServer(),
            ),
          ],
        ),
      ),
    );
  }

  _doLogin() async {
    setState(() {
      _isInProgress = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final response = await Http.getData(
        endpoint: "pos.user_auth",
        data: {
          "username": _txtUsername.text,
          "password": _txtPassword.text,
        },
      );

      if (response != null) {
        if (response["success"]) {
          final data = response["data"];

          Http.setAccessToken(data["access_token"]);
          if (data["is_open_shift"]) {
            shiftID = data["shift_id"];
            shiftNumber = data["shift_number"];
            shiftDate = DateParser.deserializeString(data["shift_date"]);
            openingBalance = prefs.getString("opening_balance") ?? "";
            print(shiftID);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OpenShiftPage(),
              ),
            );
          }

          return;
        } else {
          _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "FAILED",
                    style: Theme.of(context).textTheme.body2.copyWith(
                          color: Colors.red.shade300,
                        ),
                  ),
                  Text(
                    "${response["data"]}",
                    style: Theme.of(context).textTheme.caption.copyWith(
                          color: Theme.of(context).canvasColor,
                        ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "ERROR",
                style: Theme.of(context).textTheme.body2.copyWith(
                      color: Colors.red.shade300,
                    ),
              ),
              Text(
                "Failed connecting to server.",
                style: Theme.of(context).textTheme.caption.copyWith(
                      color: Theme.of(context).canvasColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    setState(() {
      _isInProgress = false;
    });
  }

  _settingServer() async {
    var callback = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: SettingServer(
          data: dataSettingServer != null
              ? dataSettingServer
              : {"host": "127.0.0.1", "port": "12345"},
        ),
      ),
    );

    if (callback) {
      await _getSettingServer();
      setState(() {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => MyApp(),
        //   ),
        // );
      });
    }

    FocusScope.of(context).requestFocus(_txtUsernameNode);
  }

  _getSettingServer() async {
    await loadConfigs();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('settings')) {
      String conf = prefs.getString("settings");
      Map<String, dynamic> configJson = json.decode(conf);

      setState(() {
        ipAddress = configJson["host"];
        dataSettingServer = configJson;
      });

      return null;
    }

    return "192.168.2.101:19001";
  }
}

class SettingServer extends StatefulWidget {
  final dynamic data;
  SettingServer({@required this.data});
  @override
  _SettingServerState createState() => _SettingServerState();
}

class _SettingServerState extends State<SettingServer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _txtIpHostName = TextEditingController();
  TextEditingController _txtPort = TextEditingController();
  TextEditingController _txtDisplayPort = TextEditingController();
  TextEditingController _txtDisplayBaudRate = TextEditingController();
  TextEditingController _txtLine1 = TextEditingController();
  TextEditingController _txtLine2 = TextEditingController();
  FocusNode _portFocus = FocusNode();
  FocusNode _displayPortFocus = FocusNode();
  FocusNode _displayBaudRateFocus = FocusNode();
  FocusNode _line1Focus = FocusNode();
  FocusNode _line2Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _setField();
  }

  _setField() async {
    final sp = await SharedPreferences.getInstance();
    if (widget.data['host'] != null && widget.data['port'] != null) {
      setState(() {
        _txtIpHostName = TextEditingController(text: widget.data["host"]);
        _txtPort = TextEditingController(text: widget.data["port"]);
        _txtDisplayPort = TextEditingController(
          text: sp.getString("display_port")?.toString() ?? "",
        );
        _txtDisplayBaudRate = TextEditingController(
          text: sp.getInt("display_baud_rate")?.toString() ?? "9600",
        );
        _txtLine1 = TextEditingController(
          text: sp.getString("line1")?.toString() ?? "",
        );
        _txtLine2 = TextEditingController(
          text: sp.getString("line2")?.toString() ?? "",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      borderRadius: BorderRadius.circular(1.0),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                "Setting Server And Display Pole",
                style: Theme.of(context).textTheme.headline.copyWith(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Host/Ip"),
                      TextFormField(
                        autofocus: true,
                        validator: (text) {
                          if (text.isEmpty) {
                            return "cannot be empty";
                          }

                          return null;
                        },
                        controller: _txtIpHostName,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            hintText: 'Enter Ip Server'),
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_portFocus);
                        },
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text("Port"),
                      TextFormField(
                        focusNode: _portFocus,
                        validator: (text) {
                          if (text.isEmpty) {
                            return "cannot be empty";
                          }
                          return null;
                        },
                        controller: _txtPort,
                        inputFormatters: <TextInputFormatter>[
                          BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        ],
                        onFieldSubmitted: (text) {
                          FocusScope.of(context)
                              .requestFocus(_displayPortFocus);
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            hintText: 'Enter Port Server'),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text("Display Port"),
                      TextFormField(
                        focusNode: _displayPortFocus,
                        onFieldSubmitted: (text) {
                          FocusScope.of(context)
                              .requestFocus(_displayBaudRateFocus);
                        },
                        controller: _txtDisplayPort,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0)),
                          hintText: 'Enter Display Port',
                        ),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text("Display Baud Rate"),
                      TextFormField(
                        focusNode: _displayBaudRateFocus,
                        validator: (text) {
                          if (text.isEmpty) {
                            return "cannot be empty";
                          }
                          return null;
                        },
                        controller: _txtDisplayBaudRate,
                        inputFormatters: <TextInputFormatter>[
                          BlacklistingTextInputFormatter(RegExp("[a-zA-Z]")),
                        ],
                        onFieldSubmitted: (text) {
                          FocusScope.of(context).requestFocus(_line1Focus);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0)),
                          hintText: 'Enter Display Baud Rate',
                        ),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text("Display Line 1"),
                      TextFormField(
                        autofocus: true,
                        validator: (text) {
                          if (text.isEmpty) {
                            return "cannot be empty";
                          }

                          if (text.length > 20) {
                            return "Text tidak boleh lebih dari 20 kata";
                          }

                          return null;
                        },
                        controller: _txtLine1,
                        focusNode: _line1Focus,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            hintText: 'Enter Display Line 1'),
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_line2Focus);
                        },
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text("Display Line 2"),
                      TextFormField(
                        autofocus: true,
                        validator: (text) {
                          if (text.isEmpty) {
                            return "cannot be empty";
                          }

                          if (text.length > 20) {
                            return "Text tidak boleh lebih dari 20 kata";
                          }

                          return null;
                        },
                        controller: _txtLine2,
                        focusNode: _line2Focus,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            hintText: 'Enter Display Line 2'),
                        onEditingComplete: () {
                          final formState = _formKey.currentState;
                          if (!formState.validate()) {
                            return null;
                          }

                          if (formState.validate()) {
                            formState.save();
                            _submitSettingServer();
                          }
                          Navigator.pop(context, true);
                        },
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 1.0,
              color: Theme.of(context).dividerColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlineButton.icon(
                    icon: Icon(
                      Icons.done_outline,
                      color: Colors.green,
                    ),
                    label: Text(
                      "OK",
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.green),
                    ),
                    borderSide: BorderSide(color: Colors.green),
                    highlightedBorderColor: Colors.green,
                    onPressed: () {
                      final formState = _formKey.currentState;
                      if (!formState.validate()) {
                        return null;
                      }

                      if (formState.validate()) {
                        formState.save();
                        _submitSettingServer();
                      }

                      Navigator.pop(context, true);
                    },
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 10,
                  child: OutlineButton.icon(
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    label: Text(
                      "CANCEL",
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.red),
                    ),
                    borderSide: BorderSide(color: Colors.red),
                    highlightedBorderColor: Colors.red,
                    onPressed: () async {
                      Navigator.pop(context, false);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _submitSettingServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> configJson = {
      "host": _txtIpHostName.text,
      "port": _txtPort.text,
    };
    String jsonEncode = json.encode(configJson);
    await prefs.setString("settings", jsonEncode);
    await prefs.setString("display_port", _txtDisplayPort.text);
    await prefs.setInt(
      "display_baud_rate",
      int.tryParse(_txtDisplayBaudRate.text),
    );
    await prefs.setString("line1", _txtLine1.text);
    await prefs.setString("line2", _txtLine2.text);
  }
}

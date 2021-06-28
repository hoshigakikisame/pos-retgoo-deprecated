import 'dart:async';
import 'dart:convert';

import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/bloc/shift.dart';
import 'package:pos_desktop/bloc/transaction.dart';
import 'package:pos_desktop/dialogs/promo_dialog.dart';
import 'package:pos_desktop/dialogs/shorcut_transaction_dialog.dart';
import 'package:pos_desktop/dialogs/transaction_past_dialog.dart';
import 'package:pos_desktop/models/response_core.dart';
import 'package:pos_desktop/pages/login_page.dart';
import 'package:pos_desktop/pages/payment_page.dart';
import 'package:pos_desktop/pages/promos/free_product_selector.dart';
import 'package:pos_desktop/pages/promos/promo_code_page_new.dart';
import 'package:pos_desktop/pages/shift_page.dart';
import 'package:pos_desktop/pages/transaction_page.dart';
import 'package:pos_desktop/plugins/date_serializer.dart';
import 'package:pos_desktop/plugins/display.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List _transactions = [];
  final FocusNode _focusNode = FocusNode();
  final AutoScrollController _scrollController = AutoScrollController();
  var _selectedTransaction;
  var _informationStore;
  int _getPosTemplate;
  bool _isEnabledButton = true;
  final formatDate = DateFormat("EEEE, d MMMM yyyy");
  String line1 = "";
  String line2 = "";
  int count = 300;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      if (sp.containsKey("line1")) {
        line1 = sp.getString("line1");
      }

      if (sp.containsKey("line2")) {
        line2 = sp.getString("line2");
      }
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _getStoreInformation();
    _getCurrentTransaction();
    _getTemplatePos();
    _initializeTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeTimer() {
    count = 300;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      count--;
      print(count);
      if (count == 0) {
        CustomerDisplay.print("$line1\r\n$line2");
        timer.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("Resumed");
        break;
      case AppLifecycleState.inactive:
        print("Inactive");
        break;
      case AppLifecycleState.paused:
        CustomerDisplay.print("$line1\r\n$line2");
        break;
      case AppLifecycleState.detached:
        print("Detached");
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (!_timer.isActive) {
          return;
        }
        _timer.cancel();
      },
      onPointerUp: (event) {
        _initializeTimer();
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (ev) async {
          if (!(ev is RawKeyUpEvent)) {
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f1) {
            await _newTransaction();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f2) {
            await _previousCart();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f3) {
            await _nextCart();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f4) {
            if (_isEnabledButton) {
              await _buildNewCheckPromo();
            }
            return;
          }
          if (ev.logicalKey == LogicalKeyboardKey.f5) {
            await _cancelTransaction();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f7) {
            await _showHelpInfo();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f8) {
            await _showAllTransaction();
            return;
          }

          if (ev.logicalKey == LogicalKeyboardKey.f9) {
            await _showPromoDialog();
            return;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.blueGrey.shade50,
          appBar: AppBar(
            elevation: 4.0,
            brightness: Brightness.light,
            backgroundColor: Theme.of(context).canvasColor,
            textTheme: Theme.of(context).textTheme,
            iconTheme: Theme.of(context).iconTheme,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_informationStore != null
                    ? _informationStore["store_name"]
                    : "RETGOO STORE"),
                Text(
                  _informationStore != null
                      ? _informationStore["store_address"] +
                          " / " +
                          "Telp. ${_informationStore["phone_number"]}"
                      : "Jln. Terusan Candi Mendut 9B, Malang",
                  style: Theme.of(context).textTheme.body1,
                ),
              ],
            ),
            actions: <Widget>[
              Container(
                child: _selectedTransaction != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          right: 4.0,
                        ),
                        child: SizedBox(
                          width: 135,
                          child: OutlineButton.icon(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.redAccent,
                            ),
                            label: Text(
                              "CANCEL",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            highlightedBorderColor: Colors.redAccent,
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                            onPressed: () => _cancelTransaction(),
                          ),
                        ),
                      )
                    : Container(),
              ),
              Container(
                child: _selectedTransaction != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: 8.0,
                          bottom: 8.0,
                          right: 8.0,
                        ),
                        child: SizedBox(
                          width: 135,
                          child: OutlineButton.icon(
                            highlightedBorderColor: Colors.blueAccent,
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: Colors.blueAccent,
                            ),
                            label: Text("CHECKOUT",
                                style: TextStyle(color: Colors.blueAccent)),
                            borderSide:
                                BorderSide(color: Colors.blueAccent, width: 2),
                            onPressed: () =>
                                _isEnabledButton ? _buildNewCheckPromo() : null,
                          ),
                        ),
                      )
                    : Container(),
              )
            ],
          ),
          bottomNavigationBar: PreferredSize(
            preferredSize: Size.fromHeight(56.0),
            child: BottomAppBar(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                ),
                child: SizedBox(
                  height: 56.0,
                  child: Row(
                    children: <Widget>[
                      FlatButton.icon(
                        icon: Icon(Icons.add),
                        label: Text("New Cart"),
                        onPressed: _newTransaction,
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Container(
                        width: 1.0,
                        color: Theme.of(context).dividerColor,
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _transactions.length,
                          padding: EdgeInsets.only(
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, position) {
                            var transactionItem =
                                _transactions.elementAt(position);

                            return AutoScrollTag(
                              index: position,
                              controller: _scrollController,
                              key: ValueKey(position),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: 4.0,
                                ),
                                child: FlatButton.icon(
                                  icon: Icon(
                                    Icons.shopping_cart,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  color: _selectedTransaction == transactionItem
                                      ? Theme.of(context).dividerColor
                                      : null,
                                  label: Text(
                                    transactionItem["transaction_number"] ??
                                        "*",
                                  ),
                                  onPressed: () async {
                                    await _selectCart(transactionItem);
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
            ),
          ),
          drawer: _buildLeftPanel(),
          body: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildContainerPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCart(dynamic trxItem) async {
    setState(() {
      _selectedTransaction = trxItem;
    });

    await Future.delayed(Duration(milliseconds: 100), () {
      // var states = TransactionPage.of(context, false);

      // if (states == null) {
      //   return;
      // }

      // states.activate();

      if (_transactionKey == null) {
        print("_transactionKey is null");
        return;
      }

      if (_transactionKey.currentState == null) {
        print("_transactionKey.currentState is null");
        return;
      }

      _transactionKey.currentState.activate();
    });
  }

  _getTemplatePos() async {
    final response = await Http.getData(endpoint: "pos.get_template_pos");
    if (response != null) {
      if (!mounted) return;
      setState(() {
        _getPosTemplate = response['data']['template_pos'];
      });
    }
  }

  _getStoreInformation() async {
    final response = await Http.getData(endpoint: "pos.get_store_information");
    if (response != null) {
      if (!mounted) return;
      setState(() {
        _informationStore = response['data'];
      });
    }
  }

  _getCurrentTransaction() async {
    final response =
        await Http.getData(endpoint: "pos.get_waiting_carts", data: {
      "shift_id": shiftID,
    });

    if (response != null && response["success"]) {
      _transactions.clear();
      response["data"]["sales_transactions"].forEach((trx) {
        List<Map<String, dynamic>> items = [];

        Map<String, dynamic> trxState = trx;

        if (!trxState.containsKey("customer_id")) {
          trx["customer_id"] = null;
        }

        if (!trxState.containsKey("customer_name")) {
          trx["customer_name"] = null;
        }

        if (!trxState.containsKey("customer_code")) {
          trx["customer_code"] = null;
        }

        if (!trxState.containsKey("referral_id")) {
          trx["referral_id"] = null;
        }

        if (!trxState.containsKey("referral_name")) {
          trx["referral_name"] = null;
        }

        if (!trxState.containsKey("referral_code")) {
          trx["referral_code"] = null;
        }

        Future<dynamic> fResponse = Http.getData(
          endpoint: "pos.get_detail_carts",
          data: {
            "sales_transaction_id": trx["sales_transaction_id"],
          },
        );

        fResponse.then((detailResponse) {
          if (detailResponse != null && detailResponse["success"]) {
            if (detailResponse["data"]["sales_transaction_details"] != null) {
              detailResponse["data"]["sales_transaction_details"]
                  .forEach((item) {
                Map<String, dynamic> rowData = {};
                rowData["sales_transaction_id"] = trx["sales_transaction_id"];
                rowData["sales_transaction_detail_id"] =
                    item["ret_sales_transaction_detail_id"];
                rowData["uom_id"] = item["ret_uom_id"];
                rowData["unit"] = item["ret_uom_name"];
                rowData["product_id"] = item["ret_product_id"];
                rowData["unit_price"] =
                    ((item["ret_default_unit_price"] ?? 0.0) as num)
                        ?.toDouble();
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
        });

        trx["items"] = items;
        _transactions.add(trx);
      });

      if (_transactions.isEmpty) {
        await _newTransaction();
        if (!mounted) return;
        setState(() {
          _selectedTransaction =
              _transactions.elementAt(_transactions.length - 1);
        });
        return;
      }

      if (!mounted) return;
      setState(() {});
    }
  }

  _newTransaction() async {
    final response = await Http.getData(endpoint: "pos.add_cart", data: {
      "shift_id": shiftID,
    });

    if (response != null && response["success"]) {
      var newTransaction = {
        "sales_transaction_id": response["data"]["sales_transaction_id"],
        "transaction_number": response["data"]["transaction_number"],
        "customer_name": response["data"]["customer_name"],
        "customer_id": response["data"]["customer_id"],
        "customer_code": response["data"]["customer_code"],
        "referral_id": response["data"]["referral_id"],
        "referral_code": response["data"]["referral_code"],
        "referral_name": response["data"]["referral_name"],
        "items": <Map<String, dynamic>>[
          {},
        ],
      };

      setState(() {
        _transactions.add(newTransaction);
        _selectedTransaction = newTransaction;
      });

      await Future.delayed(Duration(milliseconds: 100), () {
        _scrollController
            .scrollToIndex(_transactions.indexOf(_selectedTransaction));

        if (_transactionKey == null) {
          print("_transactionKey is null");
          return;
        }

        if (_transactionKey.currentState == null) {
          print("_transactionKey.currentState is null");
          return;
        }

        _transactionKey.currentState.activate();
      });
    }
  }

  _previousCart() {
    if (_transactions.isNotEmpty && _selectedTransaction != null) {
      int currentIndex = _transactions.indexOf(_selectedTransaction);

      if (currentIndex > 0) {
        currentIndex--;

        setState(() {
          _selectedTransaction = _transactions.elementAt(currentIndex);
        });

        Future.delayed(Duration(milliseconds: 100), () {
          _transactionKey.currentState.activate();
          _scrollController
              .scrollToIndex(_transactions.indexOf(_selectedTransaction));
        });
      }
    }
  }

  _nextCart() {
    if (_transactions.isNotEmpty && _selectedTransaction != null) {
      int currentIndex = _transactions.indexOf(_selectedTransaction);
      if (currentIndex < _transactions.length - 1) {
        currentIndex++;

        setState(() {
          _selectedTransaction = _transactions.elementAt(currentIndex);
        });

        Future.delayed(Duration(milliseconds: 100), () {
          _transactionKey.currentState.activate();
          _scrollController
              .scrollToIndex(_transactions.indexOf(_selectedTransaction));
        });
      }
    }
  }

  _buildLeftPanel() {
    return Drawer(
      child: Container(
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.all(16.0),
        color: Theme.of(context).primaryColorDark,
        child: Column(
          children: <Widget>[
            _buildUserInfo(),
            SizedBox(
              height: 8.0,
            ),
            _buildMenu(),
          ],
        ),
      ),
    );
  }

  _buildUserInfo() {
    return FutureBuilder(
      future: Http.getData(endpoint: "pos.get_profile"),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.white30,
                radius: 48,
              ),
              SizedBox(
                height: 16.0,
              ),
              Text(
                "${snapshot.data["data"]["employee_name"]}",
                style: Theme.of(context).textTheme.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(
                height: 8.0,
              ),
              OutlineButton(
                child: Text("CLOSE SHIFT"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                borderSide: BorderSide(
                  width: 2.0,
                  color: Colors.white,
                ),
                textColor: Colors.white,
                onPressed: () async {
                  bool isLogout = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CloseShiftPage(),
                    ),
                  );

                  if (isLogout ?? false) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        }

        return Container(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  _buildMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: ListTile(
              title: Text("NEW CART"),
              subtitle: Text(
                "Create new empty cart",
                style: Theme.of(context).textTheme.caption,
              ),
              leading: Icon(Icons.shopping_basket),
              onTap: () {
                _newTransaction();
              },
            ),
          ),
        ),
        Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: ListTile(
              title: Text("Help (F7)"),
              subtitle: Text(
                "Shortcut Information",
                style: Theme.of(context).textTheme.caption,
              ),
              leading: Icon(Icons.help),
              onTap: () {
                _showHelpInfo();
              },
            ),
          ),
        ),
        Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text("Print Past Transaction (F8)"),
              subtitle: Text(
                "Select past transaction to print it again",
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
              leading: Icon(Icons.print),
              onTap: () {
                _showAllTransaction();
              },
            ),
          ),
        ),
        Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: ListTile(
              title: Text("Promo (F9)"),
              subtitle: Text(
                "Search for existing promo",
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
              leading: Icon(Icons.local_offer),
              onTap: () {
                _showPromoDialog();
              },
            ),
          ),
        ),
      ],
    );
  }

  _showPromoDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PromoDialog(),
    );
  }

  _showAllTransaction() async {
    await showDialog(
        context: context, builder: (context) => TransactionPastDialog(shiftID));
  }

  _showHelpInfo() async {
    await showDialog(
        context: context, builder: (context) => ShortcutDialogTransaction());
  }

  GlobalKey<TransactionPageState> _transactionKey = GlobalKey();
  _buildContainerPanel() {
    return _selectedTransaction != null
        ? TransactionPage(
            transaction: _selectedTransaction, template: _getPosTemplate)
        : Container();
  }

  _cancelTransaction() async {
    if (_selectedTransaction != null) {
      lastReferrerName = null;
      lastReferrerID = null;
      int idx = _transactions.indexOf(_selectedTransaction);
      final response = await Http.getData(
        endpoint: "pos.cancel_cart",
        data: {
          "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
        },
      );

      if (response != null && response["success"]) {
        setState(() {
          _transactions.remove(_selectedTransaction);

          if (_transactions.isEmpty) {
            _selectedTransaction = null;
          } else {
            if (idx > 0) {
              idx--;
              _selectedTransaction = _transactions.elementAt(idx);
              return;
            }

            if (idx == 0 && _transactions.isNotEmpty) {
              _selectedTransaction = _transactions.elementAt(idx);
              return;
            }

            if (_transactions.length - 1 >= idx) {
              _selectedTransaction = _transactions.elementAt(idx);
              return;
            }
          }

          _selectedTransaction = null;
        });
      }
    }
  }

  _buildPaymentPage() async {
    setState(() {
      _isEnabledButton = false;
    });
    lastReferrerName = null;
    lastReferrerID = null;

    final checkOutResponse =
        await HttpFramework.getData("pos.checkout_cart_new", body: {
      "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
    });

    if (checkOutResponse == null) {
      return;
    }

    if (!checkOutResponse.success) {
      return;
    }

    print(checkOutResponse.toMap());

    var paymentResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          payment: checkOutResponse.toMap(),
          transactionId: _selectedTransaction["sales_transaction_id"],
        ),
      ),
    );

    if (paymentResult ?? false) {
      _getCurrentTransaction();
      _transactions.remove(_selectedTransaction);
      _selectedTransaction = null;
      if (!mounted) return;
      setState(() {
        _isEnabledButton = true;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isEnabledButton = true;
      });
    }

    // setState(() {
    //   _isEnabledButton = true;
    // });
    // final response =
    //     await Http.getData(endpoint: "pos.checkout_cart_new", data: {
    //   "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
    // });
    // if (response["data"]["amount_total"] != null && response["success"]) {
    //   if (response != null) {
    //     var itemShow = await showDialog(
    //         barrierDismissible: false,
    //         context: context,
    //         builder: (context) => PaymentPage(
    //               payment: response,
    //               transactionId: _selectedTransaction["sales_transaction_id"],
    //             ));
    //     if (itemShow) {
    //       _getCurrentTransaction();
    //       _transactions.remove(_selectedTransaction);
    //       _selectedTransaction = null;
    //       _isEnabledButton = true;
    //     } else {
    //       setState(() {
    //         _isEnabledButton = true;
    //       });
    //     }
    //   }
    // }
  }

  _buildNewCheckPromo() async {
    lastReferrerName = null;
    lastReferrerID = null;

    if (_selectedTransaction == null) {
      return null;
    }

    final appliesPromoTest =
        await HttpFramework.getData("pos.get_applies_promo", body: {
      "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
      "is_term_cash": true,
      "is_term_non_cash": false,
      "is_term_sales_credit": false
    });

    if (appliesPromoTest == null) {
      return _buildPaymentPage();
    }

    Map<String, dynamic> promoMap = appliesPromoTest.dataToMap();
    if (promoMap == null) {
      return _buildPaymentPage();
    }

    List promoList = promoMap["applies_promo"] ?? List();

    if (promoList.length <= 0) {
      return _buildPaymentPage();
    }

    setState(() {
      _isEnabledButton = false;
    });

    if (promoMap["is_procedure"]) {
      List<Map<String, dynamic>> items = [];

      final procedureResponse = await HttpFramework.getData(
          "pos.get_applies_promo_procedure",
          body: {"applies_promo": promoList});

      if (procedureResponse.success) {
        Map<String, dynamic> appliesPromoProcudure =
            procedureResponse.dataToMap();
        if (appliesPromoProcudure != null &&
            appliesPromoProcudure.containsKey("applies_promo_procedure")) {
          List<dynamic> promoItem =
              appliesPromoProcudure["applies_promo_procedure"];
          promoItem.forEach((item) {
            Map<String, dynamic> rowData = {};
            final dateTime = DateParser.deserializeString(item["finish_date"]);
            rowData["promo_name"] = item["promo_name"];
            rowData["valid_date"] = formatDate.format(dateTime);
            rowData["procedure"] = item["procedur"];
            rowData["promo_code"] = item["promo_code"];
            rowData["benefit"] = item["benefit"];
            rowData["promo_id"] = item["promo_id"];
            rowData["is_procedure"] = item["is_procedure"];
            items.add(rowData);
          });
        }
      }

      var newCallback = await showDialog(
          context: context, builder: (ctx) => PromoCodePageX(items));

      if (newCallback != null) {
        final setResponse =
            await HttpFramework.getData("pos.set_promo_procedure", body: {
          "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
          "member_id": promoMap["member_id"],
          "applies_promo": promoList,
          "applies_promo_procedure": newCallback,
        });

        if (setResponse == null) {
          _buildPaymentPage();
          return null;
        }

        Map<String, dynamic> setResponseData = setResponse.dataToMap();
        if (!setResponseData.containsKey("applies_promo")) {
          _buildPaymentPage();
          return null;
        }

        List<dynamic> appliesPromoList =
            setResponseData["applies_promo"] ?? List();
        if (appliesPromoList == null || appliesPromoList.length <= 0) {
          _buildPaymentPage();
          return null;
        }

        await _processAppliesPromo(appliesPromoList, setResponseData);
        await Future.delayed(Duration(milliseconds: 500), () async {
          await _buildPaymentPage();
        });
        return null;
      }
    } else {
      await _processAppliesPromo(promoList, promoMap);
      await Future.delayed(Duration(milliseconds: 500), () async {
        await _buildPaymentPage();
      });
    }

    setState(() {
      _isEnabledButton = true;
    });

    return null;
  }

  _processAppliesPromo(
      List<dynamic> appliesPromo, Map<String, dynamic> promoMap) async {
    appliesPromo.forEach((item) async {
      switch (item["benefit"]) {
        case 1:
          await _benefitFirst(item["promo_id"], promoMap["member_id"] ?? null);
          break;
        case 2:
          await _benefitSecond(item["promo_id"], promoMap["member_id"] ?? null);
          break;
        case 3:
          await _benefitThird();
          break;
        case 4:
          await _benefitFourth();
          break;
        default:
      }
    });
  }

  //FIRST Benefit [DONE]
  _benefitFirst(var promoID, String memberId) async {
    final freeProductResponse = await Http.getData(
        endpoint: "pos.get_free_product",
        data: {"promo_id": promoID, "member_id": memberId});
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
  _benefitSecond(var promoID, String memberId) async {
    final benefit2Response = await HttpFramework.getData(
        "pos.set_promo_benefit_disc_product",
        body: {
          "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
          "promo_id": promoID,
          "member_id": memberId
        });
    if (benefit2Response != null && benefit2Response.success) {
      print(benefit2Response.toMap());
      return;
    }
    // final responseB = await Http.getData(
    //     endpoint: "pos.set_promo_benefit_disc_product",
    //     data: {
    //       "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
    //       "promo_id": promoID,
    //       "member_id": memberId
    //     });
    // if (responseB != null && responseB["success"]) {
    //   // _buildPaymentPage();
    //   return;
    // }
  }

  //THIRD benefit [UNDONE {Kurang api belum jadi}]
  _benefitThird() async {
    print(3);
    final discNominalResponse = await Http.getData(
        endpoint: "pos.set_promo_benefit_disc_nominal", data: {});
    if (discNominalResponse != null && discNominalResponse["success"]) {
      return;
    }
  }

  //FOURTH benefit [UNDONE {API belum jadi}]
  _benefitFourth() async {
    print(4);
    final redeemResponse =
        await Http.getData(endpoint: "pos.get_cheap_redeem", data: {});
    if (redeemResponse != null && redeemResponse["success"]) {}
  }

  //TERUSAN dari FIRST Benefit
  _setPromoBenefitFreeProduct(var promoId, var freeProducts) async {
    final freeProductsResponse = await Http.getData(
        endpoint: "pos.set_promo_benefit_free_product",
        data: {
          "sales_transaction_id": _selectedTransaction["sales_transaction_id"],
          "promo_id": promoId,
          "free_products": freeProducts
        });
    if (freeProductsResponse != null && freeProductsResponse["success"]) {
      return;
    }
  }
}

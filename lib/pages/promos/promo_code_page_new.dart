import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:pos_desktop/widgets/data_grid_view.dart';

class PromoCodePageX extends StatefulWidget {
  final List<Map<String, dynamic>> appliesPromoProcedure;

  PromoCodePageX(this.appliesPromoProcedure) : super(key: UniqueKey());

  @override
  _PromoCodePageXState createState() => _PromoCodePageXState();
}

class _PromoCodePageXState extends State<PromoCodePageX> {
  final FocusNode _keyboardListenerFn = FocusNode();
  final GlobalKey<DataGridViewState> _gridViewPromoKey = GlobalKey();
  final formatDate = DateFormat("EEEE, d MMMM yyyy");

  String currentPromo;

  List<Map<String, dynamic>> appliesPromoProcedure;

  @override
  void initState() {
    super.initState();
    appliesPromoProcedure = widget.appliesPromoProcedure;
    if (!mounted) return;
    setState(() {});
    _getCurrentPromo();
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
      if (!mounted) return;
      setState(() {
        if (singleString == "") {
          currentPromo = "Tidak ada promo!";
        } else {
          currentPromo = singleString;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(appliesPromoProcedure);
    // print("applies" + appliesPromo.toMap().toString());
    return RawKeyboardListener(
      focusNode: _keyboardListenerFn,
      onKey: (keyEvent) {
        if (!(keyEvent is RawKeyUpEvent)) {
          return;
        }

        if (_keyboardListenerFn.hasFocus) {
          bool isControlPressed = keyEvent.isControlPressed;

          if (keyEvent.logicalKey == LogicalKeyboardKey.f12 ||
              (keyEvent.isShiftPressed &&
                  keyEvent.logicalKey == LogicalKeyboardKey.arrowDown) ||
              (isControlPressed &&
                  keyEvent.isShiftPressed &&
                  keyEvent.logicalKey == LogicalKeyboardKey.arrowDown)) {
            _gridViewPromoKey.currentState.focusToLastRowFirstColumn();
            return;
          }

          if (isControlPressed &&
              keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
            _gridViewPromoKey.currentState.focusToPreviosRow();
            return;
          }

          if (isControlPressed &&
              keyEvent.logicalKey == LogicalKeyboardKey.arrowDown) {
            _gridViewPromoKey.currentState.focusToNextRow();
            return;
          }

          if (isControlPressed &&
              keyEvent.logicalKey == LogicalKeyboardKey.arrowRight) {
            _gridViewPromoKey.currentState.focusToNextColumn();
            return;
          }

          if (isControlPressed &&
              keyEvent.logicalKey == LogicalKeyboardKey.arrowLeft) {
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
              field: "promo_name",
              header: "Promo Name",
              readOnly: true,
              textAlign: TextAlign.center,
            ));

            columns.add(DataGridColumn(
              field: "valid_date",
              header: "Valid Date",
              readOnly: true,
              columnType: DataGridColumnType.date,
              textAlign: TextAlign.center,
            ));

            columns.add(DataGridColumn(
              field: "procedure",
              header: "Procedure",
              readOnly: true,
              textAlign: TextAlign.center,
            ));

            columns.add(DataGridColumn(
              autoFocusable: true,
              field: "promo_code",
              header: "Promo Code",
              onSubmitted: (state, text, rowData) async {
                _updateDataNew(text);
                // setState(() {

                // });
                return true;
              },
            ));

            return DataGridView(
              columns: columns,
              dataSource: appliesPromoProcedure,
              key: _gridViewPromoKey,
              hightlightBackgroundColor: Colors.blue.shade100,
              header: Container(
                height: 80,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Input Promo Code',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline
                                              .copyWith(
                                                fontWeight: FontWeight.w400,
                                              )),
                                    ),
                                  ],
                                ),
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
                          child: SizedBox(
                            height: 10.0,
                          ),
                        ),
                        Expanded(
                          child: Container(
                              height: 100.0,
                              width: 100.0,
                              padding: const EdgeInsets.all(10.0),
                              child: Marquee(
                                text: currentPromo ?? "Tidak ada promo!",
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
                                  borderSide:
                                      BorderSide(color: Colors.green, width: 2),
                                  onPressed: () {
                                    Navigator.pop(
                                        context, appliesPromoProcedure);
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
          }),
        ),
      ),
    );
  }

  _updateDataNew(String promoCode) async {
    // print("Applies : " + appliesPromoProcedure.toString());
    List<Map<String, dynamic>> items = [];
    await Future.delayed(Duration(milliseconds: 1), () {
      if (appliesPromoProcedure != null) {
        for (final promo in appliesPromoProcedure) {
          if (!promo.containsKey("promo_id")) {
            continue;
          }
          Map<String, dynamic> rowData = {};
          rowData["promo_name"] = promo["promo_name"];
          rowData["valid_date"] = promo["valid_date"];
          rowData["procedure"] = promo["procedure"];
          rowData["promo_code"] = promoCode;
          rowData["benefit"] = promo["benefit"];
          rowData["promo_id"] = promo["promo_id"];
          rowData["is_procedure"] = promo["is_procedure"];
          items.add(rowData);
        }
      }

      // print(items);
      // items.add({});
      setState(() {
        appliesPromoProcedure = items;
        _gridViewPromoKey.currentState.reFocus();
      });
    });
  }
}

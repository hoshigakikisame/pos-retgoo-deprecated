import 'dart:convert';
import 'package:toast/toast.dart';
import 'package:flutter/material.dart';

class FreeProductsSelector extends StatefulWidget {
  final List list;
  FreeProductsSelector({Key key, this.list}) : super(key: key);
  @override
  _FreeProductsSelectorState createState() => _FreeProductsSelectorState();
}

class _FreeProductsSelectorState extends State<FreeProductsSelector> {
  List _selectedList = [];

  @override
  void initState() {
    super.initState();
    _selectedList.add(widget.list[0]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Material(
          type: MaterialType.card,
          borderRadius: BorderRadius.circular(8.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              Container(
                color: Theme.of(context).primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(15.0),
                      child: Text('Choose Free Products',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.list.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = widget.list[index];
                    return Container(
                      child: CheckboxListTile(
                        title: Text(item['ret_product_name']),
                        subtitle: Text(item["ret_product_qrcode"] +
                            "\n" +
                            item["ret_qty"].toString() +
                            " | " +
                            item["uom_name"]),
                        isThreeLine: true,
                        value: _selectedList.contains(item),
                        onChanged: (value) {
                          if (value) {
                            if (!_selectedList.contains(
                                item)) if (_selectedList.length == 0) {
                              setState(() {
                                _selectedList.add(item);
                              });
                            } else {
                              setState(() {
                                _selectedList.clear();
                                _selectedList.add(item);
                              });
                            }
                          } else {
                            if (_selectedList.contains(item))
                              setState(() {
                                _selectedList.remove(item);
                              });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlineButton.icon(
                        highlightedBorderColor: Colors.blueAccent,
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: Colors.blueAccent,
                        ),
                        label: Text("SUBMIT",
                            style: TextStyle(color: Colors.blueAccent)),
                        borderSide:
                            BorderSide(color: Colors.blueAccent, width: 2),
                        onPressed: () {
                          if (_selectedList.length > 0) {
                            Map<String, dynamic> jsonB = {
                              "free_product": jsonEncode(_selectedList),
                            };
                            Navigator.pop(context, jsonB);
                          } else {
                            Toast.show("Select at least one item", context,
                                duration: Toast.LENGTH_SHORT,
                                gravity: Toast.CENTER);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

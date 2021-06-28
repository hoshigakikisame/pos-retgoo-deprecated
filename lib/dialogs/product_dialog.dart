import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/widgets/list_control_tile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ProductSelectionDialog extends StatefulWidget {
  final List list;
  final String text;

  const ProductSelectionDialog({Key key, this.list, this.text})
      : super(key: key);

  @override
  _ProductSelectionDialogState createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  final FocusNode focusNode = FocusNode();
  int _currentIndex = 0;
  final AutoScrollController _controller = AutoScrollController();
  TextEditingController _txtSearch = TextEditingController();
  bool isAllItem = false;

  @override
  void initState() {
    _txtSearch = TextEditingController(text: widget.text ?? "");
    super.initState();
  }

  @override
  void dispose() {
    _txtSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      child: Container(
        height: 300,
        width: 300,
        child: Column(
          children: <Widget>[
            Container(
              height: 20,
              child: TextField(
                style: TextStyle(fontSize: 10),
                controller: _txtSearch,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(4.0),
                  icon: Icon(
                    Icons.search,
                    size: 18,
                  ),
                  hintText: "type to search product",
                  hintStyle: TextStyle(fontSize: 10),
                ),
                onChanged: (text) async {
                  final response =
                      await Http.getData(endpoint: "pos.find_product", data: {
                    "keyword": text,
                    "is_keyword_all": isAllItem,
                    "category_id": null,
                    "brand_id": null,
                  });

                  if (response != null && response["success"]) {
                    widget.list.clear();

                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      widget.list.addAll(response["data"]);
                    });
                  }
                },
                onEditingComplete: () {
                  Navigator.pop(context, widget.list.elementAt(_currentIndex));
                },
              ),
            ),
            Divider(),
            Container(
              height: 35,
              child: Row(
                children: <Widget>[
                  Transform(
                    transform: Matrix4.identity()..scale(0.8),
                    child: ChoiceChip(
                      label: Text(
                        "Show All Item",
                        style: TextStyle(fontSize: 14),
                      ),
                      selected: isAllItem,
                      avatar: Icon(Icons.check, size: 16),
                    ),
                  )
                ],
              ),
            ),
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
                    child: Container(
                      color: _currentIndex != null && _currentIndex == position
                          ? Colors.blueGrey.withOpacity(0.2)
                          : Colors.white,
                      child: ListControlTile(
                        containerSpace: 1,
                        isTopSubtitle: true,
                        selected: _currentIndex == position,
                        title: Text(
                          item["ret_product_name"] ?? "",
                          style: TextStyle(fontSize: 10),
                        ),
                        subTitle: Text(
                          item["ret_product_code"] ??
                              "" + item["ret_product_qrcode"] ??
                              "",
                          style: TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                            "Rp. " +
                                    NumberFormat("#,##0")
                                        .format(
                                            item["ret_default_unit_price"] ?? 0)
                                        .toString() +
                                    " / " +
                                    item["ret_qty_available"].toString() ??
                                "0" + " /" + item["ret_uom_name"] ??
                                " ",
                            style: TextStyle(fontSize: 10)),
                        onTap: () {
                          Navigator.pop(context, item);
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
      onKey: (RawKeyEvent ev) {
        if (!(ev is RawKeyUpEvent)) {
          return;
        }

        if (ev.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.pop(context, widget.list[_currentIndex]);
          return;
        }

        if (ev.isAltPressed && ev.logicalKey?.keyLabel == "a") {
          setState(() {
            isAllItem = !isAllItem;
          });
          return;
        }

        if (ev.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (_currentIndex > 0) {
            setState(() {
              _currentIndex--;
            });

            Future.delayed(Duration(milliseconds: 100), () {
              _controller.scrollToIndex(_currentIndex);
            });
          }
          return;
        }

        if (ev.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_currentIndex < widget.list.length - 1) {
            setState(() {
              _currentIndex++;
            });

            Future.delayed(Duration(milliseconds: 100), () {
              _controller.scrollToIndex(_currentIndex);
            });
          }
          return;
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_desktop/models/promo.dart';
import 'package:pos_desktop/models/response_core.dart';
import 'package:pos_desktop/widgets/base_control_dialog.dart';
import 'package:pos_desktop/widgets/expanded_list_tile.dart';
import 'package:pos_desktop/widgets/list_control_tile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class PromoDialog extends StatefulWidget {
  @override
  _PromoDialogState createState() => _PromoDialogState();
}

class _PromoDialogState extends State<PromoDialog> {
  String keyword;

  List<Promo> transactionList = [];

  final FocusNode focusNode = FocusNode();
  int _currentIndex = 0;
  final AutoScrollController _controller = AutoScrollController();
  TextEditingController _txtSearch = TextEditingController();
  bool isAllItem = false;

  @override
  void initState() {
    _txtSearch = TextEditingController(text: keyword ?? "");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseControlDialog(
      isUsingDefaultContainer: true,
      dialogWidth: MediaQuery.of(context).size.width * 0.7,
      child: RawKeyboardListener(
        focusNode: focusNode,
        onKey: (keyListen) {
          if (!(keyListen is RawKeyUpEvent)) {
            return;
          }

          if (keyListen.logicalKey == LogicalKeyboardKey.arrowUp) {
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

          if (keyListen.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_currentIndex < transactionList.length - 1) {
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
        child: Container(
          child: Column(
            children: <Widget>[
              TextField(
                controller: _txtSearch,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12.0),
                  icon: Icon(Icons.search),
                  hintText: "type to search promo",
                ),
                onChanged: (text) {
                  setState(() {
                    keyword = text;
                  });
                },
                onEditingComplete: () {},
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 1.0,
                color: Theme.of(context).dividerColor,
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: FutureBuilder<bool>(
                  future: _refreshItems(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text("Failed get data"));
                    }

                    if (!snapshot.data) {
                      return Center(child: Text("Failed to show data"));
                    }

                    if (transactionList == null) {
                      return Container();
                    }

                    return ListView.builder(
                      controller: _controller,
                      itemCount: transactionList.length,
                      itemBuilder: (context, index) {
                        final item = transactionList.elementAt(index);
                        return AutoScrollTag(
                          key: ValueKey(index),
                          controller: _controller,
                          index: index,
                          child: ExpandedListTile<Promo>(
                            isSelected: _currentIndex == index,
                            titleBottomMargin: 1,
                            print: false,
                            trailingRightMargin: 5,
                            title: Text(item.promoCode),
                            subTitle: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: "${item.promoName}",
                                  )
                                ],
                              ),
                            ),
                            item: item,
                            onTap: (promo) {},
                            expandedWidget: ListView(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: false,
                              children: [
                                ListControlTile(
                                  selected: false,
                                  isTopSubtitle: false,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Term And Condition : ${item.termAndCondition}"),
                                      Text("Benefit : ${item.benefit}"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _refreshItems() async {
    final response = await HttpFramework.getData(
        "pos.list_sales_transaction_promo",
        body: {"keyword": keyword ?? ""});

    if (response != null) {
      List<Promo> transactions = Promo.responseToList(response);

      if (transactions == null) {
        return false;
      }

      if (!mounted) return false;

      setState(() {
        transactionList = transactions;
      });

      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _txtSearch.dispose();
    super.dispose();
  }
}

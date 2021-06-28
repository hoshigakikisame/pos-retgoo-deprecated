import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_desktop/models/response_core.dart';
import 'package:pos_desktop/models/transaction_history.dart';
import 'package:pos_desktop/widgets/base_control_dialog.dart';
import 'package:pos_desktop/widgets/expanded_list_tile.dart';
import 'package:pos_desktop/widgets/list_control_tile.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class TransactionPastDialog extends StatefulWidget {
  final String shiftId;
  TransactionPastDialog(this.shiftId, {Key key}) : super(key: key);

  @override
  _TransactionPastDialogState createState() => _TransactionPastDialogState();
}

class _TransactionPastDialogState extends State<TransactionPastDialog> {
  String keyword;

  String get shiftId => widget.shiftId;

  List<HistoryTransaction> transactionList = List();

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

          if (keyListen.logicalKey == LogicalKeyboardKey.arrowRight) {
            _showPrintPreview();
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
                  hintText: "type to search transaction",
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
                          child: ExpandedListTile<HistoryTransaction>(
                            isSelected: _currentIndex == index,
                            titleBottomMargin: 3,
                            trailingRightMargin: 5,
                            trailing: Text(item.amountTotal.toString()),
                            title: Text(item.customerName),
                            subTitle: RichText(
                              text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: "${item.employeeName}",
                                    )
                                  ]),
                            ),
                            item: item,
                            onTap: (item) {
                              _showPrint(item);
                            },
                            expandedWidget: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: false,
                              itemCount: item.transactionHistory.length,
                              itemBuilder: (context, position) {
                                final historyItem =
                                    item.transactionHistory.elementAt(position);
                                return ListControlTile(
                                  selected: false,
                                  isTopSubtitle: false,
                                  title: Text(historyItem.productName),
                                );
                              },
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
        "pos.list_sales_transaction_by_shift",
        body: {"keyword": keyword ?? "", "shift_id": shiftId});

    if (response != null) {
      List<HistoryTransaction> transactions =
          HistoryTransaction.responseToList(response);

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

  void _showPrintPreview() {
    if (transactionList == null || transactionList.length <= 0) {
      return;
    }

    HistoryTransaction transaction = transactionList[_currentIndex];

    _showPrint(transaction);
  }

  void _showPrint(HistoryTransaction transaction) async {
    if (transaction == null) {
      return;
    }

    if (transactionList == null || transactionList.length <= 0) {
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _txtSearch.dispose();
    super.dispose();
  }
}

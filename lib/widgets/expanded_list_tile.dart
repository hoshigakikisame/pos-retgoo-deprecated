import 'package:aiframework/protocol/http.dart';
import 'package:flutter/material.dart';
import 'package:pos_desktop/pages/print_page.dart';

typedef CallbackFunct<T> = void Function(T);

class ExpandedListTile<T> extends StatefulWidget {
  final T item;
  final Widget trailing;
  final double trailingRightMargin;
  final CallbackFunct<T> onTap;
  final IconData tapIcon;
  final bool isSelected;
  final bool print;
  final ListView expandedWidget;
  final Widget title;
  final double titleBottomMargin;
  final Widget subTitle;
  ExpandedListTile(
      {this.isSelected = false,
      this.print = true,
      this.titleBottomMargin,
      this.trailingRightMargin,
      this.tapIcon,
      this.title,
      this.subTitle,
      this.trailing,
      this.item,
      this.onTap,
      this.expandedWidget,
      Key key})
      : assert(item != null),
        assert(onTap != null),
        super(key: key);

  @override
  _ExpandedListTileState<T> createState() => _ExpandedListTileState();
}

class _ExpandedListTileState<T> extends State<ExpandedListTile> {
  T get item => widget.item as T;

  bool isExpanded;

  var widthPrint;

  CallbackFunct<T> get tapCallback => widget.onTap;
  ListView get expandedWidget => widget.expandedWidget;
  bool get isSelected => widget.isSelected;
  Widget get title => widget.title;
  Widget get subTitle => widget.subTitle;
  IconData get tapIcon => widget.tapIcon;
  double get titleBottomMargin => widget.titleBottomMargin;
  double get trailingRightMargin => widget.trailingRightMargin;
  Widget get trailing => widget.trailing;

  @override
  void initState() {
    super.initState();
    isExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      color: isSelected ? Colors.grey[300] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height:
              MediaQuery.of(context).size.height * (isExpanded ? 0.3 : 0.075),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: Row(children: <Widget>[
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        title ?? Container(),
                        SizedBox(
                          height: titleBottomMargin ?? 0,
                        ),
                        subTitle ?? Container()
                      ],
                    ),
                  )),
                  trailing ?? Container(),
                  SizedBox(
                    width: trailingRightMargin ?? 0,
                  ),
                  Row(
                    children: <Widget>[
                      if (widget.print)
                        IconButton(
                          icon: Icon(tapIcon ?? Icons.print),
                          onPressed: () {
                            _print();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                      ),
                    ],
                  )
                ]),
              ),
              isExpanded
                  ? Expanded(
                      child: Container(
                        color: Colors.grey,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: expandedWidget ?? Container(),
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  _print() async {
    final responseX = await Http.getData(endpoint: "print.get_print", data: {
      "sales_trx_id": widget.item.id,
      "print_width": widthPrint ?? 32
    });
    if (responseX != null) {
      var itemShow = await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) => WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, true);
            return;
          },
          child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              child: PrintPage(
                transactionId: widget.item.id,
                dataPrint: responseX["data"],
              )),
        ),
      );
      if (itemShow != null) {
        Navigator.pop(context, itemShow);
      }
      setState(() {});
    }
  }
}

// Stack(
//             overflow: Overflow.visible,
//             fit: StackFit.passthrough,
//             alignment: Alignment.topLeft,
//             children: <Widget>[
//               Positioned(
//                 child: Row(
//                   children: <Widget>[
//                     Expanded(
//                       child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: <Widget>[
//                             title ?? Container(),
//                             SizedBox(height: titleBottomMargin ?? 3),
//                             subTitle ?? Container()
//                           ]),
//                     ),
//                     Container(
//                       child: Row(
//                         children: <Widget>[
//                           IconButton(
//                             icon: Icon(tapIcon ?? Icons.print),
//                             onPressed: () {
//                               tapCallback(item);
//                             },
//                           ),
//                           IconButton(
//                             icon: Icon(isExpanded
//                                 ? Icons.expand_less
//                                 : Icons.expand_more),
//                             onPressed: () {
//                               setState(() {
//                                 this.isExpanded = !this.isExpanded;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Positioned(
//                 top: 100,
//                 child: isExpanded ? expandedWidget ?? Container() : Container(),
//               )
//               // isExpanded
//               //     ? Positioned(
//               //         top: 100,
//               //         child: expandedWidget ?? Container(),
//               //       )
//               //     : Container()
//             ],
//           ),

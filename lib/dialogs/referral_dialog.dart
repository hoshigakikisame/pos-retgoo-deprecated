import 'package:aiframework/aiframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ReferrarSelectionDialog extends StatefulWidget {
  final List list;
  const ReferrarSelectionDialog({Key key, this.list}) : super(key: key);
  @override
  _ReferrarSelectionDialogState createState() =>
      _ReferrarSelectionDialogState();
}

class _ReferrarSelectionDialogState extends State<ReferrarSelectionDialog> {
  final FocusNode focusNode = FocusNode();
  int _currentIndex = 0;
  final AutoScrollController _controller = AutoScrollController();

  bool isAllItem = false;
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      child: Container(
        height: 300,
        width: 300,
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12.0),
                icon: Icon(Icons.search),
                hintText: "search referrer",
              ),
              onChanged: (text) async {
                final response =
                    await Http.getData(endpoint: "pos.find_referral", data: {
                  "keyword": text,
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
            Container(
              height: 1.0,
              color: Theme.of(context).dividerColor,
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
                      child: ListTile(
                        selected: _currentIndex == position,
                        title: Text(item["employee_name"] ?? ""),
                        subtitle: Text(item["employee_code"] ?? ""),
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

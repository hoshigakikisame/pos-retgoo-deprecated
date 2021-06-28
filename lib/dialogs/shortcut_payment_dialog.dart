import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShortcutPaymentDialog extends StatefulWidget {
  @override
  _ShortcutPaymentDialogState createState() => _ShortcutPaymentDialogState();
}

class _ShortcutPaymentDialogState extends State<ShortcutPaymentDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      child: Material(
        type: MaterialType.card,
        borderRadius: BorderRadius.circular(5.0),
        clipBehavior: Clip.antiAlias,
        child: Container(
          margin: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Shortcut Information",
                style: Theme.of(context).textTheme.title.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).accentColor),
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.only(left: 16.0, bottom: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 0.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildShortcutInformation("Help", ":", "F8"),
                    _buildShortcutInformation("Other expenses", ":", "F9"),
                    _buildShortcutInformation("Non cash", ":", "F10"),
                    _buildShortcutInformation("Voucher", ":", "F11"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_buildShortcutInformation(String title, String separator, String shortcut) {
  return Container(
    padding: const EdgeInsets.all(2.0),
    width: 300,
    child: Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: FixedColumnWidth(70),
        1: FixedColumnWidth(5),
        2: FixedColumnWidth(10)
      },
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(fontSize: 14.0),
            ),
            Text(separator, style: TextStyle(fontSize: 14.0)),
            Container(
              height: 20.0,
              child: Center(
                child: Text(
                  shortcut,
                  style: TextStyle(fontSize: 14.0),
                ),
              ),
            )
          ],
        )
      ],
    ),
  );
}

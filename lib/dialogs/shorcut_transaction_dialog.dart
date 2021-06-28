import 'package:flutter/material.dart';
import 'package:pos_desktop/widgets/base_control_dialog.dart';

class ShortcutDialogTransaction extends StatefulWidget {
  @override
  _ShortcutDialogTransactionState createState() =>
      _ShortcutDialogTransactionState();
}

class _ShortcutDialogTransactionState extends State<ShortcutDialogTransaction> {
  @override
  Widget build(BuildContext context) {
    return BaseControlDialog(
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
                  _buildShortcutInformation("New cart", ":", "F1"),
                  _buildShortcutInformation("Previous cart", ":", "F2"),
                  _buildShortcutInformation("Next cart", ":", "F3"),
                  _buildShortcutInformation("Checkout cart", ":", "F4"),
                  _buildShortcutInformation("Cancel cart", ":", "F5"),
                  _buildShortcutInformation("Focus last row", ":", "F12"),
                  _buildShortcutInformation("Customer", ":", "Home"),
                  _buildShortcutInformation("Referral", ":", "End"),
                  _buildShortcutInformation("Skip SPG", ":", "Ctrl + -->"),
                  _buildShortcutInformation(" ", " ", " "),
                ],
              ),
            ),
          ],
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

import 'package:flutter/material.dart';

class FormTileBox extends StatelessWidget {
  final Widget inputter;
  final String label;
  const FormTileBox({this.label, this.inputter, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Text(
            label ?? "",
            style: Theme.of(context)
                .textTheme
                .subhead
                .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
              padding: EdgeInsets.all(0),
              width: MediaQuery.of(context).size.width * 0.3,
              child: inputter),
        ),
        SizedBox(
          width: 5,
        )
      ],
    );
  }
}

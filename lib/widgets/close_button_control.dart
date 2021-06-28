import 'package:flutter/material.dart';

class CloseButtonControl extends StatelessWidget {
  final VoidCallback onPressed;
  const CloseButtonControl({this.onPressed, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OutlineButton.icon(
          icon: Icon(
            Icons.cancel,
            color: Colors.lightBlue,
          ),
          label: Text(
            "Close",
            style: Theme.of(context)
                .textTheme
                .button
                .copyWith(color: Colors.lightBlue),
          ),
          borderSide: BorderSide(color: Colors.lightBlue),
          highlightedBorderColor: Colors.lightBlue,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

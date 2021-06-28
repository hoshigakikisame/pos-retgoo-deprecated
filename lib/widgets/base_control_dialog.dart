import 'package:flutter/material.dart';

class BaseControlDialog extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final double dialogWidth;
  final double dialogHeight;
  final bool isUsingDefaultContainer;
  final EdgeInsetsGeometry contentPadding;
  const BaseControlDialog(
      {this.dialogWidth,
      this.dialogHeight,
      this.borderRadius,
      this.isUsingDefaultContainer = false,
      this.child,
      this.contentPadding,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(5.0)),
      child: Material(
          type: MaterialType.card,
          borderRadius: borderRadius ?? BorderRadius.circular(5.0),
          clipBehavior: Clip.antiAlias,
          child: isUsingDefaultContainer
              ? Container(
                  height:
                      dialogHeight ?? MediaQuery.of(context).size.height * 0.9,
                  width: dialogWidth ?? MediaQuery.of(context).size.width * 0.4,
                  child: child,
                  padding: contentPadding ?? const EdgeInsets.all(16),
                )
              : child),
    );
  }
}

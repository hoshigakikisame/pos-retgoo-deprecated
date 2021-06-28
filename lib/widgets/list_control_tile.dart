import 'package:flutter/material.dart';

class ListControlTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTopSubtitle;
  final bool selected;
  final Widget title;
  final Widget subTitle;
  final Widget trailing;
  final double containerSpace;
  const ListControlTile(
      {this.isTopSubtitle = false,
      this.containerSpace,
      this.selected,
      this.onTap,
      this.title,
      this.subTitle,
      this.trailing,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Material(
        type: MaterialType.card,
        color: selected ? Colors.grey[300] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isTopSubtitle
                ? <Widget>[
                    subTitle ?? Container(),
                    SizedBox(
                      height: containerSpace ?? 0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        title ?? Container(),
                        trailing ?? Container()
                      ],
                    )
                  ]
                : <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        title ?? Container(),
                        trailing ?? Container()
                      ],
                    ),
                    SizedBox(
                      height: containerSpace ?? 0,
                    ),
                    subTitle ?? Container(),
                  ],
          ),
          // child: Builder(builder: (context) {
          //   if (isTopSubtitle) {
          //     return Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: <Widget>[
          //           subTitle,
          //           SizedBox(
          //             height: containerSpace ?? 0,
          //           ),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: <Widget>[title, trailing],
          //           )
          //         ]);
          //   } else {
          //     return Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: <Widget>[
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: <Widget>[title, trailing],
          //           ),
          //           SizedBox(
          //             height: containerSpace ?? 0,
          //           ),
          //           subTitle,
          //         ]);
          //   }
          // }),
        ),
      ),
      onTap: onTap ?? null,
    );
  }
}

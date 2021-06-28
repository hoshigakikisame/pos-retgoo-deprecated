import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_desktop/widgets/text_form_field.dart';

typedef dynamic DataGridColumnValueCallback(int row);
typedef Future<bool> DataGridColumnSubmited(
    DataGridViewState state, dynamic value, Map<String, dynamic> rowData);
typedef OnFocusChange(bool hasFocus);
typedef Widget CellBuilder(
    BuildContext context, int row, int column, dynamic rowData);

enum DataGridColumnType {
  text,
  date,
  datetime,
  time,
  numberInteger,
  numberDouble,
  boolean,
}

class DataGridColumn {
  final String field;
  final String valueField;
  final String header;
  final CellBuilder builder;
  final bool readOnly;
  final DataGridColumnValueCallback onGetValue;
  final TextStyle style;
  final TextAlign textAlign;
  final double width;
  final DataGridColumnSubmited onSubmitted;
  final OnFocusChange onFocusChange;
  final String displayFormat;
  final DataGridColumnType columnType;
  final Widget prefix;
  final Widget suffix;
  final List<TextInputFormatter> inputFormaters;
  final bool autoFocusable;

  DataGridColumn({
    this.field,
    this.valueField,
    this.header,
    this.builder,
    this.readOnly = false,
    this.onGetValue,
    this.style,
    this.textAlign,
    this.width = 0,
    this.onSubmitted,
    this.onFocusChange,
    this.displayFormat,
    this.columnType = DataGridColumnType.text,
    this.prefix,
    this.suffix,
    this.inputFormaters,
    this.autoFocusable = true,
  });
}

class DataGridView extends StatefulWidget {
  final bool readOnly;
  final List<DataGridColumn> columns;
  final List<Map<String, dynamic>> dataSource;
  final double elevation;
  final Widget header;
  final Widget footer;
  final Color hightlightBackgroundColor;

  DataGridView({
    GlobalKey key,
    this.columns,
    this.readOnly = false,
    this.dataSource,
    this.elevation = 4.0,
    this.footer,
    this.header,
    this.hightlightBackgroundColor,
  }) : super(key: key);

  @override
  DataGridViewState createState() => DataGridViewState();

  static DataGridViewState of(BuildContext context, [bool rootWidget = true]) {
    final DataGridViewState lastState = rootWidget
        ? context
            .rootAncestorStateOfType(const TypeMatcher<DataGridViewState>())
        : context.ancestorStateOfType(const TypeMatcher<DataGridViewState>());

    if (lastState == null) {
      // print("State Is Null");
      return null;
    }

    return lastState;
  }
}

class DataGridViewState extends State<DataGridView> {
  final ScrollController _scrollController = ScrollController();

  Map<int, TableColumnWidth> get _columnWidth {
    final Map<int, TableColumnWidth> result = {};
    widget.columns.forEach((column) {
      if (column.width > 0) {
        result.putIfAbsent(
          widget.columns.indexOf(column),
          () {
            return column.width > 0 ? FixedColumnWidth(column.width) : null;
          },
        );
      }
    });

    return result;
  }

  TableRow _generateColumns(BuildContext context) {
    TableRow result = TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
      ),
      children: widget.columns.map<Widget>((column) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            column.header,
            style: Theme.of(context).textTheme.body2,
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );

    return result;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final columnWidth = _columnWidth;
    return Material(
      elevation: widget.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      shadowColor: Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          widget.header ?? Container(),
          Expanded(
            child: LayoutBuilder(builder: (context, constraint) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  SizedBox(
                    width: constraint.maxWidth,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          top: 34,
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: DraggableScrollbar.semicircle(
                            controller: _scrollController,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(
                                0.0,
                              ),
                              controller: _scrollController,
                              itemCount: widget.dataSource != null
                                  ? widget.dataSource.length
                                  : 1,
                              itemBuilder: (context, position) {
                                bool isOdd = position % 2 > 0;
                                Color normalColor = isOdd
                                    ? (Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey.shade200
                                        : Colors.white.withOpacity(0.05))
                                    : null;

                                return Column(
                                  children: <Widget>[
                                    Container(
                                      color: focussedRow == position
                                          ? widget.hightlightBackgroundColor ??
                                              normalColor
                                          : normalColor,
                                      child: Table(
                                        columnWidths: columnWidth,
                                        border: TableBorder.symmetric(
                                          inside: BorderSide(
                                            width: 1.0,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade800,
                                          ),
                                        ),
                                        children: <TableRow>[
                                          _generateNewInputRow(
                                              context, position),
                                        ],
                                      ),
                                    ),
                                    position ==
                                            (widget.dataSource != null
                                                    ? widget.dataSource.length
                                                    : 1) -
                                                1
                                        ? Container(
                                            height: 1.0,
                                            color:
                                                Theme.of(context).dividerColor,
                                          )
                                        : Container(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        Material(
                          elevation:
                              widget.elevation != null && widget.elevation > 2
                                  ? widget.elevation - 2
                                  : 1.0,
                          shadowColor: Colors.grey.shade100,
                          child: Table(
                            columnWidths: _columnWidth,
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            border: TableBorder.symmetric(
                              inside: BorderSide(
                                width: 1.0,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                            children: <TableRow>[
                              _generateColumns(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
          widget.footer ?? Container(),
        ],
      ),
    );
  }

  int _focussedRow = 0;
  int _focussedColumn = 0;

  int get focussedRow => _focussedRow;
  int get focussedColumn => _focussedColumn;

  set focussedRow(int value) {
    if (_focussedRow == value) {
      return;
    }

    setState(() {
      _focussedRow = value;
    });
  }

  set focussedColumn(int value) {
    if (_focussedColumn == value) {
      return;
    }

    setState(() {
      _focussedColumn = value;
    });
  }

  focusToRowField(int row, String fieldName) {
    if (widget.dataSource.isNotEmpty) {
      if (row >= 0 && row < widget.dataSource.length) {
        _focussedRow = row;
        for (int i = 0; i < widget.columns.length; i++) {
          DataGridColumn nextColumn = widget.columns[i];
          if (nextColumn.field == fieldName) {
            _focussedColumn = i;
            focusToCell(_focussedRow, _focussedColumn);
          }
        }
      }
    }
  }

  getSelectedRowData() {
    if (_focussedRow >= 0 && _focussedRow < widget.dataSource.length) {
      return widget.dataSource.elementAt(_focussedRow);
    }

    return null;
  }

  focusToCell(int row, int column) {
    // setState(() {
    //   if (row >= widget.dataSource.length) {
    //     row = widget.dataSource.length - 1;
    //   }

    //   _focussedRow = row;
    //   _focussedColumn = column;
    // });
    // return;

    setState(() {
      _focussedRow = null;
      _focussedColumn = null;

      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          if (row >= widget.dataSource.length) {
            row = widget.dataSource.length - 1;
          }

          _focussedRow = row;
          _focussedColumn = column;
        });
      });
    });
  }

  focusToPreviosRow() {
    if (_focussedRow > 0) {
      _focussedRow -= 1;
      focusToCell(_focussedRow, _focussedColumn);
    }
  }

  focusToLastRowFirstColumn() {
    _focussedRow = widget.dataSource.length - 1;
    for (int i = 0; i < widget.columns.length; i++) {
      DataGridColumn nextColumn = widget.columns[i];
      if (!nextColumn.readOnly) {
        _focussedColumn = i;
        focusToCell(_focussedRow, _focussedColumn);
        return;
      }
    }
  }

  focusToNextRow() {
    if (_focussedRow < widget.dataSource.length - 1) {
      _focussedRow += 1;
      focusToCell(_focussedRow, _focussedColumn);
    }
  }

  void focusToPreviousColumn() {
    for (int i = _focussedColumn - 1; i >= 0; i--) {
      DataGridColumn nextColum = widget.columns[i];
      if (!nextColum.readOnly) {
        _focussedColumn = widget.columns.indexOf(nextColum);
        focusToCell(_focussedRow, _focussedColumn);
        return;
      }
    }

    if (_focussedRow > 0) {
      setState(() {
        _focussedRow -= 1;
        _focussedColumn = widget.columns.length - 1;

        Future.delayed(Duration(milliseconds: 100), () {
          focusToPreviousColumn();
        });
      });

      return;
    }
  }

  void reFocus() {
    focusToCell(_focussedRow, _focussedColumn);
  }

  void focusToNextColumn() {
    if (_focussedColumn == null) {
      _focussedColumn = 0;
    }

    if (_focussedRow == null) {
      _focussedRow = 0;
    }

    if (_focussedColumn + 1 < widget.columns.length - 1) {
      for (int i = _focussedColumn + 1; i < widget.columns.length; i++) {
        DataGridColumn nextColum = widget.columns[i];
        if (!nextColum.readOnly && nextColum.autoFocusable) {
          _focussedColumn = widget.columns.indexOf(nextColum);
          focusToCell(_focussedRow, _focussedColumn);
          return;
        }
      }
    }

    if (_focussedRow < widget.dataSource.length - 1) {
      setState(() {
        _focussedRow += 1;
        _focussedColumn = 0;

        Future.delayed(Duration(milliseconds: 100), () {
          focusToNextColumn();
        });
      });

      return;
    }

    if (_focussedRow == widget.dataSource.length - 1) {
      setState(() {
        widget.dataSource.add({});
        _focussedRow += 1;
        _focussedColumn = 0;

        Future.delayed(Duration(milliseconds: 100), () {
          focusToNextColumn();
        });
      });
    }
  }

  void toNextColumn() {
    if (_focussedColumn == null) {
      _focussedColumn = 0;
    }

    if (_focussedRow == null) {
      _focussedRow = 0;
    }

    if (_focussedColumn + 1 < widget.columns.length - 1) {
      for (int i = _focussedColumn + 1; i < widget.columns.length; i++) {
        DataGridColumn nextColum = widget.columns[i];
        if (!nextColum.readOnly) {
          _focussedColumn = widget.columns.indexOf(nextColum);
          focusToCell(_focussedRow, _focussedColumn);
          return;
        }
      }
    }

    if (_focussedRow < widget.dataSource.length - 1) {
      setState(() {
        _focussedRow += 1;
        _focussedColumn = 0;

        Future.delayed(Duration(milliseconds: 100), () {
          toNextColumn();
        });
      });

      return;
    }

    if (_focussedRow == widget.dataSource.length - 1) {
      setState(() {
        widget.dataSource.add({});
        _focussedRow += 1;
        _focussedColumn = 0;

        Future.delayed(Duration(milliseconds: 100), () {
          toNextColumn();
        });
      });
    }
  }

  TableRow _generateNewInputRow(BuildContext context, int rowIndex) {
    return DataGridViewRow.fromColumns(
      columns: widget.columns,
      context: context,
      rowIndex: rowIndex,
      readOnly: widget.readOnly,
      rowData: widget.dataSource != null ? widget.dataSource[rowIndex] : null,
      textEditingController: TextEditingController(),
    );
  }

  refreshState(VoidCallback fn) {
    setState(() {
      fn();
    });
  }
}

class DataGridViewRow extends TableRow {
  final List<DataGridColumn> columns;
  final Decoration decoration;
  final LocalKey key;
  final List<Widget> children;
  final Map<String, dynamic> rowData;

  DataGridViewRow({
    this.key,
    this.decoration,
    this.children,
    this.columns,
    this.rowData,
  }) : super(
          key: key,
          decoration: decoration,
          children: children,
        );

  factory DataGridViewRow.fromColumns({
    BuildContext context,
    bool readOnly = false,
    List<DataGridColumn> columns,
    Decoration decoration,
    LocalKey key,
    int rowIndex,
    Map<String, dynamic> rowData,
    TextEditingController textEditingController,
  }) {
    final List<Widget> chidren = columns.map((column) {
      DataGridViewState gridViewState = DataGridView.of(context);

      int focussedColumn = gridViewState._focussedColumn;
      int focussedRow = gridViewState._focussedRow;

      int currentColumnIndex = columns.indexOf(column);
      int currentRowIndex = rowIndex;

      bool isFocussed = (focussedColumn == currentColumnIndex) &&
          (focussedRow == currentRowIndex);

      const EdgeInsets edgeInsets = const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        top: 8.0,
        bottom: 8.0,
      );

      InputDecoration inputDecoration = InputDecoration(
        border: InputBorder.none,
        contentPadding: edgeInsets,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2.0,
          ),
        ),
      );

      dynamic dataValue = column.onGetValue != null
          ? column.onGetValue(rowIndex)
          : (rowData != null ? (rowData[column.field] ?? "") : "");

      if (dataValue != null) {
        switch (column.columnType) {
          case DataGridColumnType.text:
            break;

          case DataGridColumnType.numberDouble:
            if (column.displayFormat != null) {
              dataValue = NumberFormat(column.displayFormat).format(
                double.tryParse(
                        dataValue != null ? dataValue.toString() : "0.0") ??
                    0.0,
              );
            } else {
              dataValue = dataValue.toString();
            }
            break;
          default:
        }
      }

      GlobalKey<TextFormFieldState> key = GlobalKey();
      Widget editor = column.builder != null
          ? column.builder(context, currentRowIndex, currentColumnIndex,
              gridViewState.widget.dataSource[currentRowIndex])
          : (readOnly || column.readOnly || !isFocussed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    column.prefix ?? Container(),
                    Expanded(
                      child: Padding(
                        padding: edgeInsets,
                        child: Text(
                          dataValue,
                          style:
                              column.style ?? Theme.of(context).textTheme.body1,
                          textAlign: column.textAlign ?? TextAlign.start,
                        ),
                      ),
                    ),
                    column.suffix ?? Container(),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      column.prefix ?? Container(),
                      Expanded(
                        child: TextFormFieldX(
                          key: key,
                          autofocus: true,
                          initialValue: dataValue,
                          inputFormatters: column.inputFormaters,
                          onFieldSubmitted: (value) async {
                            //final value = key.currentState.text;
                            if (rowData != null && column.field != null) {
                              rowData[column.field] = value;
                            }

                            //gridViewState.refreshState(() {});
                            //gridViewState.reFocus();

                            try {
                              if (column.onSubmitted != null) {
                                final gotoNext = await column.onSubmitted(
                                    gridViewState, value, rowData);
                                gridViewState.refreshState(() {
                                  if (gotoNext) {
                                    gridViewState.focusToNextColumn();
                                    Future.delayed(Duration(milliseconds: 300),
                                        () {
                                      gridViewState._scrollController.animateTo(
                                        gridViewState._scrollController.position
                                            .maxScrollExtent,
                                        curve: Curves.easeOut,
                                        duration:
                                            const Duration(milliseconds: 300),
                                      );
                                    });
                                    // gridViewState._scrollController.jumpTo(500);
                                  } else {
                                    gridViewState.reFocus();
                                  }
                                });
                              } else {
                                gridViewState.focusToNextColumn();
                              }
                            } catch (e) {}
                          },
                          //focusNode: _focusNode,
                          decoration: inputDecoration,
                          style:
                              column.style ?? Theme.of(context).textTheme.body1,
                          textAlign: column.textAlign ?? TextAlign.start,
                          textInputAction: TextInputAction.go,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      column.suffix ?? Container(),
                    ],
                  ),
                ));

      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Container(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 40),
            child: InkWell(
              onTap: () {
                gridViewState.focusToCell(currentRowIndex, currentColumnIndex);
              },
              child: editor,
            ),
          ),
        ),
      );
    }).toList();

    return DataGridViewRow(
      columns: columns,
      key: key,
      decoration: decoration,
      children: chidren,
    );
  }
}

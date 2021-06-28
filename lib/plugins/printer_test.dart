import 'package:flutter/material.dart';
import 'package:pos_desktop/plugins/printers.dart';

class PrinterTestPage extends StatefulWidget {
  @override
  _PrinterTestPageState createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  @override
  void initState() {
    super.initState();
    getPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Printer Test"),
      ),
      body: Container(),
    );
  }

  getPrinters() async {
    final printers = await Printer.getPrinters();
    print(printers);

    PrinterDocument("Struk")
      ..addText("Hello World")
      ..addText("Ini adalah percobaan print")
      ..addText("Pake Flutter")
      ..addFeed()
      ..addFeed()
      ..cutPaper()
      ..finish()
      ..print("POS58");
  }
}

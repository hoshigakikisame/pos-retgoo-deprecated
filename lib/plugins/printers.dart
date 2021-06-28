import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Printer {
  static final platform =
      MethodChannel("id.retgoo.flutter/printer", JSONMethodCodec());

  static getPrinters() async {
    return (await platform.invokeMapMethod("getPrinters"))["printers"];
  }

  static print(
      String printerName, String jobName, PrinterDocument document) async {
    await platform.invokeMethod("print", {
      "printer": printerName,
      "job": jobName ?? "Receipt",
      "payload": document.getPayload(),
    });
  }
}

class PrinterCommands {
  static final Uint8List CUT = Uint8List.fromList([0x1B, 0x69]);
  static final Uint8List INIT = Uint8List.fromList([0x1B, 0x40]);
  static final Uint8List END = Uint8List.fromList([0x10, 'J'.codeUnitAt(0)]);
  static final Uint8List HT = Uint8List.fromList([0x9]);
  static final Uint8List LF = Uint8List.fromList([0x0A]);
  static final Uint8List CR = Uint8List.fromList([0x0D]);
  static final Uint8List ESC = Uint8List.fromList([0x1B]);
  static final Uint8List DLE = Uint8List.fromList([0x10]);
  static final Uint8List GS = Uint8List.fromList([0x1D]);
  static final Uint8List FS = Uint8List.fromList([0x1C]);
  static final Uint8List STX = Uint8List.fromList([0x02]);
  static final Uint8List US = Uint8List.fromList([0x1F]);
  static final Uint8List CAN = Uint8List.fromList([0x18]);
  static final Uint8List CLR = Uint8List.fromList([0x0C]);
  static final Uint8List EOT = Uint8List.fromList([0x04]);
  static final Uint8List PAGE_MODE = Uint8List.fromList([27, 76]);
  static final Uint8List STANDARD_MODE = Uint8List.fromList([27, 83]);
  static final Uint8List FEED_LINE = Uint8List.fromList([10]);
  static final Uint8List ESC_ALIGN_LEFT =
      Uint8List.fromList([0x1B, "a".codeUnitAt(0), 0x00]);
  static final Uint8List ESC_ALIGN_RIGHT =
      Uint8List.fromList([0x1B, "a".codeUnitAt(0), 0x02]);
  static final Uint8List ESC_ALIGN_CENTER =
      Uint8List.fromList([0x1B, "A".codeUnitAt(0), 0x02]);
  static final Uint8List NORMAL = Uint8List.fromList([0x1B, 0x21, 0x00]);
  static final Uint8List BOLD = Uint8List.fromList([0x1B, 0x21, 0x08]);
  static final Uint8List BOLD_MEDIUM = Uint8List.fromList([0x1B, 0x21, 0x20]);
  static final Uint8List BOLD_LARGE = Uint8List.fromList([0x1B, 0x21, 0x10]);
}

class PrinterDocument {
  final String name;
  PrinterDocument(this.name) {
    payload.addAll(PrinterCommands.INIT);
    payload.addAll(PrinterCommands.STANDARD_MODE);
  }

  List<int> payload = [];
  bool isFinish = false;

  addLogo(List<int> bytes) {
    payload.addAll(bytes);
  }

  addText(String text) {
    if (!text.endsWith("\n")) {
      text += "\n";
    }

    payload.addAll(ascii.encode(text));
  }

  addTab() {
    payload.addAll(PrinterCommands.HT);
  }

  addFeed() {
    payload.addAll(PrinterCommands.FEED_LINE);
  }

  setAlignLeft() {
    payload.addAll(PrinterCommands.ESC_ALIGN_LEFT);
  }

  setAlignCenter() {
    payload.addAll(PrinterCommands.ESC_ALIGN_CENTER);
  }

  setAlignRight() {
    payload.addAll(PrinterCommands.ESC_ALIGN_RIGHT);
  }

  setNormal() {
    payload.addAll(PrinterCommands.NORMAL);
  }

  setBold() {
    payload.addAll(PrinterCommands.BOLD);
  }

  setBoldMedium() {
    payload.addAll(PrinterCommands.BOLD_MEDIUM);
  }

  setBoldLarge() {
    payload.addAll(PrinterCommands.BOLD_LARGE);
  }

  cutPaper() {
    payload.addAll(PrinterCommands.CUT);
  }

  finish() {
    payload.addAll(PrinterCommands.END);
  }

  getPayload() {
    return base64.encode(payload);
  }

  print(String printerName) {
    Printer.print(printerName, name, this);
  }
}

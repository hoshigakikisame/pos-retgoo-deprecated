import 'package:pos_desktop/models/response_core.dart';

class HistoryTransaction {
  String id;
  double amountTotal;
  String customerName;
  String employeeName;
  bool isExpanded;
  List<HistoryTransactionItem> transactionHistory;

  HistoryTransaction(
      {this.id,
      this.amountTotal,
      this.customerName,
      this.employeeName,
      this.isExpanded,
      this.transactionHistory});

  factory HistoryTransaction.fromJson(Map<String, dynamic> json) {
    return HistoryTransaction(
        id: json["id"] ?? null,
        isExpanded: false,
        customerName: json["customer_name"] ?? null,
        amountTotal: json["amount_total"] ?? 0.0,
        employeeName: json["employee_name"] ?? null,
        transactionHistory: json["sales_transaction_detail"] == null
            ? null
            : new List<HistoryTransactionItem>.from(
                json["sales_transaction_detail"]
                    .map((x) => HistoryTransactionItem.fromJson(x))));
  }

  static List<HistoryTransaction> responseToList(Response response) {
    return response.data == null
        ? null
        : new List<HistoryTransaction>.from(response
            .dataToList()
            .map((item) => HistoryTransaction.fromJson(item)));
  }
}

class HistoryTransactionItem {
  double amountTotal;
  double discPercent;
  String productCode;
  String productName;
  String productQrCode;
  double qty;
  double unitPrice;
  String uomName;

  HistoryTransactionItem(
      {this.amountTotal,
      this.discPercent,
      this.productCode,
      this.productName,
      this.productQrCode,
      this.qty,
      this.unitPrice,
      this.uomName});

  factory HistoryTransactionItem.fromJson(Map<String, dynamic> json) {
    return HistoryTransactionItem(
        amountTotal: json["amount_total"] ?? 0.0,
        discPercent: json["disc_percent"] ?? 0.0,
        productCode: json["product_code"] ?? "-",
        productName: json["product_name"] ?? "-",
        productQrCode: json["product_qrcode"] ?? "-",
        qty: json["qty"] ?? 0.0,
        unitPrice: json["unit_price"] ?? 0.0,
        uomName: json["uom_name"] ?? "-");
  }
}

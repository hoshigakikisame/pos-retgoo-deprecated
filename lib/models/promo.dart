import 'response_core.dart';

class Promo {
  String id;
  String benefit;
  String promoCode;
  String promoName;
  String termAndCondition;
  bool isExpanded;

  Promo({
    this.id,
    this.benefit,
    this.promoCode,
    this.promoName,
    this.termAndCondition,
    this.isExpanded,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json["id"] ?? null,
      isExpanded: false,
      benefit: json["benefit"] ?? null,
      promoCode: json["promo_code"] ?? null,
      promoName: json["promo_name"] ?? null,
      termAndCondition: json["term_and_condition"] ?? null,
    );
  }

  static List<Promo> responseToList(Response response) {
    return response.data == null
        ? null
        : new List<Promo>.from(
            response.dataToList().map((item) => Promo.fromJson(item)));
  }
}

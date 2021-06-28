import 'package:aiframework/aiframework.dart';

class Response {
  final bool success;
  final dynamic data;

  Response(this.success, this.data);

  factory Response.fromJson(Map<String, dynamic> data) {
    return Response(data["success"] ?? false, data["data"] ?? null);
  }

  Map dataToMap() {
    if (data == null) {
      return null;
    }

    if (data is Map) {
      return data as Map;
    }

    return null;
  }

  List dataToList() {
    if (data == null) {
      return null;
    }

    if (data is List) {
      return data as List;
    }

    return null;
  }

  String dataToString() {
    if (data == null) {
      return null;
    }

    if (data is String) {
      return data as String;
    }

    return "";
  }

  Map<String, dynamic> toMap() {
    return {"success": success, "data": data};
  }
}

class HttpFramework {
  static Future<Response> getData(String endpoint, {dynamic body}) async {
    try {
      final response = await Http.getData(endpoint: endpoint, data: body);

      if (response == null) {
        return null;
      }

      return Response.fromJson(response);
    } catch (e) {
      print(e);
    }

    return null;
  }
}

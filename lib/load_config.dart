import 'dart:convert';

import 'package:aiframework/aiframework.dart';
import 'package:shared_preferences/shared_preferences.dart';

loadConfigs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('settings')) {
    String conf = prefs.getString("settings");
    Map<String, dynamic> configJson = json.decode(conf);

    Http.baseURL = "http://${configJson["host"]}:${configJson["port"]}/api/pg/";
  }
}

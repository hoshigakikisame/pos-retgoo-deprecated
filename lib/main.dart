import 'package:flutter/material.dart';
import 'package:pos_desktop/load_config.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadConfigs();
  runApp(new MyApp());
}

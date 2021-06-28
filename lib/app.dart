import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_desktop/pages/login_page.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'RetGoo - Point Of Sales ',
      theme: ThemeData(
        fontFamily: "Quicksand",
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        cardTheme: CardTheme(
          clipBehavior: Clip.antiAlias,
        ),
        textTheme: TextTheme(
          title: TextStyle(
            color: Color(0xFF333333),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      // home: PrinterTestPage()
    );
  }
}

import 'package:flutter/material.dart';

import 'package:stocktrak/pages/homepage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: Colors.black,
        accentColor: Colors.blue,
        accentColorBrightness: Brightness.light,
        primaryColor: Colors.green,
        bottomAppBarColor: Color.fromARGB(255, 32, 32, 32),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.black,
        ),

        textTheme: TextTheme(
          headline3: TextStyle(
            fontFamily: "Museo-Moderno",
            fontWeight: FontWeight.bold,
						color: Colors.white,
          ),
        ),

        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

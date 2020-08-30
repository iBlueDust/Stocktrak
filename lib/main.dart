import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stocktrak/pages/homepage.dart';
import 'package:stocktrak/pages/newtransactionpage.dart';
import 'package:stocktrak/store/stock_manager.dart';
import 'package:stocktrak/store/transaction_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StockManager()..initialize(),
      child: ChangeNotifierProvider(
        create: (_) => TransactionManager()..initialize(),
        child: MaterialApp(
          title: 'Stocktrak',
          theme: ThemeData(
            brightness: Brightness.dark,
            backgroundColor: Colors.black,
            accentColor: Colors.blue,
            accentColorBrightness: Brightness.light,
            primaryColor: Colors.green,
            bottomAppBarColor: const Color.fromARGB(255, 64, 64, 64),

            buttonColor: const Color.fromARGB(255, 64, 64, 64),
            buttonTheme: ButtonThemeData(
              buttonColor: const Color.fromARGB(255, 64, 64, 64),
            ),

            cardColor: const Color.fromARGB(255, 64, 64, 64),

            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.black,
            ),

            textTheme: TextTheme(
              headline3: TextStyle(
                fontFamily: "Museo-Moderno",
                fontWeight: FontWeight.bold,
                height: 1.15,
                color: Colors.white,
              ),
            ),

            // This makes the visual density adapt to the platform that you run
            // the app on. For desktop platforms, the controls will be smaller and
            // closer together (more dense) than on mobile platforms.
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => HomePage(),
            '/new-transaction': (context) => NewTransactionPage(),
          },
        ),
      ),
    );
  }
}

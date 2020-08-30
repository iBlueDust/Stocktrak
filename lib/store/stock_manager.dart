import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrak/utils/daily_stock.dart';
import 'package:stocktrak/utils/money.dart';

const RETRY_INTERVAL = Duration(minutes: 1);
const TIMEOUT = kDebugMode ? Duration(minutes: 3) : Duration(seconds: 30);
const MAX_ATTEMPTS = 30;

class StockManager extends ChangeNotifier {
  // static const PK_COMPANIES = 'companies';
  static const PK_DAILY_STOCKS = 'daily-stocks';
  static const PK_DAILY_STOCKS_DATE = 'daily-stocks/date';

  static const COMPANY_DELIM = '\n';

  SharedPreferences _prefs;

  Map<String, DailyStock> dailyStocks;
  DateTime dailyStocksDate;
  // Map<String, String> companies;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      await decacheDailyStocks().timeout(TIMEOUT);
    } catch (_) {/* ignore */}

    print("Fetching Daily Stocks Data");
    if (dailyStocks == null) {
      await fetchStocks();
    }
    notifyListeners();
  }

  Future<void> fetchStocks() async {
    try {
      await fetchDailyStocks().timeout(TIMEOUT);
    } catch (error) {
      if (kDebugMode) print(error);
    }
    notifyListeners();

    if (dailyStocks == null)
      throw Exception("No Daily Stocks found");
    else
      cacheDailyStocks(); // Don't await
  }

  Future<void> cacheDailyStocks() {
    return Future.wait([
      _prefs.setString(
        PK_DAILY_STOCKS,
        json.encode(
          dailyStocks.values.map((d) => d.toJson()).toList(),
        ),
      ),
      if (dailyStocksDate != null)
        _prefs.setString(PK_DAILY_STOCKS_DATE, dailyStocksDate.toIso8601String().substring(0, 10)),
    ]);
  }

  Future<void> decacheDailyStocks() async {
    try {
      final DateTime date = DateTime.parse(json.decode(_prefs.getString(PK_DAILY_STOCKS_DATE)));

      var now = DateTime.now();
      now = DateTime(now.year, now.month, now.day);

      if (date.isAtSameMomentAs(now)) {
        dailyStocks = decodeDailyStocks(_prefs.getString(PK_DAILY_STOCKS));
      } else {
        throw TimeoutException('Fetch Daily Stocks found outdated daily stocks data in cache');
      }
    } catch (error) {
      if (kDebugMode) print('Fetch Daily Stocks failed to find cache in SharedPreferences');
      throw error;
    }
  }

  Future<void> fetchDailyStocks() async {
    var date = DateTime.now();

    for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
      final uri = Uri.parse(
          'https://idx.co.id/umbraco/Surface/TradingSummary/GetStockSummary?date=${date.toIso8601String().substring(0, 10)}&length=10000');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        dailyStocks = decodeDailyStocks(response.body);

        if (dailyStocks.length > 0) break;
      } else {
        final error = HttpException(
            'Fetch Daily Stocks encountered a HTTP error ${response.statusCode}: ${response.reasonPhrase}');

        if (kDebugMode) print(error);

        throw error;
      }

      date = date.subtract(Duration(days: 1));
    }

    dailyStocksDate = DateTime(date.year, date.month, date.day);
  }

  Map<String, DailyStock> decodeDailyStocks(String jsonString) {
    final stocks = json.decode(jsonString);
    return Map.fromIterable(stocks['data'], key: (s) => s['StockCode'], value: (s) => DailyStock.fromJson(s));
  }

  Money stockPrice(String code) {
    return dailyStocks == null || dailyStocks[code] == null ? null : Money.fromDouble(dailyStocks[code].close);
  }
}

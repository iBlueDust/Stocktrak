import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' as Sembast;
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrak/utils/owned_stock.dart';
import 'package:stocktrak/utils/transaction.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionManager extends ChangeNotifier {
  static const DB_VERSION = 0;
  static const DB_FILENAME = "transactions.db";
  static const PK_OWNED_STOCKS = 'owned-stocks';

  SharedPreferences _pref;
  Sembast.Database db;
  Sembast.StoreRef store = Sembast.StoreRef.main();

  Future<void> _init;

  Future<void> initialize() => _init = _initialize();

  Future<void> _initialize() async {
    _pref = await SharedPreferences.getInstance();

    if (await Permission.storage.request().isGranted) {
      final appDir = await getApplicationDocumentsDirectory();
      await appDir.create(recursive: true);
      final filePath = path.join(appDir.path, DB_FILENAME);
      db = await databaseFactoryIo.openDatabase(filePath, version: DB_VERSION);

      await _fetchTransactions();
      print('Transactions retrieved');

      print('Sembast DB initialized');

      notifyListeners();
    } else if (kDebugMode) print("Storage permissions denied");

    try {
      await _decacheOwnedStocks();
    } catch (_) {
      print("Owned Stocks not found in SharedPreferences");
      await _calculateOwnedStocks();
      await _cacheOwnedStocks();
    }
  }

  List<Transaction> transactions;
  Map<String, OwnedStock> ownedStocks;

  Future<void> _fetchTransactions() async {
    final records = await store.find(db,
        finder: Sembast.Finder(
          sortOrders: [
            Sembast.SortOrder('date', false),
            Sembast.SortOrder('stock'),
          ],
        ));
    transactions = records.map((t) => Transaction.fromJson(t.value)).toList();
  }

  Future<void> _cacheOwnedStocks() async {
    return _pref.setString(
        PK_OWNED_STOCKS, json.encode(ownedStocks.map((key, value) => MapEntry(key, value.toJson()))));
  }

  Future<void> _decacheOwnedStocks() async {
    Map<String, Map<String, dynamic>> map = json.decode(_pref.getString(PK_OWNED_STOCKS));
    ownedStocks = map.map((stockCode, value) => MapEntry(stockCode, OwnedStock.fromJson(value)));
    notifyListeners();
  }

  Future<void> _calculateOwnedStocks() async {
    ownedStocks = Map();

    for (final t in transactions) {
      _accumulateOwnedStock(t);
    }
    notifyListeners();
  }

  void _accumulateOwnedStock(Transaction transaction) {
    if (ownedStocks.containsKey(transaction.stock)) {
      final ownedStock = ownedStocks[transaction.stock];
      ownedStock.lots += transaction.type == TransactionType.Buy ? transaction.lots : -transaction.lots;
      ownedStock.nettCost += transaction.type == TransactionType.Buy ? transaction.totalPrice : -transaction.totalPrice;
    } else {
      ownedStocks[transaction.stock] = OwnedStock(
        lots: transaction.lots,
        nettCost: transaction.type == TransactionType.Buy ? transaction.totalPrice : -transaction.totalPrice,
      );
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _init;
    await store.add(db, transaction.toJson());

    final index = transactions.indexWhere(
      (element) =>
          element.date.isBefore(transaction.date) ||
          (element.date.isAtSameMomentAs(transaction.date) && transaction.stock.compareTo(transaction.stock) <= 0),
    );

    if (index == -1)
      transactions.add(transaction);
    else
      transactions.insert(index, transaction);

    _accumulateOwnedStock(transaction);
  }

  Transaction transactionAt(int index) => transactions[index];

  int get transactionCount => transactions?.length ?? -1;
}

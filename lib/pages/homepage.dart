import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stocktrak/store/stock_manager.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'package:stocktrak/store/stock_manager.dart' show StockManager, TIMEOUT;
import 'package:stocktrak/store/transaction_manager.dart';
import 'package:stocktrak/utils/owned_stock.dart';
import 'package:stocktrak/utils/transaction.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class PageTab {
  Function(BuildContext context) build;
  String name;
  Icon icon;

  PageTab({this.build, this.name, this.icon});

  BottomNavigationBarItem buildBottomNavigationBarItem(BuildContext context) {
    return BottomNavigationBarItem(
      icon: this.icon,
      title: Text(this.name),
    );
  }
}

class _HomePageState extends State<HomePage> {
  static final _pageTabs = [
    PageTab(
      name: "Dashboard",
      icon: Icon(Icons.show_chart),
      build: (BuildContext context) => DashboardScreen(),
    ),
    PageTab(
      name: "Transactions",
      icon: Icon(Icons.list),
      build: (BuildContext context) => TransactionScreen(),
    ),
  ];

  PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    super.dispose();

    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        top: true,
        child: PageView(
          scrollDirection: Axis.horizontal,
          controller: _pageController,
          onPageChanged: _changePage,
          children: _pageTabs.map<Widget>((tab) => tab.build(context)).toList(),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).bottomAppBarColor,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _pageController.hasClients ? _pageController.page.round() : 0,
          items: _pageTabs.map((tab) => tab.buildBottomNavigationBarItem(context)).toList(),
          elevation: 0,
          onTap: _changePage,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/new-transaction'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _changePage(int index) {
    setState(() {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOutQuad,
      );
    });
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

enum _DashboardViewType { Delta, PercentDelta }

class _DashboardScreenState extends State<DashboardScreen> {
  RefreshController _controller;

  _DashboardViewType _type = _DashboardViewType.Delta;

  @override
  void initState() {
    super.initState();
    _controller = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<StockManager>(
      builder: (context, manager, child) => SmartRefresher(
        scrollDirection: Axis.vertical,
        enablePullDown: true,
        controller: _controller,
        header: ClassicHeader(
          textStyle: theme.textTheme.bodyText2,
        ),
        onRefresh: () async {
          try {
            await manager.fetchStocks().timeout(TIMEOUT);
            _controller.refreshCompleted();
          } catch (error) {
            _controller.refreshFailed();
            if (kDebugMode) print(error);
          }
        },
        child: child,
      ),
      child: CustomScrollView(
        scrollDirection: Axis.vertical,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onLongPress: () => _calculateOwnedStocks(context),
                        child: Text("Dashboard", style: theme.textTheme.headline3),
                      ),
                      SizedBox(height: 32.0),
                      Align(
                        alignment: Alignment.topRight,
                        child: ToggleButtons(
                          children: [
                            Text('Rp'),
                            Text('%'),
                          ],
                          constraints: BoxConstraints(minHeight: 32, minWidth: 48),
                          selectedColor: theme.floatingActionButtonTheme.foregroundColor,
                          fillColor: theme.floatingActionButtonTheme.backgroundColor,
                          isSelected: _type == _DashboardViewType.Delta ? const [true, false] : const [false, true],
                          borderRadius: BorderRadius.circular(2),
                          borderColor: theme.buttonColor,
                          selectedBorderColor: theme.accentColor,
                          onPressed: (index) {
                            setState(() {
                              _type = index == 0 ? _DashboardViewType.Delta : _DashboardViewType.PercentDelta;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StockList(viewType: _type),
        ],
      ),
    );
  }

  Future<void> _calculateOwnedStocks(BuildContext context) async {
    final scaffold = Scaffold.of(context);

    scaffold.showSnackBar(SnackBar(
      content: Text('Resetting dashboard'),
    ));
    _controller.requestRefresh();

    final manager = Provider.of<TransactionManager>(context, listen: false);
    await manager.calculateOwnedStocks();

    scaffold.showSnackBar(SnackBar(
      content: Text('Reset complete'),
    ));
  }
}

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  bool _isSelecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Transactions", style: theme.textTheme.headline3),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ]),
        ),
        TransactionList(selectMode: _isSelecting),
      ],
    );
  }
}

class StockList extends StatelessWidget {
  final _DashboardViewType viewType;

  StockList({Key key, this.viewType}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionManager>(
      builder: (context, manager, _) {
        if (manager.ownedStocks?.length != 0) {
          final stocks = manager.ownedStocks?.entries?.toList(growable: false) ?? [];
          stocks.sort((a, b) => a.key.compareTo(b.key));

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => StockListItem(
                stockCode: stocks[index].key,
                ownedStock: stocks[index].value,
                viewType: viewType,
              ),
              childCount: stocks.length,
            ),
          );
        } else {
          return SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Dashboard will be available once there are transactions.\nTap the "+" button to add',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            hasScrollBody: false,
          );
        }
      },
    );
  }
}

class StockListItem extends StatelessWidget {
  final String stockCode;
  final OwnedStock ownedStock;
  final _DashboardViewType viewType;

  StockListItem({
    Key key,
    @required this.stockCode,
    @required this.ownedStock,
    this.viewType = _DashboardViewType.Delta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(stockCode, style: theme.textTheme.headline6),
              Consumer2<StockManager, TransactionManager>(
                builder: (context, stockManager, transactionManager, _) {
                  if (stockManager.dailyStocks == null)
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[800],
                      highlightColor: Colors.grey[700],
                      child: Container(
                        width: 48,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white,
                        ),
                      ),
                    );
                  else {
                    final stockPrice = stockManager.stockPrice(stockCode);

                    if (stockPrice != null) {
                      if (transactionManager.ownedStocks[stockCode] == null)
                        return Text(
                          stockPrice.toString(),
                          style: theme.textTheme.overline,
                        );
                      else {
                        final lots = transactionManager.ownedStocks[stockCode].lots;

                        return Text(
                          '${lots}L @ ${stockPrice.toString()}',
                          style: theme.textTheme.overline,
                        );
                      }
                    } else {
                      return Text(
                        'ERROR',
                        style: theme.textTheme.overline.copyWith(color: theme.errorColor),
                      );
                    }
                  }
                },
              ),
              Text('CAP: ' + ownedStock.nettCost.toString(), style: theme.textTheme.overline),
            ],
          ),
          Consumer<StockManager>(builder: (context, manager, _) => _buildStockDelta(context, manager)),
        ],
      ),
    );
  }

  Widget _buildStockDelta(BuildContext context, StockManager manager) {
    final theme = Theme.of(context);
    final stockPrice = manager.stockPrice(stockCode);

    if (stockPrice == null)
      return Shimmer.fromColors(
        baseColor: Colors.grey[800],
        highlightColor: Colors.grey[700],
        child: Container(
          width: 96,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white,
          ),
        ),
      );

    final currentPrice = stockPrice * ownedStock.lots * Transaction.stocksPerLot;
    Color color;
    String sign = '';

    if (currentPrice > ownedStock.nettCost) {
      color = theme.primaryColor;
      sign = '+';
    } else if (currentPrice == ownedStock.nettCost)
      color = Colors.yellowAccent;
    else
      color = theme.errorColor;

    Widget Function(BuildContext, double, Widget) _buildDeltaText;
    switch (viewType) {
      case _DashboardViewType.PercentDelta:
        final percentDelta = (currentPrice.toDouble() / ownedStock.nettCost.toDouble()) * 100 - 100;

        _buildDeltaText = (context, value, _) => Opacity(
              opacity: value,
              child: Text(
                '$sign${(value * percentDelta).toStringAsFixed(2)}%',
                style: theme.textTheme.headline6.copyWith(color: color),
              ),
            );
        break;
      default:
        final delta = currentPrice - ownedStock.nettCost;

        _buildDeltaText = (context, value, _) => Opacity(
              opacity: value,
              child: Text(
                sign + (delta * value).toString(),
                style: theme.textTheme.headline6.copyWith(color: color),
              ),
            );
    }

    return TweenAnimationBuilder<double>(
      key: Key(EnumToString.parse(viewType)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
      tween: Tween<double>(begin: 0, end: 1),
      builder: _buildDeltaText,
    );
  }
}

class TransactionList extends StatelessWidget {
  final bool selectMode;

  TransactionList({Key key, this.selectMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionManager>(
      builder: (context, manager, child) {
        if (manager.transactionCount == 0)
          return SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nothing here\nAdd a Transaction with the "+" button',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            hasScrollBody: false,
          );
        else if (manager.transactionCount > 0)
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = manager.transactionAt(index);
                return TransactionListItem(
                  transaction,
                  key: Key(transaction.id.toRadixString(16)),
                  onTap: () => _editTransaction(transaction, context),
                  onLongPress: () => _showOptionsDialog(index, manager, context),
                );
              },
              childCount: manager.transactionCount,
            ),
          );
        else
          return Center(
            child: CircularProgressIndicator(),
          );
      },
    );
  }

  Future<void> _showOptionsDialog(int index, TransactionManager manager, BuildContext context) async {
    await showDialog(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            title: const Text('Transaction Actions'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  final manager = Provider.of<TransactionManager>(context, listen: false);
                  _editTransaction(manager.transactionAt(index), context);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Edit'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  _deleteTransactionAt(index, manager, context);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        });
  }

  Future<void> _editTransaction(Transaction transaction, BuildContext context) {
    return Navigator.pushNamed(context, '/edit-transaction', arguments: transaction);
  }

  Future<void> _deleteTransactionAt(int index, TransactionManager manager, BuildContext context) async {
    final transaction = manager.transactionAt(index);

    await manager.removeTransactionAt(index);
    final scaffold = Scaffold.of(context);

    scaffold.showSnackBar(SnackBar(
      content: Text(
          '${transaction.stock} ${transaction.lots}L @ ${transaction.pricePerStock.toString()} Transaction deleted'),
      action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            await manager.addTransaction(transaction);
            scaffold.showSnackBar(SnackBar(
              content: Text('Undid transaction delete'),
            ));
          }),
    ));
  }
}

class TransactionListItem extends StatelessWidget {
  final Key key;
  final Transaction transaction;
  final Function onLongPress;
  final Function onTap;

  TransactionListItem(
    this.transaction, {
    this.key,
    this.onLongPress,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.stock, style: theme.textTheme.headline6),
                Text(transaction.date.toIso8601String().substring(0, 10), style: theme.textTheme.overline),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${transaction.lots}L @ ${transaction.pricePerStock.toString()}",
                  style: theme.textTheme.overline,
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, _) => Opacity(
                    opacity: value,
                    child: Text(
                      (transaction.totalPrice * value).toString(),
                      style: transaction == null
                          ? theme.textTheme.headline6
                          : theme.textTheme.headline6.copyWith(
                              color: transaction.type == TransactionType.Buy ? theme.primaryColor : theme.errorColor,
                            ),
                    ),
                  ),
                ),
                Text(
                  EnumToString.parse(transaction.type).toUpperCase(),
                  style: theme.textTheme.overline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

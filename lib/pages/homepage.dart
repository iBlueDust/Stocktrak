import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:stocktrak/utils/money.dart';
import 'package:stocktrak/utils/stock_scraper.dart';

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
              width: 2,
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
        onPressed: () {},
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

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Dashboard", style: theme.textTheme.headline3),
          SizedBox(height: 32.0),
          StockList(),
        ],
      ),
    );
  }
}

class TransactionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Transaction Screen"),
    );
  }
}

class StockList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      children: <Widget>[
        StockListItem(),
      ],
    );
  }
}

class StockListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("ASII", style: theme.textTheme.headline6),
              FutureBuilder(
                future: scrapeStockValue('ASII'),
                builder: (context, snap) {
                  if (snap.hasError)
                    return Text(
                      'Error',
                      style: TextStyle(color: theme.errorColor),
                    );
                  else if (snap.connectionState == ConnectionState.done)
                    return Text(
                      (snap.data as Money).toString(),
                    );
                  else
                    return Shimmer.fromColors(
                      baseColor: theme.highlightColor.withOpacity(0.85),
                      highlightColor: theme.highlightColor,
                      child: Container(
                        width: 48,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                      ),
                    );
                },
              ),
            ],
          ),
          Text(
            "+Rp 600,000",
            style: theme.textTheme.headline6.copyWith(color: theme.primaryColor),
          ),
        ],
      ),
    );
  }
}

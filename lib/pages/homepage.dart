import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stocktrak/store/stock_manager.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:stocktrak/store/stock_manager.dart' show StockManager, TIMEOUT;

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

class _DashboardScreenState extends State<DashboardScreen> {
	RefreshController _controller;

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
			child: Padding(
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
							Consumer<StockManager>(
								builder: (context, manager, _) {
									if (manager.dailyStocks == null)
										return Shimmer.fromColors(
											baseColor: Colors.grey[700],
											highlightColor: Colors.grey[500],
											child: Container(
												width: 48,
												height: 16,
												decoration: BoxDecoration(
													borderRadius: BorderRadius.circular(4),
													color: Colors.white,
												),
											),
										);
									else {
										final stockPrice = manager.stockPrice("ASII");

										if (stockPrice != null)
											return Text(stockPrice.toString());
										else
											return Text(
												'Error',
												style: TextStyle(color: theme.errorColor),
											);
									}
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

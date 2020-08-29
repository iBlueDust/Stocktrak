import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart' show MoneyMaskedTextController;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocktrak/store/stock_manager.dart';

import 'package:stocktrak/utils/money.dart';
import 'package:stocktrak/utils/stock_scraper.dart';
import 'package:stocktrak/utils/transaction.dart';

class NewTransactionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("New Transaction", style: theme.textTheme.headline3),
                SizedBox(height: 64.0),
                TransactionForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  Money _pricePerStock = Money(0);
  int _lots = 1;

  String _stock = '';
  bool _isStockValid = false;

  MoneyMaskedTextController _pricePerStockController;

  DateTime _date = DateTime.now();
  TextEditingController _dateFieldController;

  @override
  void initState() {
    super.initState();

    _pricePerStockController = MoneyMaskedTextController(
      leftSymbol: 'Rp ',
      precision: 0,
      decimalSeparator: '',
      thousandSeparator: ',',
    )..addListener(() {
        setState(() => _pricePerStock = Money.fromDouble(_pricePerStockController.numberValue));
      });
    _dateFieldController = TextEditingController();
    _updateDateField();
  }

  @override
  void dispose() {
    super.dispose();

    _pricePerStockController.dispose();
    _dateFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Consumer<StockManager>(
                  builder: (context, manager, _) => TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Stock code',
                    ),
                    onChanged: (stock) {
                      setState(() {
                        _stock = stock;
                        final price = manager.stockPrice(stock);

                        if (price == null)
                          _isStockValid = false;
                        else {
                          _pricePerStockController.updateValue(price.toDouble());
                          _isStockValid = true;
                        }
                      });
                    },
                    validator: (text) {
                      if (text.length < 4)
                        return 'Has to be 4 letters';
                      else if (!_isStockValid) return 'Unknown stock code';

                      return null;
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: StockFetcher(
                    stock: _stock,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Price per stock',
                    ),
                    controller: _pricePerStockController,
                    keyboardType: TextInputType.number,
                    validator: (_) {
                      if (_pricePerStock < 0) return 'This can\'t be negative';
                      return null;
                    }),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 64),
                  child: TextFormField(
                    initialValue: '1',
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Lots',
                    ),
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly,
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (text) => setState(() => _lots = text.isEmpty ? 0 : int.parse(text)),
                    validator: (_) => _lots < 0 ? 'Lots cannot be negative' : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 48),
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              labelText: 'Date',
            ),
            keyboardType: TextInputType.datetime,
            readOnly: true,
            onTap: () {
              _showDatePicker(context);
            },
            controller: _dateFieldController,
            validator: (_) => _date == null ? 'Date is required' : null,
          ),
          SizedBox(height: 48),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: theme.textTheme.overline,
                  ),
                  Text(
                    (_pricePerStock * _lots * Transaction.stocksPerLot).toString(),
                    style: theme.textTheme.headline6,
                  ),
                ],
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlineButton(
              onPressed: () {
                _showCancelDialog(context);
              },
              child: Text('Cancel'),
              borderSide: BorderSide(
                color: theme.buttonColor,
              ),
            ),
            SizedBox(width: 16),
            FlatButton(
              color: theme.accentColor,
              onPressed: () => _save(context),
              child: Text('Save'),
            ),
          ])
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard changes?'),
        content: Text('Your changes will not be saved!'),
        actions: <Widget>[
          FlatButton(
            textColor: theme.buttonColor,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
          FlatButton(
            color: theme.accentColor,
            onPressed: () => Navigator.pop(context),
            child: Text('Nevermind'),
          ),
          SizedBox(width: 0),
        ],
      ),
    );
  }

  void _updateDateField() {
    _dateFieldController.text = DateFormat.yMMMd().format(_date);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1),
      lastDate: DateTime(6000),
    );

    if (date != null) {
      setState(() {
        this._date = date;
        _updateDateField();
      });
    }
  }

  void _save(BuildContext context) {
    if (this._formKey.currentState.validate()) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved!"),
        ),
      );
    } else
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text("Error!"),
        ),
      );
  }
}

class StockFetcher extends StatelessWidget {
  final String stock;
  final Function(Money) onFetch;

  const StockFetcher({
    Key key,
    @required this.stock,
    this.onFetch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stock.length < 4) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.keyboard_arrow_left),
          Flexible(
            child: Text(
              'Type a Stock Code',
              style: theme.textTheme.headline6,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    } else {
      return Consumer<StockManager>(
        builder: (context, manager, _) {
          final price = manager.stockPrice(stock);
          if (price == null) {
            return Align(
              alignment: Alignment.centerRight,
              child: Text('Not found', style: theme.textTheme.headline6),
            );
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text("${manager.stockPrice(stock).toString()}", style: theme.textTheme.headline6),
                Text("PER STOCK", style: theme.textTheme.overline),
              ],
            );
          }
        },
      );
    }
  }
}

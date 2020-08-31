import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart' show MoneyMaskedTextController;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocktrak/store/stock_manager.dart';

import 'package:stocktrak/utils/money.dart';
import 'package:stocktrak/utils/transaction.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction, bool Function()) onSave;
  final Function(bool) onCancel;
  final Transaction initValue;

  TransactionForm({
    Key key,
    this.initValue,
    this.onSave,
    this.onCancel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  int _id;

// #region Transaction values
  TransactionType _type = TransactionType.Buy;

  Money _pricePerStock = Money(0);
  int _lots = 1;

  String _stock = '';
  bool _isStockValid = false;

  MoneyMaskedTextController _pricePerStockController;

  DateTime _date;
  TextEditingController _dateFieldController;

  String _notes = '';

  Transaction get transaction => Transaction(
        id: _id,
        date: _date,
        lots: _lots,
        pricePerStock: _pricePerStock,
        stock: _stock,
        type: _type,
        notes: _notes,
      );
// #endregion

  bool _edited = false;

  @override
  void initState() {
    super.initState();

    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);

    // Copy init value from widget
    _id = widget.initValue?.id ?? _id;
    _type = widget.initValue?.type ?? _type;
    _pricePerStock = widget.initValue?.pricePerStock ?? _pricePerStock;
    _lots = widget.initValue?.lots ?? _lots;
    _stock = widget.initValue?.stock ?? _stock;
    _date = widget.initValue?.date ?? today;
    _notes = widget.initValue?.notes ?? _notes;

    // Controlers
    _pricePerStockController = MoneyMaskedTextController(
      leftSymbol: 'Rp',
      precision: 0,
      decimalSeparator: '',
      thousandSeparator: '.',
    )
      // Make sure to update before attaching a listener
      ..updateValue(_pricePerStock.toDouble())
      ..addListener(() {
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
          ToggleButtons(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("BUY"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("SELL"),
              ),
            ],
            constraints: BoxConstraints(minHeight: 32, minWidth: 48),
            selectedColor: theme.floatingActionButtonTheme.foregroundColor,
            fillColor: theme.floatingActionButtonTheme.backgroundColor,
            isSelected: _type == TransactionType.Buy ? [true, false] : [false, true],
            borderRadius: BorderRadius.circular(2),
            borderColor: theme.buttonColor,
            selectedBorderColor: theme.accentColor,
            onPressed: (index) {
              setState(() {
                _type = index == 0 ? TransactionType.Buy : TransactionType.Sell;
              });
            },
          ),
          SizedBox(height: 32),
          Row(
            children: <Widget>[
              Expanded(
                child: Consumer<StockManager>(
                  builder: (context, manager, _) => TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                    initialValue: _stock,
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Stock code',
                    ),
                    onChanged: (stock) {
                      _edited = true;

                      setState(() {
                        _stock = stock.toUpperCase();
                        final price = manager.stockPrice(_stock);

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
                    onChanged: (_) {
                      _edited = true;
                    },
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
                    initialValue: _lots.toString(),
                    decoration: InputDecoration(
                      filled: true,
                      labelText: 'Lots',
                    ),
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly,
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (text) {
                      _edited = true;
                      setState(() => _lots = text.isEmpty ? 0 : int.parse(text));
                    },
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
            onTap: () => _showDatePicker(context),
            controller: _dateFieldController,
            validator: (_) => _date == null ? 'Date is required' : null,
          ),
          SizedBox(height: 48),
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              labelText: 'Notes',
            ),
            initialValue: _notes,
            keyboardType: TextInputType.multiline,
            maxLines: 10,
            minLines: 1,
            onChanged: (text) {
              _edited = true;
              _notes = text;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: theme.textTheme.overline,
                  ),
                  TweenAnimationBuilder<Money>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutQuad,
                    tween: Tween<Money>(begin: Money(0), end: _pricePerStock * _lots * Transaction.stocksPerLot),
                    builder: (context, total, _) => Text(
                      total.toString(),
                      style: theme.textTheme.headline6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlineButton(
              onPressed: cancel,
              child: Text('Cancel'),
              borderSide: BorderSide(
                color: theme.buttonColor,
              ),
            ),
            SizedBox(width: 16),
            FlatButton(
              color: theme.accentColor,
              onPressed: this.save,
              child: Text('Save'),
            ),
          ])
        ],
      ),
    );
  }

  void save() {
    widget.onSave(transaction, this._formKey.currentState.validate);
  }

  void cancel() {
    widget.onCancel(_edited);
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

    if (date != _date) ;
    _edited = true;

    if (date != null) {
      setState(() {
        this._date = date;
        _updateDateField();
      });
    }
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
                TweenAnimationBuilder<Money>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                  tween: Tween<Money>(begin: Money(0), end: manager.stockPrice(stock)),
                  builder: (context, stockPrice, _) =>
                      Text("${stockPrice.toString()}", style: theme.textTheme.headline6),
                ),
                Text("PER STOCK", style: theme.textTheme.overline),
              ],
            );
          }
        },
      );
    }
  }
}

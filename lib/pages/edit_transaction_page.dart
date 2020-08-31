import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stocktrak/components/transaction_form.dart';
import 'package:stocktrak/store/transaction_manager.dart';
import 'package:stocktrak/utils/transaction.dart';

class EditTransactionPage extends StatelessWidget {
  final _formKey = GlobalKey<TransactionFormState>(debugLabel: 'EditTransactionPage TransactionForm');

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text("Edit Transaction", style: theme.textTheme.headline3),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _formKey.currentState.cancel(),
                    )
                  ],
                ),
                SizedBox(height: 64.0),
                TransactionForm(
                  key: _formKey,
                  initValue: ModalRoute.of(context).settings.arguments,
                  onCancel: (isEdited) => _close(context, isEdited),
                  onSave: (transaction, validate) => _save(context, transaction, validate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context, bool isEdited) {
    if (isEdited)
      _showCancelDialog(context);
    else
      Navigator.pop(context);
  }

  Future<void> _save(BuildContext context, Transaction transaction, bool Function() validate) async {
    if (validate()) {
      final manager = Provider.of<TransactionManager>(context, listen: false);
      await manager.updateTransaction(transaction);
    }
  }

  Future<void> _showCancelDialog(BuildContext context) {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Discard changes?'),
        content: Text('Your changes will not be saved!'),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
          FlatButton(
            color: theme.accentColor,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Nevermind'),
          ),
          SizedBox(width: 0),
        ],
      ),
    );
  }
}

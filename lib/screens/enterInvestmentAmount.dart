import 'dart:convert';

import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class EnterInvestmentAmount extends StatefulWidget {
  var min;
  var max;
  EnterInvestmentAmount({this.min, this.max});
  @override
  State<EnterInvestmentAmount> createState() => _EnterInvestmentAmountState();
}

class _EnterInvestmentAmountState extends State<EnterInvestmentAmount> {
  var amountController = TextEditingController();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  controller: amountController,
                  decoration: InputDecoration(
                    hintText: 'Amount (\$${widget.min} - \$${widget.max})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: double.infinity,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: Colors.blue,
                    onPressed: () async {
                      if (double.parse(amountController.text.trim()) <
                              widget.min ||
                          double.parse(amountController.text.trim()) >
                              widget.max) {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(
                                'The minimum is ${widget.min} and maximum is ${widget.max}')));
                      } else {
                        var response = jsonDecode((await post(
                                Uri.parse(
                                    'https://api.commerce.coinbase.com/charges/'),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'X-CC-Api-Key': coinbaseApiKey,
                                  'X-CC-Version': '2018-03-22',
                                },
                                body: jsonEncode({
                                  'name': 'Deposit',
                                  'description':
                                      'Investing ${amountController.text.trim()}',
                                  'local_price': {
                                    'amount': amountController.text.trim(),
                                    'currency': 'USD'
                                  },
                                  'pricing_type': 'fixed_price'
                                })))
                            .body)['data'];
                        await launch(response['hosted_url']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        'Invest',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

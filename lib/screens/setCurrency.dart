import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cryptowallet/screens/receiveToken.dart';
import 'package:cryptowallet/screens/sendToken.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

class setCurrency extends StatefulWidget {
  var data;
  setCurrency({this.data});

  @override
  _setCurrencyState createState() => _setCurrencyState();
}

class _setCurrencyState extends State<setCurrency> {
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  var gestureRecognizers = [Factory(() => EagerGestureRecognizer())].toSet();

  UniqueKey _key = UniqueKey();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: 30,
                        )),
                    Text(
                      'Select Fiat Currency',
                      style: TextStyle(fontSize: 18),
                    ),
                    GestureDetector(
                      onTap: () async {},
                      child: Text(
                        'OKK',
                        style:
                            TextStyle(fontSize: 18, color: Color(0x00ffffff)),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                FutureBuilder(future: () async {
                  print('debugging');
                  var pref = await SharedPreferences.getInstance();
                  var defaultCurrency =
                      pref.getString('defaultCurrency') == null
                          ? 'USD'
                          : pref.getString('defaultCurrency');

                  var currencyList = await getCurrencyJson();
                  return {
                    'defaultCurrency': defaultCurrency,
                    'currencyList': currencyList
                  };
                }(), builder: (ctx, snapshot) {
                  var currencyWidget = <Widget>[];
                  if (snapshot.hasData) {
                    var data = snapshot.data as Map;
                    var currencyList = jsonDecode(data['currencyList']) as Map;

                    for (var currency in currencyList.keys) {
                      currencyWidget.add(InkWell(
                        onTap: () async {
                          var pref = await SharedPreferences.getInstance();
                          var responseBody = jsonDecode((await get(Uri.parse(
                                  'https://api.coingecko.com/api/v3/simple/supported_vs_currencies')))
                              .body) as List;

                          if (responseBody
                              .contains(currency.toString().toLowerCase())) {
                            pref.setString('defaultCurrency', currency);
                            Navigator.pop(context);
                            setState(() {});
                          } else {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text('${currency} is not supported yet'),
                              duration: Duration(seconds: 2),
                            ));
                          }
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      backgroundImage: AssetImage(
                                          'assets/currency_flags/${currency.toLowerCase()}.png'),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Flexible(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currency,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    currencyList[currency],
                                                    style:
                                                        TextStyle(fontSize: 15),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: Colors.blue),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: currency == data['defaultCurrency']
                                      ? Icon(
                                          Icons.check,
                                          size: 20,
                                          color: Colors.white,
                                        )
                                      : Icon(
                                          Icons.check_box_outline_blank,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                ),
                              )
                            ]),
                      ));

                      currencyWidget.add(Divider());
                    }
                  }
                  return Column(
                    children: currencyWidget,
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

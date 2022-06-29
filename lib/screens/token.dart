import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cryptowallet/screens/private_sale.dart';
import 'package:cryptowallet/screens/receiveToken.dart';
import 'package:cryptowallet/screens/sendToken.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Token extends StatefulWidget {
  var data;
  Token({this.data});

  @override
  _TokenState createState() => _TokenState();
}

class _TokenState extends State<Token> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  var gestureRecognizers = [Factory(() => EagerGestureRecognizer())].toSet();

  UniqueKey _key = UniqueKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
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
                            if (Navigator.canPop(context))
                              Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            size: 30,
                          )),
                      Text(
                        widget.data['name'],
                        style: TextStyle(fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await launch(buyCryptoLink);
                        },
                        child: Text(
                          'BUY',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coin',
                        style: TextStyle(fontSize: 18),
                      ),
                      widget.data['noPrice'] != null
                          ? Text(
                              '\$0',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: widget.data['contractAddress'] != null
                                      ? Color(0x00ffffff)
                                      : null),
                            )
                          : StreamBuilder(
                              stream: () async* {
                                while (true) {
                                  var currencyWithSymbol = jsonDecode(
                                      await rootBundle.loadString(
                                          'json/currency_symbol.json')) as Map;
                                  var defaultCurrency =
                                      (await SharedPreferences.getInstance())
                                              .getString('defaultCurrency') ??
                                          "USD";

                                  var symbol =
                                      (currencyWithSymbol[defaultCurrency]
                                          ['symbol']);

                                  var price =
                                      (jsonDecode(await getCryptoPrice())
                                                  as Map)[
                                              coinGeckCryptoSymbolToID[
                                                  widget.data['symbol']]]
                                          [defaultCurrency.toLowerCase()];

                                  yield {'price': price, 'symbol': symbol};
                                  await Future.delayed(forFetch);
                                }
                              }(),
                              builder: (ctx, snapshot) {
                                if (snapshot.hasError) print(snapshot.error);
                                if (snapshot.hasData) {
                                  return Text(
                                    '${(snapshot.data as Map)['symbol']}${formatMoney((snapshot.data as Map)['price'])}',
                                    style: TextStyle(fontSize: 18),
                                  );
                                } else
                                  return Text(
                                    '\$0',
                                    style: TextStyle(fontSize: 18),
                                  );
                              },
                            )
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  StreamBuilder(stream: () async* {
                    while (true) {
                      if (widget.data['contractAddress'] != null) {
                        yield (await getERC20TokenBalance(widget.data as Map));
                        await Future.delayed(forFetch);
                        return;
                      } else if (widget.data['default'] != null) {
                        if (widget.data['default'] == 'BTC') {
                          var seedPhrase =
                              (await SharedPreferences.getInstance())
                                  .getString('mmemomic');
                          var getBitCoinDetails =
                              await getBitCoinFromMemnomic(seedPhrase);
                          yield (await getBitcoinAddressDetails(
                              getBitCoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                          return;
                        } else if (widget.data['default'] == 'BTCTEST') {
                          var seedPhrase =
                              (await SharedPreferences.getInstance())
                                  .getString('mmemomic');
                          var getBitCoinDetails = await getBitCoinFromMemnomic(
                              seedPhrase,
                              istestnet: true);
                          yield (await getBitcoinAddressDetails(
                              getBitCoinDetails['address'],
                              istestnet: true))['final_balance'];
                          await Future.delayed(forFetch);
                          return;
                        } else if (widget.data['default'] == 'LTC') {
                          var seedPhrase =
                              (await SharedPreferences.getInstance())
                                  .getString('mmemomic');
                          var getLitecoinDetails =
                              await getLiteCoinFromMemnomic(seedPhrase);
                          yield (await getLitecoinAddressDetails(
                              getLitecoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                          return;
                        } else if (widget.data['default'] == 'DOGE') {
                          var seedPhrase =
                              (await SharedPreferences.getInstance())
                                  .getString('mmemomic');
                          var getDogecoinDetails =
                              await getDogeCoinFromMemnomic(seedPhrase);
                          yield (await getDogecoinAddressDetails(
                              getDogecoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                          return;
                        } else {
                          yield await getEthBalance(rpcUrl: widget.data['rpc']);
                          await Future.delayed(forFetch);
                          return;
                        }
                      }
                      await Future.delayed(forFetch);
                      yield 0;
                    }
                  }(), builder: (context, snapshot) {
                    return Text(
                      '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : ''} ${widget.data['symbol']}',
                      style: TextStyle(fontSize: 20),
                    );
                  }),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () async {
                              var seedPhrase =
                                  (await SharedPreferences.getInstance())
                                      .getString('mmemonic');
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => SendToken(
                                      data: widget.data,
                                      seedPhrase: seedPhrase,
                                    ),
                                  ));
                            },
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.upload,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Send',
                                  style: TextStyle(fontSize: 15),
                                )
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var seedPhrase =
                                  (await SharedPreferences.getInstance())
                                      .getString('mmemonic');

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => ReceiveToken(
                                    data: widget.data,
                                    seedPhrase: seedPhrase,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.download,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Receive',
                                  style: TextStyle(fontSize: 15),
                                )
                              ],
                            ),
                          ),
                        ]),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  StreamBuilder(stream: () async* {
                    var pref = await SharedPreferences.getInstance();

                    var seedPhrase = pref.getString('mmemomic');
                    var response = await getCryptoKeys(seedPhrase);
                    var currentAddress;

                    if (widget.data['default'] == 'BTC') {
                      currentAddress =
                          (await getBitCoinFromMemnomic(seedPhrase))['address'];
                    } else if (widget.data['default'] == 'BTCTEST') {
                      currentAddress = (await getBitCoinFromMemnomic(seedPhrase,
                              istestnet: true))['address']
                          .toString()
                          .toLowerCase();
                    } else if (widget.data['default'] == 'LTC') {
                      currentAddress =
                          (await getLiteCoinFromMemnomic(seedPhrase))['address']
                              .toString()
                              .toLowerCase();
                    } else if (widget.data['default'] == 'DOGE') {
                      currentAddress =
                          (await getDogeCoinFromMemnomic(seedPhrase))['address']
                              .toString()
                              .toLowerCase();
                    } else {
                      var response = await getCryptoKeys(seedPhrase);
                      currentAddress = response['eth_wallet_address']
                          .toString()
                          .toLowerCase();
                    }

                    if (widget.data['contractAddress'] != null &&
                        pref.getString(
                                '${widget.data['contractAddress']} Details') !=
                            null) {
                      yield {
                        'trx': jsonDecode(pref.getString(
                            '${widget.data['contractAddress']} Details')),
                        'currentUser': currentAddress
                      };
                    } else if (widget.data['default'] != null &&
                        pref.getString('${widget.data['default']} Details') !=
                            null) {
                      yield {
                        'trx': jsonDecode(pref
                            .getString('${widget.data['default']} Details')),
                        'currentUser': currentAddress
                      };
                    } else {
                      yield {'trx': [], 'currentUser': currentAddress};
                    }
                  }(), builder: (context, snapshot) {
                    if (snapshot.hasError) print(snapshot.error);
                    if (snapshot.hasData) {
                      var returnedData = snapshot.data as Map;
                      print(returnedData);
                      List data = returnedData['trx'] as List;
                      var listTransactions = <Widget>[];

                      for (var datum in data) {
                        if (datum['from'].toString().toLowerCase() !=
                            returnedData['currentUser']) continue;
                        var tokenSent =
                            datum['value'] / pow(10, datum['decimal']);
                        listTransactions.addAll([
                          InkWell(
                            onTap: () async {
                              await launch(
                                  '${widget.data['block explorer']}/tx/${datum['transactionHash']}');
                            },
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    datum['time'],
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Icon(Icons.upload,
                                                color: Colors.grey),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Transfer',
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    datum['to'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '-${tokenSent}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Color(0xffeb6a61)),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          Divider()
                        ]);
                      }

                      if (listTransactions.isEmpty) {
                        return const Text('No Transaction Recorded Yet');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: listTransactions,
                      );
                    } else
                      return Text('Loading...');
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

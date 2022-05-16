import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

class ReceiveToken extends StatefulWidget {
  var data;
  var seedPhrase;
  ReceiveToken({this.data, this.seedPhrase});

  @override
  _ReceiveTokenState createState() => _ReceiveTokenState();
}

class _ReceiveTokenState extends State<ReceiveToken> {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: StreamBuilder(stream: () async* {
        while (true) {
          var seedPhrase =
              (await SharedPreferences.getInstance()).getString('mmemomic');
          if (widget.data['default'] == 'BTC') {
            var getBitCoinDetails = await getBitCoinFromMemnomic(seedPhrase);
            (await SharedPreferences.getInstance())
                .setString('bitCoinAddr', getBitCoinDetails['address']);
            yield {'address': getBitCoinDetails['address']};
            return;
          } else if (widget.data['default'] == 'BTCTEST') {
            var getBitCoinDetails =
                await getBitCoinFromMemnomic(seedPhrase, istestnet: true);
            (await SharedPreferences.getInstance())
                .setString('bitCoinAddr', getBitCoinDetails['address']);
            yield {'address': getBitCoinDetails['address']};
            return;
          } else if (widget.data['default'] == 'LTC') {
            var getLiteCoinAddress = await getLiteCoinFromMemnomic(seedPhrase);
            (await SharedPreferences.getInstance())
                .setString('liteconaddr', getLiteCoinAddress['address']);
            yield {'address': getLiteCoinAddress['address']};
            return;
          } else if (widget.data['default'] == 'DOGE') {
            var dogeCoinDetails = await getDogeCoinFromMemnomic(seedPhrase);
            (await SharedPreferences.getInstance())
                .setString('dogeCoinAddr', dogeCoinDetails['address']);
            yield {'address': dogeCoinDetails['address']};
            return;
          }
          var response = await getCryptoKeys(seedPhrase);
          (await SharedPreferences.getInstance())
              .setString('privateKey', response['eth_wallet_privateKey']);
          (await SharedPreferences.getInstance())
              .setString('address', response['eth_wallet_address']);
          yield {'address': response['eth_wallet_address']};
          await Future.delayed(Duration(minutes: 1));
        }
      }(), builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error.toString() + 'error here');
        if (snapshot.hasData) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
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
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Receive ${widget.data['symbol']}',
                          style: TextStyle(fontSize: 18),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    QrImage(
                      backgroundColor:
                          MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                      data: (snapshot.data as Map)['address'],
                      version: QrVersions.auto,
                      size: 250,
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Text((snapshot.data as Map)['address'],
                        textAlign: TextAlign.center),
                    SizedBox(
                      height: 40,
                    ),
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: [
                          TextSpan(text: 'Send only '),
                          TextSpan(
                              text:
                                  '${widget.data['name']} (${widget.data['symbol']})',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                              text:
                                  ' to this address. Sending any other coins may result in permanent loss.'),
                        ])),
                    SizedBox(
                      height: 40,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: (snapshot.data as Map)['address']));
                              scaffoldKey.currentState?.showSnackBar(
                                  SnackBar(content: Text('Copied')));
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
                                      Icons.copy,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Copy',
                                  style: TextStyle(fontSize: 17),
                                )
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await Share.share(
                                  'My Public Address to Receive ${widget.data['symbol']} ${(snapshot.data as Map)['address']}');
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
                                      Icons.share,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Share',
                                  style: TextStyle(fontSize: 17),
                                )
                              ],
                            ),
                          ),
                        ]),
                  ],
                ),
              ),
            ),
          );
        } else
          return Center(child: CircularProgressIndicator());
      }),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:cryptowallet/screens/NFT.dart';
import 'package:cryptowallet/screens/airdrop.dart';
import 'package:cryptowallet/screens/import_token.dart';
import 'package:cryptowallet/screens/private_sale.dart';
import 'package:cryptowallet/screens/token.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web3dart/web3dart.dart' as web3;
import './dapp.dart';

class WalletMainBody extends StatefulWidget {
  @override
  _WalletMainBodyState createState() => _WalletMainBodyState();
}

class _WalletMainBodyState extends State<WalletMainBody> {
  @override
  Widget build(BuildContext context) {
    var blockChainsArray = <Widget>[];
    blockChainsArray.addAll([
      InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => Token(data: const {
                        'name': 'BitCoin',
                        'symbol': 'BTC',
                        'default': 'BTC',
                        'block explorer': 'https://www.blockchain.com/btc'
                      })));
        },
        child: Container(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/bitcoin.png'),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bitcoin',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder(
                                  stream: () async* {
                                    while (true) {
                                      var currencyWithSymbol = jsonDecode(
                                          await rootBundle.loadString(
                                              'json/currency_symbol.json'));
                                      var defaultCurrency =
                                          (await SharedPreferences
                                                      .getInstance())
                                                  .getString(
                                                      'defaultCurrency') ??
                                              "USD";
                                      var symbol =
                                          (currencyWithSymbol[defaultCurrency]
                                              ['symbol']);
                                      var cryptoPrice =
                                          await getCryptoPrice('BTC');

                                      var change = await getCryptoChange('BTC');

                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');

                                      var getBitCoinDetails =
                                          await getBitCoinFromMemnomic(
                                              seedPhrase);
                                      var accountDetails =
                                          await getBitcoinAddressDetails(
                                              getBitCoinDetails['address']);

                                      yield {
                                        'price': cryptoPrice,
                                        'currencySymbol': symbol,
                                        'change': change,
                                        'balance':
                                            accountDetails['final_balance']
                                      };
                                      await Future.delayed(
                                          const Duration(minutes: 1));
                                    }
                                  }(),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.hasError) {
                                      print(snapshot.error);
                                    }
                                    if (snapshot.hasData) {
                                      var change = (snapshot.data
                                                  as Map)['change'] >
                                              0
                                          ? '+${formatMoney((snapshot.data as Map)['change'])}'
                                          : formatMoney(
                                              (snapshot.data as Map)['change']);

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${(snapshot.data as Map)['price'] == 0 ? '' : (snapshot.data as Map)['currencySymbol'] + formatMoney((snapshot.data as Map)['price'])}',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                ' ${(snapshot.data as Map)['change'] == 0 ? '' : change + '%'}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: (snapshot.data
                                                                    as Map)[
                                                                'change']
                                                            .toString()
                                                            .startsWith('-')
                                                        ? Color(0xffeb6a61)
                                                        : Color(0xff01aa78)),
                                              )
                                            ],
                                          ),
                                          Text(
                                            '${formatMoney((snapshot.data as Map)['balance'])} BTC',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      );
                                    } else
                                      return Text(
                                        '',
                                        style: TextStyle(fontSize: 15),
                                      );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ]),
                  )
                ],
              ),
            ),
          ]),
        ),
      ),
      Divider(),
      !kReleaseMode
          ? InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => Token(data: const {
                              'name': 'BitCoin(Testnet)',
                              'symbol': 'BTC',
                              'default': 'BTCTEST',
                              'block explorer':
                                  'https://www.blockchain.com/btc-testnet'
                            })));
              },
              child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              backgroundImage: AssetImage('assets/bitcoin.png'),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Flexible(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bitcoin(Testnet)',
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
                                        Expanded(
                                          child: StreamBuilder(
                                            stream: () async* {
                                              while (true) {
                                                var currencyWithSymbol = jsonDecode(
                                                    await rootBundle.loadString(
                                                        'json/currency_symbol.json'));
                                                var defaultCurrency =
                                                    (await SharedPreferences
                                                                .getInstance())
                                                            .getString(
                                                                'defaultCurrency') ??
                                                        "USD";
                                                var symbol =
                                                    (currencyWithSymbol[
                                                            defaultCurrency]
                                                        ['symbol']);
                                                var cryptoPrice =
                                                    await getCryptoPrice('BTC');

                                                var change =
                                                    await getCryptoChange(
                                                        'BTC');

                                                var seedPhrase =
                                                    (await SharedPreferences
                                                            .getInstance())
                                                        .getString('mmemomic');

                                                var getBitCoinDetails =
                                                    await getBitCoinFromMemnomic(
                                                        seedPhrase,
                                                        istestnet: true);

                                                var accountDetails =
                                                    await getBitcoinAddressDetails(
                                                        getBitCoinDetails[
                                                            'address'],
                                                        istestnet: true);

                                                yield {
                                                  'price': cryptoPrice,
                                                  'currencySymbol': symbol,
                                                  'change': change,
                                                  'balance': accountDetails[
                                                      'final_balance']
                                                };
                                                await Future.delayed(
                                                    const Duration(minutes: 1));
                                              }
                                            }(),
                                            builder: (ctx, snapshot) {
                                              if (snapshot.hasError) {
                                                print(snapshot.error);
                                              }
                                              if (snapshot.hasData) {
                                                var change = (snapshot.data
                                                            as Map)['change'] >
                                                        0
                                                    ? '+${formatMoney((snapshot.data as Map)['change'])}'
                                                    : formatMoney((snapshot.data
                                                        as Map)['change']);

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '${(snapshot.data as Map)['price'] == 0 ? '' : (snapshot.data as Map)['currencySymbol'] + formatMoney((snapshot.data as Map)['price'])}',
                                                          style: TextStyle(
                                                              fontSize: 15),
                                                        ),
                                                        Text(
                                                          ' ${(snapshot.data as Map)['change'] == 0 ? '' : change + '%'}',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: (snapshot.data
                                                                              as Map)[
                                                                          'change']
                                                                      .toString()
                                                                      .startsWith(
                                                                          '-')
                                                                  ? Color(
                                                                      0xffeb6a61)
                                                                  : Color(
                                                                      0xff01aa78)),
                                                        )
                                                      ],
                                                    ),
                                                    Text(
                                                      '${formatMoney((snapshot.data as Map)['balance'])} BTC',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                );
                                              } else
                                                return Text(
                                                  '',
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                            )
                          ],
                        ),
                      ),
                    ]),
              ),
            )
          : Container(),
      !kReleaseMode ? Divider() : Container(),
    ]);

    for (String i in getBlockChains().keys) {
      blockChainsArray.add(InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => Token(data: {
                        'name': i,
                        'symbol': getBlockChains()[i]['symbol'],
                        'default': getBlockChains()[i]['symbol'],
                        'block explorer': getBlockChains()[i]['block explorer'],
                        'rpc': getBlockChains()[i]['rpc'],
                        'chainId': getBlockChains()[i]['chainId'],
                      })));
        },
        child: Container(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(
                        getBlockChains()[i]['image'] != null
                            ? getBlockChains()[i]['image']
                            : 'assets/ethereum_logo.png'),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder(
                                  stream: () async* {
                                    while (true) {
                                      var currencyWithSymbol = jsonDecode(
                                          await rootBundle.loadString(
                                              'json/currency_symbol.json'));
                                      var defaultCurrency =
                                          (await SharedPreferences
                                                      .getInstance())
                                                  .getString(
                                                      'defaultCurrency') ??
                                              "USD";
                                      var symbol =
                                          (currencyWithSymbol[defaultCurrency]
                                              ['symbol']);
                                      var cryptoPrice = await getCryptoPrice(
                                          getBlockChains()[i]['symbol']);

                                      var change = await getCryptoChange(
                                          getBlockChains()[i]['symbol']);

                                      yield {
                                        'price': cryptoPrice,
                                        'currencySymbol': symbol,
                                        'change': change
                                      };
                                      await Future.delayed(
                                          const Duration(minutes: 1));
                                    }
                                  }(),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.hasError) {
                                      print(snapshot.error);
                                    }
                                    if (snapshot.hasData) {
                                      var change = (snapshot.data
                                                  as Map)['change'] >
                                              0
                                          ? '+${formatMoney((snapshot.data as Map)['change'])}'
                                          : formatMoney(
                                              (snapshot.data as Map)['change']);

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${(snapshot.data as Map)['price'] == 0 ? '' : (snapshot.data as Map)['currencySymbol'] + formatMoney((snapshot.data as Map)['price'])}',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                ' ${(snapshot.data as Map)['change'] == 0 ? '' : change + '%'}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: (snapshot.data
                                                                    as Map)[
                                                                'change']
                                                            .toString()
                                                            .startsWith('-')
                                                        ? Color(0xffeb6a61)
                                                        : Color(0xff01aa78)),
                                              )
                                            ],
                                          ),
                                          StreamBuilder(stream: () async* {
                                            while (true) {
                                              yield await getEthBalance(
                                                  rpcUrl: getBlockChains()[i]
                                                      ['rpc']);
                                              await Future.delayed(
                                                  const Duration(minutes: 1));
                                            }
                                          }(), builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              print(snapshot.error);
                                            }
                                            ;
                                            if (snapshot.hasData) {
                                              return Text(
                                                '${formatMoney(snapshot.data)} ${getBlockChains()[i]['symbol']}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }
                                            return Text(
                                              '*** ${getBlockChains()[i]['symbol']}',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }),
                                        ],
                                      );
                                    } else
                                      return Text(
                                        '',
                                        style: TextStyle(fontSize: 15),
                                      );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ]),
                  )
                ],
              ),
            ),
          ]),
        ),
      ));

      blockChainsArray.add(Divider());
    }

    blockChainsArray.addAll([
      InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => Token(data: const {
                'name': 'Litecoin',
                'symbol': 'LTC',
                'default': 'LTC',
                'block explorer': 'https://live.blockcypher.com/ltc'
              }),
            ),
          );
        },
        child: Container(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/litecoin.png'),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Litecoin',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder(
                                  stream: () async* {
                                    while (true) {
                                      var currencyWithSymbol = jsonDecode(
                                          await rootBundle.loadString(
                                              'json/currency_symbol.json'));
                                      var defaultCurrency =
                                          (await SharedPreferences
                                                      .getInstance())
                                                  .getString(
                                                      'defaultCurrency') ??
                                              "USD";
                                      var symbol =
                                          (currencyWithSymbol[defaultCurrency]
                                              ['symbol']);
                                      var cryptoPrice =
                                          await getCryptoPrice('LTC');

                                      var change = await getCryptoChange('LTC');

                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');

                                      var getLitecoinDetails =
                                          await getLiteCoinFromMemnomic(
                                              seedPhrase);
                                      var accountDetails =
                                          await getLitecoinAddressDetails(
                                              getLitecoinDetails['address']);

                                      yield {
                                        'price': cryptoPrice,
                                        'currencySymbol': symbol,
                                        'change': change,
                                        'balance':
                                            accountDetails['final_balance']
                                      };
                                      await Future.delayed(
                                          const Duration(minutes: 1));
                                    }
                                  }(),
                                  builder: (ctx, snapshot) {
                                    if (snapshot.hasError) {
                                      print(snapshot.error);
                                    }
                                    if (snapshot.hasData) {
                                      var change = (snapshot.data
                                                  as Map)['change'] >
                                              0
                                          ? '+${formatMoney((snapshot.data as Map)['change'])}'
                                          : formatMoney(
                                              (snapshot.data as Map)['change']);

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${(snapshot.data as Map)['price'] == 0 ? '' : (snapshot.data as Map)['currencySymbol'] + formatMoney((snapshot.data as Map)['price'])}',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                ' ${(snapshot.data as Map)['change'] == 0 ? '' : change + '%'}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: (snapshot.data
                                                                    as Map)[
                                                                'change']
                                                            .toString()
                                                            .startsWith('-')
                                                        ? Color(0xffeb6a61)
                                                        : Color(0xff01aa78)),
                                              )
                                            ],
                                          ),
                                          Text(
                                            '${formatMoney((snapshot.data as Map)['balance'])} LTC',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        ],
                                      );
                                    } else
                                      return Text(
                                        '',
                                        style: TextStyle(fontSize: 15),
                                      );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ]),
                  )
                ],
              ),
            ),
          ]),
        ),
      ),
      Divider(),
      InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => Token(data: const {
                        'name': 'Dogecoin',
                        'symbol': 'DOGE',
                        'default': 'DOGE',
                        'block explorer': 'https://dogechain.info'
                      })));
        },
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/dogecoin.png'),
                ),
                SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dogecoin',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder(
                                stream: () async* {
                                  while (true) {
                                    var currencyWithSymbol = jsonDecode(
                                        await rootBundle.loadString(
                                            'json/currency_symbol.json'));
                                    var defaultCurrency =
                                        (await SharedPreferences.getInstance())
                                                .getString('defaultCurrency') ??
                                            "USD";
                                    var symbol =
                                        (currencyWithSymbol[defaultCurrency]
                                            ['symbol']);
                                    var cryptoPrice =
                                        await getCryptoPrice('DOGE');

                                    var change = await getCryptoChange('DOGE');

                                    var seedPhrase =
                                        (await SharedPreferences.getInstance())
                                            .getString('mmemomic');

                                    var getDogeCoinDetails =
                                        await getDogeCoinFromMemnomic(
                                            seedPhrase);
                                    var accountDetails =
                                        await getDogecoinAddressDetails(
                                            getDogeCoinDetails['address']);

                                    yield {
                                      'price': cryptoPrice,
                                      'currencySymbol': symbol,
                                      'change': change,
                                      'balance': accountDetails['final_balance']
                                    };
                                    await Future.delayed(
                                        const Duration(minutes: 1));
                                  }
                                }(),
                                builder: (ctx, snapshot) {
                                  if (snapshot.hasError) {
                                    print(snapshot.error);
                                  }
                                  if (snapshot.hasData) {
                                    var change = (snapshot.data
                                                as Map)['change'] >
                                            0
                                        ? '+${formatMoney((snapshot.data as Map)['change'])}'
                                        : formatMoney(
                                            (snapshot.data as Map)['change']);

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${(snapshot.data as Map)['price'] == 0 ? '' : (snapshot.data as Map)['currencySymbol'] + formatMoney((snapshot.data as Map)['price'])}',
                                              style: TextStyle(fontSize: 15),
                                            ),
                                            Text(
                                              ' ${(snapshot.data as Map)['change'] == 0 ? '' : change + '%'}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: (snapshot.data
                                                              as Map)['change']
                                                          .toString()
                                                          .startsWith('-')
                                                      ? Color(0xffeb6a61)
                                                      : Color(0xff01aa78)),
                                            )
                                          ],
                                        ),
                                        Text(
                                          '${formatMoney((snapshot.data as Map)['balance'])} DOGE',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      ],
                                    );
                                  } else
                                    return Text(
                                      '',
                                      style: TextStyle(fontSize: 15),
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                      ]),
                )
              ],
            ),
          ),
        ]),
      ),
      Divider(),
    ]);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 2));
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      CupertinoIcons.bell,
                      size: 30,
                      color: Color(0x00222222),
                    ),
                    StreamBuilder(stream: () async* {
                      while (true) {
                        double totalPrice = 0.0;
                        var currencyWithSymbol = jsonDecode(await rootBundle
                            .loadString('json/currency_symbol.json')) as Map;

                        var defaultCurrency =
                            (await SharedPreferences.getInstance())
                                    .getString('defaultCurrency') ??
                                "USD";

                        var symbol =
                            (currencyWithSymbol[defaultCurrency]['symbol']);

                        var seedPhrase = (await SharedPreferences.getInstance())
                            .getString('mmemomic');

                        var getBitCoinDetails =
                            await getBitCoinFromMemnomic(seedPhrase);
                        var bitCoinBalance = (await getBitcoinAddressDetails(
                            getBitCoinDetails['address']))['final_balance'];

                        var btcPrice = await getCryptoPrice('BTC');

                        var getLitecoinDetails =
                            await getLiteCoinFromMemnomic(seedPhrase);
                        var liteCoinBalance = (await getLitecoinAddressDetails(
                            getLitecoinDetails['address']))['final_balance'];

                        var litecoinPrice = await getCryptoPrice('LTC');

                        var getDogeCoinDetails =
                            await getDogeCoinFromMemnomic(seedPhrase);
                        var dogeCoinBalance = (await getDogecoinAddressDetails(
                            getDogeCoinDetails['address']))['final_balance'];

                        var dogeCoinPrice = await getCryptoPrice('DOGE');

                        totalPrice += btcPrice * bitCoinBalance;
                        totalPrice += litecoinPrice * liteCoinBalance;
                        totalPrice += dogeCoinPrice * dogeCoinBalance;

                        for (String i in getBlockChains().keys) {
                          final coinPrice = await getCryptoPrice(
                              getBlockChains()[i]['symbol']);

                          final coinBalance = await getEthBalance(
                              rpcUrl: getBlockChains()[i]['rpc']);

                          totalPrice += coinPrice * coinBalance;
                        }
                        yield {'totalPrice': totalPrice, 'symbol': symbol};
                        await Future.delayed(Duration(minutes: 1));
                      }
                    }(), builder: (context, snapshot) {
                      if (snapshot.hasError)
                        print(snapshot.error.toString() + 'bad');
                      if (snapshot.hasData) {
                        return Text(
                          '${(snapshot.data as Map)['symbol']}${formatMoney((snapshot.data as Map)['totalPrice'])}',
                          style: TextStyle(fontSize: 25),
                        );
                      } else
                        return Text(
                          '****',
                          style: TextStyle(fontSize: 25),
                        );
                    }),
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: ImportToken()));
                      },
                      icon: Icon(
                        Icons.menu,
                        size: 30,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  walletName,
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () async {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (ctx) => airdrop()));
                          },
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.umbrella,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Airdrop',
                                style: TextStyle(fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            var sweetAlert = await rootBundle
                                .loadString('dappBrowser/sweetalert.js');
                            var web3 = await rootBundle
                                .loadString('dappBrowser/web3.min.js');
                            var bundleProvider = await await rootBundle
                                .loadString('dappBrowser/bundle.js');
                            var seedPhrase =
                                (await SharedPreferences.getInstance())
                                    .getString('mmemomic');
                            var insertWeb3 = '''window.web3 = new Web3(
        new HDWalletProvider({
          mnemonic: {
            phrase:
              "${seedPhrase}",
          },
          providerOrUrl: "https://data-seed-prebsc-1-s1.binance.org:8545/",
          chainId: 97,
        })
      );''';

                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) => dapp(
                                        javascriptFiles:
                                            '${web3};${sweetAlert};${bundleProvider};${insertWeb3}')));
                          },
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.web,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Browser',
                                style: TextStyle(fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (ctx) => NFT()));
                          },
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.swap_horiz,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'NFT',
                                style: TextStyle(fontSize: 15),
                              )
                            ],
                          ),
                        ),
                      ]),
                ),
                SizedBox(height: 40),
              ]
                ..addAll(blockChainsArray)
                ..add(FutureBuilder(future: () async {
                  var sharedPrefToken = (await SharedPreferences.getInstance())
                      .getString('customTokenList');

                  var customTokenList;

                  if (sharedPrefToken == null) {
                    customTokenList = [];
                  } else {
                    customTokenList = jsonDecode(sharedPrefToken as String);
                  }

                  final walletContract = web3.DeployedContract(
                      web3.ContractAbi.fromJson(erc20Abi, 'MetaCoin'),
                      web3.EthereumAddress.fromHex(tokenContractAddress));
                  var pref = (await SharedPreferences.getInstance());
                  var seedPhrase = pref.getString('mmemomic');
                  var response = await getCryptoKeys(seedPhrase);
                  var appTokenDetails = {};
                  var appTokenKey = 'appTokenDetails';

                  if (pref.getString(appTokenKey) == null) {
                    final client = web3.Web3Client(
                      getBlockChains()[walletContractNetwork]['rpc'],
                      Client(),
                    );

                    final nameFunction = walletContract.function('name');
                    final symbolFunction = walletContract.function('symbol');
                    final decimalsFunction =
                        walletContract.function('decimals');

                    final name = (await client.call(
                            contract: walletContract,
                            function: nameFunction,
                            params: []))
                        .first;

                    final decimals = (await client.call(
                            contract: walletContract,
                            function: decimalsFunction,
                            params: []))
                        .first;

                    final symbol = (await client.call(
                            contract: walletContract,
                            function: symbolFunction,
                            params: []))
                        .first;

                    appTokenDetails = {
                      'name': name,
                      'symbol': symbol,
                      'balance': '***',
                      'contractAddress': tokenContractAddress,
                      'network': walletContractNetwork,
                      'rpc': getBlockChains()[walletContractNetwork]['rpc'],
                      'chainId': getBlockChains()[walletContractNetwork]
                          ['chainId'],
                      'block explorer': getBlockChains()[walletContractNetwork]
                          ['block explorer'],
                      'image': 'assets/logo.png'
                    };
                    await pref.setString(
                        appTokenKey, jsonEncode(appTokenDetails));
                  } else {
                    appTokenDetails = jsonDecode(pref.getString(appTokenKey));
                  }

                  var elementList = [appTokenDetails];

                  for (var element in (customTokenList as List)) {
                    elementList.add({
                      'name': element['name'],
                      'symbol': element['symbol'],
                      'balance': '***',
                      'contractAddress': element['contractAddress'],
                      'network': element['network'],
                      'chainId': element['chainId'],
                      'block explorer': element['block explorer'],
                      'rpc': element['rpc'],
                    });
                  }

                  return elementList;
                }(), builder: (ctx, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    return Container();
                  }

                  if (snapshot.hasData) {
                    var customTokensWidget = <Widget>[];

                    (snapshot.data as List).forEach((element) {
                      customTokensWidget.add(InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => Token(data: {
                                        'name': element['name'],
                                        'symbol': element['symbol'],
                                        'noPrice': true,
                                        'contractAddress':
                                            element['contractAddress'],
                                        'network': element['network'],
                                        'chainId': element['chainId'],
                                        'rpc': element['rpc'],
                                        'block explorer':
                                            element['block explorer'],
                                      })));
                        },
                        child: Column(
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.white,
                                          child: element['image'] != null
                                              ? null
                                              : Text(element['symbol']),
                                          backgroundImage:
                                              element['image'] != null
                                                  ? AssetImage(element['image'])
                                                  : null,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Flexible(
                                          child: Text(
                                            element['name'],
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: StreamBuilder(stream: () async* {
                                      while (true) {
                                        yield (await getErc20TokenPrice(
                                            element));
                                        await Future.delayed(
                                            Duration(minutes: 1));
                                      }
                                    }(), builder: (context, snapshot) {
                                      return Text(
                                        '${snapshot.hasData ? formatMoney(snapshot.data) : element['balance']} ${element['symbol']}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }),
                                  ),
                                ]),
                            Row(children: [
                              SizedBox(
                                height: 15,
                              ),
                              SizedBox(
                                height: 15,
                              ),
                            ]),
                            Row(children: [
                              Text(
                                '',
                                style: TextStyle(fontSize: 15),
                              ),
                              Text(''),
                            ]),
                            Divider()
                          ],
                        ),
                      ));
                    });
                    return Column(
                      children: customTokensWidget,
                    );
                  } else
                    return Container();
                })),
            ),
          ),
        ),
      ),
    );
  }
}

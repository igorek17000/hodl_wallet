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
import '../utils/getBlockChainWidget.dart';
import './dapp.dart';

class WalletMainBody extends StatefulWidget {
  @override
  _WalletMainBodyState createState() => _WalletMainBodyState();
}

class _WalletMainBodyState extends State<WalletMainBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    var blockChainsArray = <Widget>[];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 2));
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      CupertinoIcons.bell,
                      size: 30,
                      color: Color(0x00222222),
                    ),
                    StreamBuilder(stream: () async* {
                      while (true) {
                        var allCryptoPrice =
                            jsonDecode(await getCryptoPrice()) as Map;

                        var seedPhrase = (await SharedPreferences.getInstance())
                            .getString('mmemomic');
                        var currencyWithSymbol = jsonDecode(await rootBundle
                            .loadString('json/currency_symbol.json'));

                        var defaultCurrency =
                            (await SharedPreferences.getInstance())
                                    .getString('defaultCurrency') ??
                                "USD";
                        var symbol =
                            currencyWithSymbol[defaultCurrency]['symbol'];

                        var balance = await totalCryptoBalance(
                            seedPhrase: seedPhrase,
                            defaultCurrency: defaultCurrency,
                            allCryptoPrice: allCryptoPrice);

                        yield {'balance': balance, 'symbol': symbol};
                        await Future.delayed(forFetch);
                      }
                    }(), builder: (ctx, snapshot) {
                      return Text(
                        snapshot.hasData
                            ? '${snapshot.data['symbol']}${formatMoney(snapshot.data['balance'])}'
                            : '',
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
              ),
              StreamBuilder(stream: () async* {
                while (true) {
                  blockChainsArray = <Widget>[];

                  var allCryptoPrice =
                      jsonDecode(await getCryptoPrice()) as Map;

                  var seedPhrase = (await SharedPreferences.getInstance())
                      .getString('mmemomic');
                  var currencyWithSymbol = jsonDecode(
                      await rootBundle.loadString('json/currency_symbol.json'));

                  var defaultCurrency = (await SharedPreferences.getInstance())
                          .getString('defaultCurrency') ??
                      "USD";
                  var symbol = currencyWithSymbol[defaultCurrency]['symbol'];

                  var bitCoinPrice =
                      allCryptoPrice[coinGeckCryptoSymbolToID['BTC']]
                          [defaultCurrency.toLowerCase()];

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
                                        'block explorer':
                                            'https://www.blockchain.com/btc'
                                      })));
                        },
                        child: getBlockChainWidget(
                          name: 'Bitcoin',
                          image: const AssetImage('assets/bitcoin.png'),
                          priceWithCurrency: symbol + formatMoney(bitCoinPrice),
                          cryptoChange: allCryptoPrice[
                                  coinGeckCryptoSymbolToID['BTC']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                          cryptoAmount: StreamBuilder(
                            stream: () async* {
                              while (true) {
                                var getBitCoinDetails =
                                    await getBitCoinFromMemnomic(seedPhrase);
                                yield (await getBitcoinAddressDetails(
                                        getBitCoinDetails['address']))[
                                    'final_balance'];
                                await Future.delayed(forFetch);
                              }
                            }(),
                            builder: (ctx, snapshot) {
                              return Text(
                                '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : ''} BTC',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis),
                              );
                            },
                          ),
                        )),
                    Divider(),
                  ]);

                  for (String i in getBlockChains().keys) {
                    var cryptoPrice = allCryptoPrice[coinGeckCryptoSymbolToID[
                            getBlockChains()[i]['symbol']]]
                        [defaultCurrency.toLowerCase()];

                    blockChainsArray.add(InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => Token(data: {
                                        'name': i,
                                        'symbol': getBlockChains()[i]['symbol'],
                                        'default': getBlockChains()[i]
                                            ['symbol'],
                                        'block explorer': getBlockChains()[i]
                                            ['block explorer'],
                                        'rpc': getBlockChains()[i]['rpc'],
                                        'chainId': getBlockChains()[i]
                                            ['chainId'],
                                      })));
                        },
                        child: getBlockChainWidget(
                          name: i,
                          image: AssetImage(getBlockChains()[i]['image'] ??
                              'assets/ethereum_logo.png'),
                          priceWithCurrency: symbol + formatMoney(cryptoPrice),
                          cryptoChange: allCryptoPrice[coinGeckCryptoSymbolToID[
                                  getBlockChains()[i]['symbol']]]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                          cryptoAmount: StreamBuilder(
                            stream: () async* {
                              var cryptoBalance = await getEthBalance(
                                  rpcUrl: getBlockChains()[i]['rpc']);
                              yield cryptoBalance;
                            }(),
                            builder: (ctx, snapshot) {
                              return Text(
                                '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : ''} ${getBlockChains()[i]['symbol']}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis),
                              );
                            },
                          ),
                        )));

                    blockChainsArray.add(Divider());
                  }

                  var litecoinPrice =
                      allCryptoPrice[coinGeckCryptoSymbolToID['LTC']]
                          [defaultCurrency.toLowerCase()];

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
                                        'block explorer':
                                            'https://live.blockcypher.com/ltc'
                                      })));
                        },
                        child: getBlockChainWidget(
                          name: 'Litecoin',
                          image: const AssetImage('assets/litecoin.png'),
                          priceWithCurrency:
                              symbol + formatMoney(litecoinPrice),
                          cryptoChange: allCryptoPrice[
                                  coinGeckCryptoSymbolToID['LTC']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                          cryptoAmount: StreamBuilder(
                            stream: () async* {
                              var getLitecoinDetails =
                                  await getLiteCoinFromMemnomic(seedPhrase);
                              yield (await getLitecoinAddressDetails(
                                      getLitecoinDetails['address']))[
                                  'final_balance'];
                            }(),
                            builder: (ctx, snapshot) {
                              return Text(
                                '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : ''} LTC',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis),
                              );
                            },
                          ),
                        )),
                    Divider(),
                  ]);

                  var dogeCoinPrice =
                      allCryptoPrice[coinGeckCryptoSymbolToID['DOGE']]
                          [defaultCurrency.toLowerCase()];

                  blockChainsArray.addAll([
                    InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => Token(data: const {
                                        'name': 'Dogecoin',
                                        'symbol': 'DOGE',
                                        'default': 'DOGE',
                                        'block explorer':
                                            'https://dogechain.info'
                                      })));
                        },
                        child: getBlockChainWidget(
                          name: 'Dogecoin',
                          image: const AssetImage('assets/dogecoin.png'),
                          priceWithCurrency:
                              symbol + formatMoney(dogeCoinPrice),
                          cryptoChange: allCryptoPrice[
                                  coinGeckCryptoSymbolToID['DOGE']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                          cryptoAmount: StreamBuilder(
                            stream: () async* {
                              var getDogeCoinDetails =
                                  await getDogeCoinFromMemnomic(seedPhrase);
                              yield (await getDogecoinAddressDetails(
                                      getDogeCoinDetails['address']))[
                                  'final_balance'];
                            }(),
                            builder: (ctx, snapshot) {
                              return Text(
                                '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : ''} DOGE',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis),
                              );
                            },
                          ),
                        )),
                    Divider(),
                  ]);
                  yield {
                    'seedPhrase': seedPhrase,
                    'allCryptoPrice': allCryptoPrice,
                    'blockChainsArray': blockChainsArray,
                    'defaultCurrency': defaultCurrency
                  };
                  await Future.delayed(forFetch);
                }
              }(), builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error.toString());

                return Padding(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            CupertinoIcons.bell,
                            size: 30,
                            color: Color(0x00222222),
                          ),
                          Text(
                            walletName,
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                          IconButton(
                            onPressed: null,
                            icon: Icon(
                              Icons.menu,
                              size: 30,
                              color: Color(0x00222222),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () async {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => airdrop()));
                            },
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle),
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
                                    'Airdrops',
                                    style: TextStyle(fontSize: 15),
                                  )
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (ctx) => dapp()));
                            },
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle),
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
                                    'Browser ',
                                    style: TextStyle(fontSize: 15),
                                  )
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (ctx) => NFT()));
                            },
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle),
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
                                    'NFT shop',
                                    style: TextStyle(fontSize: 15),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                    ]
                      ..addAll(blockChainsArray)
                      ..add(FutureBuilder(future: () async {
                        var sharedPrefToken =
                            (await SharedPreferences.getInstance())
                                .getString('customTokenList');

                        var customTokenList;

                        if (sharedPrefToken == null) {
                          customTokenList = [];
                        } else {
                          customTokenList =
                              jsonDecode(sharedPrefToken as String);
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
                          final symbolFunction =
                              walletContract.function('symbol');
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
                            'balance': '',
                            'contractAddress': tokenContractAddress,
                            'network': walletContractNetwork,
                            'rpc': getBlockChains()[walletContractNetwork]
                                ['rpc'],
                            'chainId': getBlockChains()[walletContractNetwork]
                                ['chainId'],
                            'block explorer':
                                getBlockChains()[walletContractNetwork]
                                    ['block explorer'],
                            'image': 'assets/logo.png'
                          };
                          await pref.setString(
                              appTokenKey, jsonEncode(appTokenDetails));
                        } else {
                          appTokenDetails =
                              jsonDecode(pref.getString(appTokenKey));
                        }

                        var elementList = [appTokenDetails];

                        for (var element in (customTokenList as List)) {
                          elementList.add({
                            'name': element['name'],
                            'symbol': element['symbol'],
                            'balance': '',
                            'contractAddress': element['contractAddress'],
                            'network': element['network'],
                            'chainId': element['chainId'],
                            'block explorer': element['block explorer'],
                            'rpc': element['rpc'],
                          });
                        }

                        var currencyWithSymbol = jsonDecode(await rootBundle
                            .loadString('json/currency_symbol.json'));

                        var defaultCurrency =
                            (await SharedPreferences.getInstance())
                                    .getString('defaultCurrency') ??
                                "USD";
                        var nativeCurrency =
                            currencyWithSymbol[defaultCurrency]['symbol'];
                        return {
                          'elementList': elementList,
                          'nativeCurrency': nativeCurrency,
                        };
                      }(), builder: (ctx, snapshot) {
                        if (snapshot.hasError) {
                          print(snapshot.error.toString());
                          return Container();
                        }

                        if (snapshot.hasData) {
                          var customTokensWidget = <Widget>[];

                          (snapshot.data['elementList'] as List)
                              .forEach((element) {
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
                                child: getBlockChainWidget(
                                  name: element['name'],
                                  image: element['image'] != null
                                      ? AssetImage(element['image'])
                                      : null,
                                  priceWithCurrency:
                                      snapshot.data['nativeCurrency'] + '0',
                                  cryptoChange: 0,
                                  symbol: element['symbol'],
                                  cryptoAmount: StreamBuilder(
                                    stream: () async* {
                                      yield (await getERC20TokenBalance(
                                          element));
                                    }(),
                                    builder: (ctx, snapshot) {
                                      return Text(
                                        '${snapshot.hasData ? formatMoney(snapshot.data, isBalance: true) : element['balance']} ${element['symbol']}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    },
                                  ),
                                )));

                            customTokensWidget.add(
                              Divider(),
                            );
                          });

                          return Column(
                            children: customTokensWidget,
                          );
                        } else
                          return Container();
                      })),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

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
          child: StreamBuilder(stream: () async* {
            while (true) {
              blockChainsArray = <Widget>[];

              var allCryptoPrice = jsonDecode(await getCryptoPrice()) as Map;

              var seedPhrase =
                  (await SharedPreferences.getInstance()).getString('mmemomic');
              var currencyWithSymbol = jsonDecode(
                  await rootBundle.loadString('json/currency_symbol.json'));

              var defaultCurrency = (await SharedPreferences.getInstance())
                      .getString('defaultCurrency') ??
                  "USD";
              var symbol = currencyWithSymbol[defaultCurrency]['symbol'];

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
                      priceWithCurrency: symbol +
                          formatMoney(
                              allCryptoPrice[coinGeckCryptoSymbolToID['BTC']]
                                  [defaultCurrency.toLowerCase()]),
                      cryptoChange:
                          allCryptoPrice[coinGeckCryptoSymbolToID['BTC']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                      cryptoAmount: StreamBuilder(stream: () async* {
                        while (true) {
                          var getBitCoinDetails =
                              await getBitCoinFromMemnomic(seedPhrase);
                          yield (await getBitcoinAddressDetails(
                              getBitCoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                        }
                      }(), builder: (context, snapshot) {
                        return Text(
                          (snapshot.hasData ? formatMoney(snapshot.data) : '') +
                              ' BTC',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    )),
                Divider(),
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
                                    'block explorer': getBlockChains()[i]
                                        ['block explorer'],
                                    'rpc': getBlockChains()[i]['rpc'],
                                    'chainId': getBlockChains()[i]['chainId'],
                                  })));
                    },
                    child: getBlockChainWidget(
                      name: i,
                      image: AssetImage(getBlockChains()[i]['image'] ??
                          'assets/ethereum_logo.png'),
                      priceWithCurrency: symbol +
                          formatMoney(allCryptoPrice[coinGeckCryptoSymbolToID[
                                  getBlockChains()[i]['symbol']]]
                              [defaultCurrency.toLowerCase()]),
                      cryptoChange: allCryptoPrice[coinGeckCryptoSymbolToID[
                              getBlockChains()[i]['symbol']]]
                          [defaultCurrency.toLowerCase() + '_24h_change'],
                      cryptoAmount: StreamBuilder(stream: () async* {
                        while (true) {
                          yield await getEthBalance(
                              rpcUrl: getBlockChains()[i]['rpc']);
                          await Future.delayed(forFetch);
                        }
                      }(), builder: (ctx, snapshot) {
                        return Text(
                          (snapshot.hasData ? formatMoney(snapshot.data) : '') +
                              ' ${getBlockChains()[i]['symbol']}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    )));

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
                                    'block explorer':
                                        'https://live.blockcypher.com/ltc'
                                  })));
                    },
                    child: getBlockChainWidget(
                      name: 'Litecoin',
                      image: const AssetImage('assets/litecoin.png'),
                      priceWithCurrency: symbol +
                          formatMoney(
                              allCryptoPrice[coinGeckCryptoSymbolToID['LTC']]
                                  [defaultCurrency.toLowerCase()]),
                      cryptoChange:
                          allCryptoPrice[coinGeckCryptoSymbolToID['LTC']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                      cryptoAmount: StreamBuilder(stream: () async* {
                        while (true) {
                          var getLitecoinDetails =
                              await getLiteCoinFromMemnomic(seedPhrase);
                          yield (await getLitecoinAddressDetails(
                              getLitecoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                        }
                      }(), builder: (context, snapshot) {
                        return Text(
                          (snapshot.hasData ? formatMoney(snapshot.data) : '') +
                              ' LTC',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    )),
                Divider(),
              ]);

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
                                    'block explorer': 'https://dogechain.info'
                                  })));
                    },
                    child: getBlockChainWidget(
                      name: 'Dogecoin',
                      image: const AssetImage('assets/dogecoin.png'),
                      priceWithCurrency: symbol +
                          formatMoney(
                              allCryptoPrice[coinGeckCryptoSymbolToID['DOGE']]
                                  [defaultCurrency.toLowerCase()]),
                      cryptoChange:
                          allCryptoPrice[coinGeckCryptoSymbolToID['DOGE']]
                              [defaultCurrency.toLowerCase() + '_24h_change'],
                      cryptoAmount: StreamBuilder(stream: () async* {
                        while (true) {
                          var getDogeCoinDetails =
                              await getDogeCoinFromMemnomic(seedPhrase);
                          yield (await getDogecoinAddressDetails(
                              getDogeCoinDetails['address']))['final_balance'];
                          await Future.delayed(forFetch);
                        }
                      }(), builder: (context, snapshot) {
                        return Text(
                          (snapshot.hasData ? formatMoney(snapshot.data) : '') +
                              ' DOGE',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    )),
                Divider(),
              ]);
              yield {};
              await Future.delayed(forFetch);
            }
          }(), builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);
            return Padding(
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
                      Text(
                        '\$0.00',
                        style: TextStyle(fontSize: 25),
                      ),
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
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => airdrop()));
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
                              var provider = await rootBundle
                                  .loadString('dappBrowser/provider.js');

                              var reEnableJavascript =
                                  await rootBundle.loadString(
                                      'dappBrowser/reEnableJavascript.js');

                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => dapp(
                                            sweetAlert: sweetAlert,
                                            web3: web3,
                                            provider: provider,
                                            reEnableJavascript:
                                                reEnableJavascript,
                                          )));
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
                                  'Dapps',
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
                    var sharedPrefToken =
                        (await SharedPreferences.getInstance())
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
                        'block explorer':
                            getBlockChains()[walletContractNetwork]
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
                                            backgroundImage: element['image'] !=
                                                    null
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
                                          yield (await getERC20TokenBalance(
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
            );
          }),
        ),
      ),
    );
  }
}

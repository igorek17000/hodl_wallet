import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import '../config/colors.dart';
import '../config/styles.dart';
import '../utils/slideUpPanel.dart';
import 'package:web3dart/web3dart.dart' as web3;

class private_sale extends StatefulWidget {
  const private_sale({Key key}) : super(key: key);
  @override
  _private_saleState createState() => _private_saleState();
}

class _private_saleState extends State<private_sale>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = false;
  var error = '';
  var bnbAmountController = TextEditingController()..text = '1';
  var bnbPrice =
      'https://api.binance.com/api/v3/klines?symbol=BNBUSDT&interval=1m&limit=1';
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(Duration(seconds: 2));
        setState(() {});
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Private Sale',
                  style: suBtitle2,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text('0', style: s_normal),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Text('100', style: s_normal),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        LinearPercentIndicator(
                          lineHeight: 20.0,
                          percent: 0,
                          linearStrokeCap: LinearStrokeCap.butt,
                          progressColor: black,
                        ),
                        SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              StreamBuilder(stream: () async* {
                while (true) {
                  var pref = await SharedPreferences.getInstance();
                  
                  try {
                    final client = web3.Web3Client(
                      getBlockChains()[walletContractNetwork]['rpc'],
                      Client(),
                    );
                    final contract = web3.DeployedContract(
                        web3.ContractAbi.fromJson(erc20Abi, ''),
                        web3.EthereumAddress.fromHex(tokenContractAddress));

                    final tokenPriceFunction = contract.function('viewSale');

                    final tokenPrice = await client.call(
                        contract: contract,
                        function: tokenPriceFunction,
                        params: []);
                    var defaultCurrency =
                        (await SharedPreferences.getInstance())
                                .getString('defaultCurrency') ??
                            "usd";
                    var bnbPrice = (jsonDecode(await getCryptoPrice())
                            as Map)[coinGeckCryptoSymbolToID['BNB']]
                        [defaultCurrency];
                    var tokenPriceDouble =
                        pow(10, 18) / double.parse(tokenPrice[3].toString());

                    var currencyWithSymbol = jsonDecode(await rootBundle
                        .loadString('json/currency_symbol.json'));
                    var symbol =
                        (currencyWithSymbol[defaultCurrency]['symbol']);

                    await pref.setString(
                        privateSaleDataKey,
                        jsonEncode({
                          'bnbPrice': bnbPrice,
                          'tokenPrice': tokenPriceDouble,
                          'symbol': symbol
                        }));

                    yield {
                      'bnbPrice': bnbPrice,
                      'tokenPrice': tokenPriceDouble,
                      'symbol': symbol,
                      'success': true
                    };
                  } catch (e) {
                    var privateSaleSavedData =
                        pref.getString(privateSaleDataKey);

                    if (privateSaleSavedData != null) {
                      var privateSaleData = jsonDecode(privateSaleSavedData);
                      yield {
                        'bnbPrice': privateSaleData['bnbPrice'],
                        'tokenPrice': privateSaleData['tokenPrice'],
                        'symbol': privateSaleData['symbol'],
                        'success': true
                      };
                    } else {
                      yield {
                        'bnbPrice': '',
                        'tokenPrice': '',
                        'symbol': '',
                        'success': false
                      };
                    }
                  } finally {
                    await Future.delayed(forFetch);
                  }
                }
              }(), builder: (ctx, snapshot) {
                if (snapshot.hasData && snapshot.data['success']) {
                  double currentPrice = snapshot.data['bnbPrice'];
                  String symbol = snapshot.data['symbol'];

                  return Stack(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Card(
                            child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text('From',
                                          style: s12_18_agSemiboldGrey),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        final client = web3.Web3Client(
                                          getBlockChains()[
                                              walletContractNetwork]['rpc'],
                                          Client(),
                                        );
                                        var seedPhrase =
                                            (await SharedPreferences
                                                    .getInstance())
                                                .getString('mmemomic');

                                        var response =
                                            await getCryptoKeys(seedPhrase);
                                        var userBalance = (((await client.getBalance(
                                                            EthereumAddress
                                                                .fromHex(response[
                                                                    'eth_wallet_address'])))
                                                        .getInWei)
                                                    .toDouble() /
                                                pow(10, 18))
                                            .toString();
                                        setState(() {
                                          bnbAmountController.text =
                                              userBalance;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: Text('Use Max', style: s_normal),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Container(
                                              width: double.infinity,
                                              child: TextFormField(
                                                onChanged: (value) {
                                                  setState(() {});
                                                },
                                                cursorColor: black,
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                style: h4,
                                                decoration: InputDecoration(
                                                    border: InputBorder.none),
                                                controller: bnbAmountController,
                                              ),
                                            )),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: SvgPicture.asset(
                                                'assets/svgs/circular_grey.svg',
                                                height: 20),
                                          ),
                                          Text('BNB', style: m_agRegular),
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: SvgPicture.asset(
                                                'assets/svgs/arrow_down.svg'),
                                          ),
                                        ],
                                      )
                                    ]),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          '${symbol}${formatMoney(currentPrice * (double.tryParse(bnbAmountController.text) ?? 0))}',
                                          style: m_agRegular_grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 150),
                        child: Card(
                            child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text('To',
                                          style: s12_18_agSemiboldGrey),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Text('', style: s_normal),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: Text(
                                              '${formatMoney(snapshot.data['tokenPrice'] * (double.tryParse(bnbAmountController.text) ?? 0))}',
                                              style: h4),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: SvgPicture.asset(
                                                'assets/svgs/circular_grey.svg',
                                                height: 20),
                                          ),
                                          Text(walletAbbr, style: m_agRegular),
                                          Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: SvgPicture.asset(
                                                'assets/svgs/arrow_down.svg'),
                                          ),
                                        ],
                                      )
                                    ]),
                                Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        '${symbol}${formatMoney(currentPrice * (double.tryParse(bnbAmountController.text) ?? 0))}',
                                        style: m_agRegular_grey,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: secondary5,
                            ),
                            width: 100,
                            height: 60,
                            child: Icon(
                              Icons.arrow_downward,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else
                  return CircularProgressIndicator(
                    color: black,
                  );
              }),
              SizedBox(
                height: 20,
              ),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      var transactionHash;
                      bool purchasedSuccessfully = true;
                      try {
                        final client = web3.Web3Client(
                          getBlockChains()[walletContractNetwork]['rpc'],
                          Client(),
                        );
                        var seedPhrase = (await SharedPreferences.getInstance())
                            .getString('mmemomic');
                        var response = await getCryptoKeys(seedPhrase);
                        final credentials =
                            await client.credentialsFromPrivateKey(
                                response['eth_wallet_privateKey']);

                        final contract = web3.DeployedContract(
                            web3.ContractAbi.fromJson(erc20Abi, walletName),
                            web3.EthereumAddress.fromHex(tokenContractAddress));

                        final tokenSale = contract.function(
                          'tokenSale',
                        );
                        final trans = await client.signTransaction(
                            credentials,
                            Transaction.callContract(
                              contract: contract,
                              function: tokenSale,
                              parameters: [
                                web3.EthereumAddress.fromHex(
                                    '0x0000000000000000000000000000000000000000'),
                              ],
                              value: web3.EtherAmount.inWei(BigInt.from(
                                  (double.tryParse(bnbAmountController.text
                                              .trim()) ??
                                          0) *
                                      pow(10, 18))),
                            ),
                            chainId: getBlockChains()[walletContractNetwork]
                                ['chainId']);

                        transactionHash =
                            (await client.sendRawTransaction(trans));
                        print(transactionHash);
                      } catch (e) {
                        purchasedSuccessfully = false;
                      }
                      slideUpPanel(context,
                          StatefulBuilder(builder: (ctx, setState) {
                        var private_saleBscScan =
                            getBlockChains()[walletContractNetwork]
                                    ['block explorer'] +
                                '/tx/$transactionHash';
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              purchasedSuccessfully
                                  ? SvgPicture.asset(
                                      'assets/svgs/icon_wrapper.svg')
                                  : Image.asset(
                                      'assets/images/failedIcon.png',
                                      scale: 10,
                                    ),
                              Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                  purchasedSuccessfully
                                      ? 'Presale Token Purchased Successfully'
                                      : 'Presale Token Purchase Failed',
                                  style: title1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Click the link below to view transaction on Bscsacan',
                                  style: s_agRegular_gray12,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: GestureDetector(
                                    child: isLoading
                                        ? CircularProgressIndicator(
                                            color: blue5,
                                          )
                                        : Text(
                                            private_saleBscScan,
                                            style:
                                                s_agRegularLinkBlue5Underline,
                                            textAlign: TextAlign.center,
                                          ),
                                    onTap: () async {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      try {
                                        await launch(private_saleBscScan);
                                      } catch (e) {}
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }),
                              ),
                            ],
                          ),
                        );
                      }));

                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: isLoading
                        ? CircularProgressIndicator(
                            color: primary5,
                          )
                        : Text('Swap', style: l_large_normal_primary5),
                    style: ElevatedButton.styleFrom(
                      primary: black,
                      padding: EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // <-- Radius
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

import 'dart:convert';
import 'dart:math';

import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cryptowallet/screens/qrCodeScan.dart';
import 'package:cryptowallet/screens/receiveToken.dart';
import 'package:cryptowallet/screens/sendToken.dart';
import 'package:cryptowallet/screens/transferToken.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class SendToken extends StatefulWidget {
  var data;
  var seedPhrase;
  var addressData;
  SendToken({this.data, this.seedPhrase, this.addressData});

  @override
  _SendTokenState createState() => _SendTokenState();
}

class _SendTokenState extends State<SendToken> {
  var recipientAddressController = TextEditingController();
  var amount = TextEditingController();
  final GlobalKey<FormState> formState = GlobalKey<FormState>();
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
                Form(
                  key: formState,
                  child: Row(
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
                        'Send ${widget.data['symbol']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      InkWell(
                        onTap: () async {
                          // check if recipinet is valid eth address

                          print(amount.text);
                          if (double.tryParse(amount.text.trim()) == null) {
                            _scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text('Please enter an amount'),
                              ),
                            );
                            return;
                          }
                          try {
                            if (widget.data['default'] == 'BTC') {
                            } else if (widget.data['default'] == 'BTCTEST') {
                            } else if (widget.data['default'] == 'LTC') {
                            } else if (widget.data['default'] == 'DOGE') {
                            } else {
                              try {
                                web3.EthereumAddress.fromHex(
                                    recipientAddressController.text.trim());
                              } catch (e) {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                  content: Text("Resolving ENS name"),
                                ));
                                var address = await resolveEnsRequst(
                                    recipientAddressController.text.trim());

                                print(address);
                                if (address['success']) {
                                  setState(() {
                                    recipientAddressController.text =
                                        address['msg'];
                                  });
                                } else {
                                  _scaffoldKey.currentState
                                      .showSnackBar(SnackBar(
                                    content: Text("Failed resolving ENS"),
                                  ));
                                  return;
                                }
                              }
                              web3.EthereumAddress.fromHex(
                                  recipientAddressController.text.trim());
                            }
                          } catch (e) {
                            _scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Can not send ${widget.data['symbol']} to this address'),
                              ),
                            );
                            return;
                          }
                          if (amount.text.trim() == "" ||
                              recipientAddressController.text.trim() == "")
                            return;
                          var data = {
                            ...(widget.data as Map),
                            'amount': amount.text.trim(),
                            'recipient': recipientAddressController.text.trim()
                          };
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => TransferToken(
                                data: data,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'CONTINUE',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                TextFormField(
                  validator: (value) {
                    if (value?.trim() == '')
                      return 'Recipient address is required';
                    else
                      return null;
                  },
                  controller: widget.addressData == null
                      ? recipientAddressController
                      : recipientAddressController
                    ..text = widget.addressData,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => qrCodeScan(
                                    routeKey: 'sendToken',
                                    data: widget.data,
                                    seedPhrase: widget.seedPhrase)));
                      },
                    ),
                    hintText: 'Recipient Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                widget.data['isNFT'] != null
                    ? TextFormField(
                        enabled: false,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value?.trim() == '')
                            return 'Amount is required';
                          else
                            return null;
                        },
                        controller: amount
                          ..text = widget.data['tokenId'].toString(),
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                        ),
                      )
                    : TextFormField(
                        enabled: true,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value?.trim() == '')
                            return 'Amount is required';
                          else
                            return null;
                        },
                        controller: amount,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Text('max'),
                            onPressed: () async {
                              if (widget.data['contractAddress'] != null) {
                                var seedPhrase =
                                    (await SharedPreferences.getInstance())
                                        .getString('mmemomic');
                                var response = await getCryptoKeys(seedPhrase);
                                final client = web3.Web3Client(
                                  widget.data['rpc'],
                                  Client(),
                                );

                                final credentials =
                                    await client.credentialsFromPrivateKey(
                                        response['eth_wallet_privateKey']);

                                final contract = web3.DeployedContract(
                                    web3.ContractAbi.fromJson(
                                        widget.data['isNFT'] != null
                                            ? erc721Abi
                                            : erc20Abi,
                                        widget.data['name']),
                                    web3.EthereumAddress.fromHex(
                                        widget.data['contractAddress']));

                                final balanceFunction =
                                    contract.function('balanceOf');

                                final decimalsFunction =
                                    contract.function('decimals');

                                final balance = await client.call(
                                    contract: contract,
                                    function: balanceFunction,
                                    params: [
                                      EthereumAddress.fromHex(
                                          response['eth_wallet_address'])
                                    ]);

                                final decimals = (await client.call(
                                        contract: contract,
                                        function: decimalsFunction,
                                        params: []))
                                    .first;

                                amount.text = (double.parse(
                                            balance.first.toString()) /
                                        pow(10,
                                            double.parse(decimals.toString())))
                                    .toString();
                              } else if (widget.data['default'] != null) {
                                if (widget.data['default'] == 'BTC') {
                                  var seedPhrase =
                                      (await SharedPreferences.getInstance())
                                          .getString('mmemomic');

                                  var getBitCoinDetails =
                                      await getBitCoinFromMemnomic(seedPhrase);
                                  var accountDetails =
                                      await getBitcoinAddressDetails(
                                          getBitCoinDetails['address']);

                                  amount.text = accountDetails['final_balance']
                                      .toString();
                                } else if (widget.data['default'] ==
                                    'BTCTEST') {
                                  var seedPhrase =
                                      (await SharedPreferences.getInstance())
                                          .getString('mmemomic');

                                  var getBitCoinDetails =
                                      await getBitCoinFromMemnomic(seedPhrase,
                                          istestnet: true);
                                  var accountDetails =
                                      await getBitcoinAddressDetails(
                                          getBitCoinDetails['address'],
                                          istestnet: true);

                                  amount.text = accountDetails['final_balance']
                                      .toString();
                                } else if (widget.data['default'] == 'LTC') {
                                  var seedPhrase =
                                      (await SharedPreferences.getInstance())
                                          .getString('mmemomic');

                                  var getLitecoinDetails =
                                      await getLiteCoinFromMemnomic(seedPhrase);
                                  var accountDetails =
                                      await getLitecoinAddressDetails(
                                          getLitecoinDetails['address']);

                                  amount.text = accountDetails['final_balance']
                                      .toString();
                                } else if (widget.data['default'] == 'DOGE') {
                                  var seedPhrase =
                                      (await SharedPreferences.getInstance())
                                          .getString('mmemomic');

                                  var getDogeCoinDetails =
                                      await getDogeCoinFromMemnomic(seedPhrase);
                                  var accountDetails =
                                      await getDogecoinAddressDetails(
                                          getDogeCoinDetails['address']);

                                  amount.text = accountDetails['final_balance']
                                      .toString();
                                } else {
                                  amount.text = (await getEthBalance(
                                          rpcUrl: widget.data['rpc']))
                                      .toString();
                                }
                              }
                            },
                          ),
                          hintText: 'Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

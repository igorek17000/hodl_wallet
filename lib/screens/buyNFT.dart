import 'dart:math';

import 'package:cryptowallet/config/styles.dart';
import 'package:cryptowallet/screens/NFT.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class BuyNFT extends StatefulWidget {
  int tokenId;
  String imageURL;
  double price;

  BuyNFT({this.tokenId, this.imageURL, this.price});

  @override
  State<BuyNFT> createState() => _BuyNFTState();
}

class _BuyNFTState extends State<BuyNFT> {
  var priceController = TextEditingController();
  bool isLoading = false;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: StreamBuilder<Object>(stream: () async* {
                while (true) {
                  var seedPhrase = (await SharedPreferences.getInstance())
                      .getString('mmemomic');
                  var response = await getCryptoKeys(seedPhrase);
                  final client = web3.Web3Client(
                    getBlockChains()[walletNFTContractNetwork]['rpc'],
                    Client(),
                  );

                  final credentials = await client.credentialsFromPrivateKey(
                      response['eth_wallet_privateKey']);

                  final contract = web3.DeployedContract(
                      web3.ContractAbi.fromJson(erc721Abi, ''),
                      web3.EthereumAddress.fromHex(tokenNFTContractAddress));

                  final buy = contract.function('buy');

                  final transactionFee = await getTransactionFee(
                      getBlockChains()[walletNFTContractNetwork]['rpc'],
                      buy.encodeCall([
                        BigInt.from(widget.tokenId),
                      ]),
                      web3.EthereumAddress.fromHex(
                          response['eth_wallet_address']),
                      web3.EthereumAddress.fromHex(tokenNFTContractAddress),
                      value: widget.price);
                  var userBalance = (await client.getBalance(
                              EthereumAddress.fromHex(
                                  response['eth_wallet_address'])))
                          .getInWei
                          .toDouble() /
                      pow(10, 18);
                  yield {
                    'transactionFeeDouble': (transactionFee / pow(10, 18)),
                    'userTotalBalance': userBalance
                  };
                  await Future.delayed(forFetch);
                }
              }(), builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: GestureDetector(
                              child: Icon(
                                Icons.arrow_back_ios,
                                size: 15,
                              ),
                              onTap: () {
                                if (Navigator.canPop(context))
                                  Navigator.pop(context);
                              },
                            ),
                          ),
                          Text(
                            'Error ',
                            style: suBtitle2,
                            textAlign: TextAlign.center,
                          ),
                          Visibility(
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 15,
                            ),
                            visible: false,
                          )
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Image.network(widget.imageURL),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                          'There was an error while checking fees , increase your balance and try again')
                    ],
                  );
                if (snapshot.hasData) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: GestureDetector(
                              child: Icon(
                                Icons.arrow_back_ios,
                                size: 15,
                              ),
                              onTap: () {
                                if (Navigator.canPop(context))
                                  Navigator.pop(context);
                              },
                            ),
                          ),
                          Text(
                            'Confirm ',
                            style: suBtitle2,
                            textAlign: TextAlign.center,
                          ),
                          Visibility(
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 15,
                            ),
                            visible: false,
                          )
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Image.network(widget.imageURL),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                          'Transaction Fee: ${(snapshot.data as Map)['transactionFeeDouble']} ${getBlockChains()[walletNFTContractNetwork]['symbol']}'),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                          'Your Balance: ${(snapshot.data as Map)['userTotalBalance'] == 0 ? '***' : (snapshot.data as Map)['userTotalBalance']} ${getBlockChains()[walletNFTContractNetwork]['symbol']}'),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20)),
                        child: RaisedButton(
                          onPressed: (snapshot.data
                                          as Map)['transactionFeeDouble'] ==
                                      0 ||
                                  (snapshot.data as Map)['userTotalBalance'] <
                                      (snapshot.data
                                          as Map)['transactionFeeDouble']
                              ? null
                              : () async {
                                  try {
                                    final client = web3.Web3Client(
                                      getBlockChains()[walletNFTContractNetwork]
                                          ['rpc'],
                                      Client(),
                                    );
                                    var seedPhrase =
                                        (await SharedPreferences.getInstance())
                                            .getString('mmemomic');
                                    var response =
                                        await getCryptoKeys(seedPhrase);
                                    final credentials =
                                        await client.credentialsFromPrivateKey(
                                            response['eth_wallet_privateKey']);

                                    final contract = web3.DeployedContract(
                                        web3.ContractAbi.fromJson(
                                            erc721Abi, ''),
                                        web3.EthereumAddress.fromHex(
                                            tokenNFTContractAddress));

                                    final buy = contract.function('buy');
                                    final trans = await client.signTransaction(
                                        credentials,
                                        Transaction.callContract(
                                            contract: contract,
                                            function: buy,
                                            parameters: [
                                              BigInt.from(widget.tokenId),
                                            ],
                                            value: web3.EtherAmount.inWei(
                                                BigInt.from(widget.price))),
                                        chainId: getBlockChains()[
                                                walletNFTContractNetwork]
                                            ['chainId']);

                                    print(trans);

                                    var transactionHash = (await client
                                        .sendRawTransaction(trans));

                                    print(transactionHash);
                                    _scaffoldKey.currentState.showSnackBar(
                                        SnackBar(content: Text('NFT bought')));
                                  } catch (e) {
                                    print(e);
                                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                                        content: Text(
                                            'Could not sell your NFT, or NFT is already for sale')));
                                  }
                                },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Confirm'),
                          ),
                        ),
                      )
                    ],
                  );
                } else
                  return Center(
                    child: CircularProgressIndicator(),
                  );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

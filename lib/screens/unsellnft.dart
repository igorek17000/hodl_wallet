import 'dart:math';

import 'package:cryptowallet/screens/NFT.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class UnSellNFT extends StatefulWidget {
  int tokenId;
  String imageURL;

  UnSellNFT({this.tokenId, this.imageURL});

  @override
  State<UnSellNFT> createState() => _UnSellNFTState();
}

class _UnSellNFTState extends State<UnSellNFT> {
  var priceController = TextEditingController();
  bool isLoading = false;
  double transactionFeeDouble = 0.0;
  double userTotalBalance = 0.0;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            child: StreamBuilder(stream: () async* {
              var seedPhrase =
                  (await SharedPreferences.getInstance()).getString('mmemomic');
              var response = await getCryptoKeys(seedPhrase);
              final client = web3.Web3Client(
                getBlockChains()[walletNFTContractNetwork]['rpc'],
                Client(),
              );

              final credentials = await client
                  .credentialsFromPrivateKey(response['eth_wallet_privateKey']);

              final contract = web3.DeployedContract(
                  web3.ContractAbi.fromJson(erc721Abi, ''),
                  web3.EthereumAddress.fromHex(tokenNFTContractAddress));

              final disallowBuy = contract.function('disallowBuy');

              final transactionFee = await getTransactionFee(
                getBlockChains()[walletNFTContractNetwork]['rpc'],
                disallowBuy.encodeCall([
                  BigInt.from(widget.tokenId),
                ]),
                web3.EthereumAddress.fromHex(response['eth_wallet_address']),
                web3.EthereumAddress.fromHex(tokenNFTContractAddress),
              );
              var userBalance = (await client.getBalance(
                          EthereumAddress.fromHex(
                              response['eth_wallet_address'])))
                      .getInWei
                      .toDouble() /
                  pow(10, 18);
              setState(() {
                transactionFeeDouble = (transactionFee / pow(10, 18));
                userTotalBalance = userBalance;
              });
            }(), builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      widget.imageURL,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                        'Transaction Fee: ${transactionFeeDouble} ${getBlockChains()[walletNFTContractNetwork]['symbol']}'),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                        'Your Balance: ${userTotalBalance == 0 ? '***' : userTotalBalance} ${getBlockChains()[walletNFTContractNetwork]['symbol']}'),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20)),
                      child: RaisedButton(
                        onPressed: transactionFeeDouble == 0 ||
                                userTotalBalance < transactionFeeDouble
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });
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
                                      web3.ContractAbi.fromJson(erc721Abi, ''),
                                      web3.EthereumAddress.fromHex(
                                          tokenNFTContractAddress));

                                  final disallowBuy =
                                      contract.function('disallowBuy');
                                  final trans = await client.signTransaction(
                                      credentials,
                                      Transaction.callContract(
                                        contract: contract,
                                        function: disallowBuy,
                                        parameters: [
                                          BigInt.from(widget.tokenId),
                                        ],
                                      ),
                                      chainId: getBlockChains()[
                                          walletNFTContractNetwork]['chainId']);

                                  print(trans);

                                  var transactionHash =
                                      (await client.sendRawTransaction(trans));

                                  print(transactionHash);
                                  _scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('NFT Unlisted on market')));

                                  setState(() {
                                    isLoading = false;
                                  });
                                } catch (e) {
                                  print(e);
                                  _scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Could not unlist your NFT')));
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              },
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: isLoading
                              ? Container(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('UNLIST FROM MARKET'),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

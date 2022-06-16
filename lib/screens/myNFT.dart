import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/config/styles.dart';
import 'package:cryptowallet/screens/sellnft.dart';
import 'package:cryptowallet/screens/sendToken.dart';
import 'package:cryptowallet/screens/unsellnft.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class MyNFT extends StatefulWidget {
  @override
  _MyNFTState createState() => _MyNFTState();
}

class _MyNFTState extends State<MyNFT> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            child: Container(
              constraints:
                  BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: StreamBuilder<Object>(stream: () async* {
                  while (true) {
                    try {
                      final client = web3.Web3Client(
                        getBlockChains()[walletNFTContractNetwork]['rpc'],
                        Client(),
                      );
                      final contract = web3.DeployedContract(
                          web3.ContractAbi.fromJson(erc721Abi, 'MetaCoin'),
                          web3.EthereumAddress.fromHex(
                              tokenNFTContractAddress));

                      var seedPhrase = (await SharedPreferences.getInstance())
                          .getString('mmemomic');
                      var response = await getCryptoKeys(seedPhrase);

                      final balanceFunction = contract.function('balanceOf');
                      final tokenOfOwnerByIndex =
                          contract.function('tokenOfOwnerByIndex');
                      final tokenMetadataURI = contract.function('tokenURI');

                      final balance = int.parse((await client.call(
                              contract: contract,
                              function: balanceFunction,
                              params: [
                            EthereumAddress.fromHex(
                                response['eth_wallet_address'])
                          ]))
                          .first
                          .toString());

                      var nftItems = [];

                      for (int i = 0; i < balance; i++) {
                        final tokenId = int.parse((await client.call(
                                contract: contract,
                                function: tokenOfOwnerByIndex,
                                params: [
                              EthereumAddress.fromHex(
                                  response['eth_wallet_address']),
                              BigInt.from(i)
                            ]))
                            .first
                            .toString());
                        var tokenMetadataURLRes = (await client.call(
                                contract: contract,
                                function: tokenMetadataURI,
                                params: [BigInt.from(tokenId)]))
                            .first
                            .toString();

                        if (tokenMetadataURLRes.startsWith('ipfs://')) {
                          tokenMetadataURLRes =
                              'https://ipfs.io/ipfs/${tokenMetadataURLRes.split('ipfs://')[1]}';
                        }

                        print(tokenMetadataURLRes);
                        final tokenMetaData = jsonDecode(
                            (await get(Uri.parse(tokenMetadataURLRes)))
                                .body) as Map;

                        print(tokenMetaData);

                        tokenMetaData['tokenId'] = tokenId;
                        if (tokenMetaData['image'] != null) {
                          nftItems.add(tokenMetaData);
                        }
                      }
                      yield nftItems;
                    } catch (e) {
                      print(e);
                      yield [];
                    }
                    await Future.delayed(forFetch);
                  }
                }(), builder: (context, snapshot) {
                  if (snapshot.hasError) print(snapshot.error);
                  var nftWidgets = <Widget>[];
                  if (snapshot.hasData) {
                    var dataList = snapshot.data as List;

                    print(dataList);

                    for (int i = 0; i < dataList.length; i++) {
                      nftWidgets.add(
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(children: [
                              Image.network(dataList[i]['image'],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'tokenId',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(dataList[i]['tokenId'].toString())
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(dataList[i]['name'])
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Description',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(dataList[i]['description'])
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              StreamBuilder(stream: () async* {
                                try {
                                  var seedPhrase =
                                      (await SharedPreferences.getInstance())
                                          .getString('mmemomic');
                                  var response =
                                      await getCryptoKeys(seedPhrase);
                                  final client = web3.Web3Client(
                                    getBlockChains()[walletNFTContractNetwork]
                                        ['rpc'],
                                    Client(),
                                  );

                                  final credentials =
                                      await client.credentialsFromPrivateKey(
                                          response['eth_wallet_privateKey']);

                                  final contract = web3.DeployedContract(
                                      web3.ContractAbi.fromJson(erc721Abi, ''),
                                      web3.EthereumAddress.fromHex(
                                          tokenNFTContractAddress));

                                  final mintedNFTPricesFunction =
                                      contract.function('mintedNFTPrices');

                                  final mintedNFTPrices = await client.call(
                                      contract: contract,
                                      function: mintedNFTPricesFunction,
                                      params: [
                                        BigInt.from(dataList[i]['tokenId'])
                                      ]);
                                  yield {
                                    'price': double.parse(
                                        mintedNFTPrices.first.toString())
                                  };
                                  return;
                                } catch (e) {
                                  yield {'price': 0};
                                  return;
                                }
                              }(), builder: (context, snapshot) {
                                if (snapshot.hasError) print(snapshot.error);
                                if (snapshot.hasData) {
                                  var data = snapshot.data as Map;
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Price',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              '${data['price'] / pow(10, 18)} ${getBlockChains()[walletNFTContractNetwork]['symbol']}')
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        width: double.infinity,
                                        child: RaisedButton(
                                          onPressed: () async {
                                            var seedPhrase =
                                                (await SharedPreferences
                                                        .getInstance())
                                                    .getString('mmemonic');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (ctx) => SendToken(
                                                  seedPhrase: seedPhrase,
                                                  data: {
                                                    'name': dataList[i]['name'],
                                                    'symbol':
                                                        '${dataList[i]['name']}  #${dataList[i]['tokenId']}',
                                                    'isNFT': true,
                                                    'tokenId': dataList[i]
                                                        ['tokenId'],
                                                    'contractAddress':
                                                        tokenNFTContractAddress,
                                                    'network':
                                                        walletNFTContractNetwork,
                                                    'rpc': getBlockChains()[
                                                            walletNFTContractNetwork]
                                                        ['rpc'],
                                                    'chainId': getBlockChains()[
                                                            walletNFTContractNetwork]
                                                        ['chainId'],
                                                    'block explorer':
                                                        getBlockChains()[
                                                                walletNFTContractNetwork]
                                                            ['block explorer'],
                                                    'image': 'assets/logo.png'
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text('SEND'),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        width: double.infinity,
                                        child: RaisedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (ctx) =>
                                                    data['price'] == 0
                                                        ? SellNFT(
                                                            tokenId: dataList[i]
                                                                ['tokenId'],
                                                            imageURL:
                                                                dataList[i]
                                                                    ['image'],
                                                          )
                                                        : UnSellNFT(
                                                            tokenId: dataList[i]
                                                                ['tokenId'],
                                                            imageURL:
                                                                dataList[i]
                                                                    ['image'],
                                                          ),
                                              ),
                                            );
                                          },
                                          child: Text(data['price'] == 0
                                              ? 'SELL'
                                              : 'UNSELL'),
                                        ),
                                      ),
                                    ],
                                  );
                                } else
                                  return Container();
                              })
                            ]),
                          ),
                        ),
                      );
                      nftWidgets.add(Divider());
                    }
                  }
                  return Column(
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
                            'My ${walletName} NFTs',
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
                    ]..addAll(snapshot.hasData
                        ? nftWidgets
                        : [Center(child: CircularProgressIndicator())]),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/config/styles.dart';
import 'package:cryptowallet/screens/buyNFT.dart';
import 'package:cryptowallet/screens/sellnft.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class NFTMarketPlace extends StatefulWidget {
  @override
  _NFTMarketPlaceState createState() => _NFTMarketPlaceState();
}

class _NFTMarketPlaceState extends State<NFTMarketPlace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                      web3.EthereumAddress.fromHex(tokenNFTContractAddress));

                  var seedPhrase = (await SharedPreferences.getInstance())
                      .getString('mmemomic');
                  var response = await getCryptoKeys(seedPhrase);

                  final totalItemForSaleFunction =
                      contract.function('totalItemForSale');
                  final tokenForSale = contract.function('tokenForSale');
                  final ownerOfFunction = contract.function('ownerOf');
                  final tokenMetadataURI = contract.function('tokenURI');

                  final totalItem = int.parse((await client.call(
                          contract: contract,
                          function: totalItemForSaleFunction,
                          params: []))
                      .first
                      .toString());

                  var nftItems = [];

                  for (int i = 0; i < totalItem; i++) {
                    final tokenId = int.parse((await client.call(
                            contract: contract,
                            function: tokenForSale,
                            params: [BigInt.from(i)]))
                        .first
                        .toString());

                    var tokenMetadataURLRes = (await client.call(
                            contract: contract,
                            function: tokenMetadataURI,
                            params: [BigInt.from(tokenId)]))
                        .first
                        .toString();
                    var ownerRes = (await client.call(
                            contract: contract,
                            function: ownerOfFunction,
                            params: [BigInt.from(tokenId)]))
                        .first
                        .toString();
                    var tokenOwer = (await client.call(
                            contract: contract,
                            function: tokenMetadataURI,
                            params: [BigInt.from(tokenId)]))
                        .first
                        .toString();

                    if (tokenMetadataURLRes.startsWith('ipfs://')) {
                      tokenMetadataURLRes =
                          'https://ipfs.io/ipfs/${tokenMetadataURLRes.split('ipfs://')[1]}';
                    }

                    final tokenMetaData = jsonDecode(
                            (await get(Uri.parse(tokenMetadataURLRes))).body)
                        as Map;

                    tokenMetaData['tokenId'] = tokenId;
                    tokenMetaData['owner'] = ownerRes.toLowerCase();
                    tokenMetaData['currentUserAddress'] =
                        response['eth_wallet_address'].toString().toLowerCase();

                    if (tokenMetaData['image'] != null) {
                      nftItems.add(tokenMetaData);
                    }
                  }
                  yield nftItems;
                } catch (e) {
                  print(e.toString() + ' o o');
                  yield [];
                }
                await Future.delayed(forFetch);
              }
            }(), builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);
              var nftWidgets = <Widget>[];
              if (snapshot.hasData) {
                var dataList = snapshot.data as List;

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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'tokenId',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(dataList[i]['tokenId'].toString())
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(dataList[i]['name'])
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                              var response = await getCryptoKeys(seedPhrase);
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
                                  dataList[i]['owner'] !=
                                          dataList[i]['currentUserAddress']
                                      ? Container(
                                          width: double.infinity,
                                          child: RaisedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (ctx) => BuyNFT(
                                                    price: data['price'],
                                                    tokenId: dataList[i]
                                                        ['tokenId'],
                                                    imageURL: dataList[i]
                                                        ['image'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text('BUY'),
                                          ),
                                        )
                                      : Container(),
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
                        'Buy ${walletName} NFTs',
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
    );
  }
}

import 'package:cryptowallet/screens/create_nft.dart';
import 'package:cryptowallet/screens/nftMarketPlace.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';

import 'myNFT.dart';

class NFT extends StatefulWidget {
  @override
  State<NFT> createState() => _NFTState();
}

class _NFTState extends State<NFT> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: 30,
                        )),
                    Text(
                      '${walletName} NFTs',
                      style: TextStyle(fontSize: 18),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // await launch(buyCryptoLink);
                      },
                      child: Text(
                        'BUY',
                        style:
                            TextStyle(fontSize: 18, color: Color(0x00ffffff)),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: double.infinity,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My NFTs',
                            style: TextStyle(fontSize: 17),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (ctx) => MyNFT()));
                    },
                  ),
                ),
                Divider(),
                Container(
                  width: double.infinity,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create NFT',
                            style: TextStyle(fontSize: 17),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (ctx) => createNFT()));
                    },
                  ),
                ),
                Divider(),
                Container(
                  width: double.infinity,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NFT Market Place',
                            style: TextStyle(fontSize: 17),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => NFTMarketPlace()));
                    },
                  ),
                ),
                Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

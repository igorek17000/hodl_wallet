import 'dart:io';
import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cryptowallet/screens/create_nft.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';
import 'package:http_parser/http_parser.dart';
import 'myNFT.dart';

class createNFT extends StatefulWidget {
  @override
  State<createNFT> createState() => _createNFTState();
}

class _createNFTState extends State<createNFT> {
  var nameController = TextEditingController();
  var descriptionController = TextEditingController();
  File image;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading = false;
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
                      'Create ${walletAbbr} NFTs',
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
                GestureDetector(
                  onTap: () {
                    showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                          content: Text("Choose image source"),
                          actions: [
                            FlatButton(
                              child: Text("Camera"),
                              onPressed: () =>
                                  Navigator.pop(context, ImageSource.camera),
                            ),
                            FlatButton(
                              child: Text("Gallery"),
                              onPressed: () =>
                                  Navigator.pop(context, ImageSource.gallery),
                            ),
                          ]),
                    ).then((ImageSource source) async {
                      if (source != null) {
                        image = File((await ImagePicker().pickImage(
                          source: source,
                        ))
                            .path);
                        setState(() {});
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10)),
                    height: 200,
                    child: image != null
                        ? Image.file(image)
                        : Center(
                            child: Text(
                              'Upload Image',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                TextFormField(
                  validator: (value) {
                    if (value?.trim() == "") return 'Required';
                    return null;
                  },
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                TextFormField(
                  validator: (value) {
                    if (value?.trim() == "") return 'Required';
                    return null;
                  },
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  width: double.infinity,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: Colors.blue,
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      print(isLoading);
                      if (nameController.text.trim() == '' ||
                          descriptionController.text.trim() == '' ||
                          image == null) {
                        setState(() {
                          isLoading = false;
                        });
                        return;
                      }

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

                        final mintingPriceFunction =
                            contract.function('mintingPrice');

                        final mintingPrice = double.parse((await client.call(
                                contract: contract,
                                function: mintingPriceFunction,
                                params: []))
                            .first
                            .toString());
                        final createTokenIdFunction =
                            contract.function('createTokenId');

                        final createTokenId = double.parse((await client.call(
                                contract: contract,
                                function: createTokenIdFunction,
                                params: []))
                            .first
                            .toString());

                        final mintingFunction = contract.function('mint');

                        final transactionFee = await getTransactionFee(
                          getBlockChains()[walletNFTContractNetwork]['rpc'],
                          mintingFunction
                              .encodeCall([BigInt.from(createTokenId)]),
                          web3.EthereumAddress.fromHex(
                              response['eth_wallet_address']),
                          web3.EthereumAddress.fromHex(tokenNFTContractAddress),
                        );

                        var totalFee =
                            (transactionFee + mintingPrice) / pow(10, 18);

                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.INFO_REVERSED,
                          buttonsBorderRadius: const BorderRadius.all(
                            Radius.circular(2),
                          ),
                          headerAnimationLoop: false,
                          animType: AnimType.BOTTOMSLIDE,
                          title: 'INFO',
                          desc:
                              'Transaction Fee: ${totalFee} ${getBlockChains()[walletNFTContractNetwork]['symbol']}',
                          showCloseIcon: true,
                          btnCancelOnPress: () {},
                          btnOkOnPress: () async {
                            final credentials =
                                await client.credentialsFromPrivateKey(
                                    response['eth_wallet_privateKey']);
                            await upload(
                                image,
                                NFTImageFieldName,
                                MediaType('image', 'jpeg'),
                                appCreateNFT, {
                              'name': nameController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'tokenId': createTokenId.toString().split('.')[0],
                            });
                            final trans = await client.signTransaction(
                                credentials,
                                Transaction.callContract(
                                  contract: contract,
                                  function: mintingFunction,
                                  parameters: [BigInt.from(createTokenId)],
                                ),
                                chainId:
                                    getBlockChains()[walletNFTContractNetwork]
                                        ['chainId']);

                            var transactionHash =
                                (await client.sendRawTransaction(trans));

                            print(transactionHash);
                            _scaffoldKey.currentState.showSnackBar(
                                SnackBar(content: Text('NFT minted')));
                            setState(() {
                              isLoading = true;
                            });
                          },
                        ).show();
                      } catch (e) {
                        print(e);
                        _scaffoldKey.currentState.showSnackBar(
                            SnackBar(content: Text('Could not create NFT')));
                        setState(() {
                          isLoading = true;
                        });
                      }
                    },
                    child: isLoading
                        ? Padding(
                            padding: EdgeInsets.all(15),
                            child: Container(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              'Create',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
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

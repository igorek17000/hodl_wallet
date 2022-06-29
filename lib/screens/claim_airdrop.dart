import 'dart:math';

import 'package:cryptowallet/screens/dapp.dart';
import 'package:cryptowallet/utils/format_money.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import '../../config/colors.dart';
import '../../config/styles.dart';
import '../utils/slideUpPanel.dart';
import 'package:web3dart/web3dart.dart' as web3;

class claim_airdrop extends StatefulWidget {
  var data;
  claim_airdrop({this.data});

  @override
  _claim_airdropState createState() => _claim_airdropState();
}

class _claim_airdropState extends State<claim_airdrop> {
  bool isLoading = false;
  bool isClaiming = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                ),
                Text(
                  'Claim Airdrop',
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
            StreamBuilder(stream: () async* {
              final client = web3.Web3Client(
                getBlockChains()[walletContractNetwork]['rpc'],
                Client(),
              );
              var seedPhrase =
                  (await SharedPreferences.getInstance()).getString('mmemomic');
              var response = await getCryptoKeys(seedPhrase);
              final credentials = await client
                  .credentialsFromPrivateKey(response['eth_wallet_privateKey']);

              final contract = web3.DeployedContract(
                  web3.ContractAbi.fromJson(erc20Abi, walletName),
                  web3.EthereumAddress.fromHex(tokenContractAddress));

              final viewAirdrop = contract.function(
                'viewAirdrop',
              );
              final viewAirdropTrans = await client
                  .call(contract: contract, function: viewAirdrop, params: []);

              final getAirdrop = contract.function(
                'getAirdrop',
              );
              final gasPrice = await client.getGasPrice();
              double transactionFee =
                  gasPrice.getValueInUnit(web3.EtherUnit.wei) *
                      (await client.estimateGas(
                              sender: EthereumAddress.fromHex(
                                  response['eth_wallet_address']),
                              to: EthereumAddress.fromHex(tokenContractAddress),
                              data: getAirdrop.encodeCall([
                                web3.EthereumAddress.fromHex(
                                    '0x0000000000000000000000000000000000000000'),
                              ])))
                          .toDouble();

              yield {
                'airdropAmount': double.parse(viewAirdropTrans[2].toString()),
                'transactionFee': transactionFee / pow(10, 18)
              };
            }(), builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text('There was an error while checking airdrop amount');
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Text(
                      '${formatMoney((snapshot.data as Map)['airdropAmount'])}',
                      style: h3,
                    ),
                    Text(
                      'transaction Fee: ${formatMoney((snapshot.data as Map)['transactionFee'])} ${getBlockChains()[walletContractNetwork]['symbol']}',
                      style: h5,
                    ),
                  ],
                );
              } else
                return Text('...');
            }),
            SizedBox(
              height: 20,
            ),
            RaisedButton(
              onPressed: () {},
              child: Text(
                walletAbbr,
                style: m_normal,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Please note that this reward can be claimed once only ',
                style: s_agRegular_gray12,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isClaiming = true;
                    });
                    var isClaimed = false;
                    var twitterHandle = widget.data['twitter'];
                    var telegramHandle = widget.data['telegram'];
                    var discordHandle = widget.data['discord'];

                    final client = web3.Web3Client(
                      getBlockChains()[walletContractNetwork]['rpc'],
                      Client(),
                    );
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');
                    var response = await getCryptoKeys(seedPhrase);
                    final credentials = await client.credentialsFromPrivateKey(
                        response['eth_wallet_privateKey']);

                    final contract = web3.DeployedContract(
                        web3.ContractAbi.fromJson(erc20Abi, walletName),
                        web3.EthereumAddress.fromHex(tokenContractAddress));

                    final getAirdrop = contract.function(
                      'getAirdrop',
                    );

                    var transactionHash = '';
                    var blockExplorer = getBlockChains()[walletContractNetwork]
                        ['block explorer'];

                    try {
                      final trans = await client.signTransaction(
                          credentials,
                          Transaction.callContract(
                            contract: contract,
                            function: getAirdrop,
                            parameters: [
                              web3.EthereumAddress.fromHex(
                                  '0x0000000000000000000000000000000000000000'),
                            ],
                          ),
                          chainId: getBlockChains()[walletContractNetwork]
                              ['chainId']);

                      transactionHash =
                          (await client.sendRawTransaction(trans));

                      isClaimed = true;
                    } catch (e) {
                      setState(() {
                        isClaiming = false;
                      });
                    }
                    slideUpPanel(context,
                        StatefulBuilder(builder: (ctx, setState) {
                      var bscAirdropUrl =
                          '${blockExplorer}/tx/${transactionHash}';

                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            isClaimed
                                ? SvgPicture.asset(
                                    'assets/svgs/icon_wrapper.svg')
                                : Image.asset(
                                    'assets/images/failedIcon.png',
                                    scale: 10,
                                  ),
                            Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                isClaimed
                                    ? 'Airdrop Claimed Successfully'
                                    : 'Airdrop Could not be Claimed',
                                style: title1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            !isClaimed
                                ? Container()
                                : Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'Click the link below to view transaction on Bscsacan',
                                      style: s_agRegular_gray12,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                            !isClaimed
                                ? Container()
                                : Padding(
                                    padding: EdgeInsets.all(20),
                                    child: GestureDetector(
                                        child: isLoading
                                            ? CircularProgressIndicator(
                                                color: blue5,
                                              )
                                            : Text(
                                                bscAirdropUrl,
                                                style:
                                                    s_agRegularLinkBlue5Underline,
                                                textAlign: TextAlign.center,
                                              ),
                                        onTap: () async {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          try {
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (ctx) {
                                              return dapp(
                                                data: bscAirdropUrl,
                                              );
                                            }));
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
                      isClaiming = false;
                    });
                  },
                  child: isClaiming
                      ? CircularProgressIndicator(
                          color: primary5,
                        )
                      : Text('Claim', style: l_large_normal_primary5),
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
    ));
  }
}

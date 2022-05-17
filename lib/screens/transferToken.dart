import 'dart:math';
import 'dart:typed_data';
import 'package:cryptowallet/api/notification_api.dart';
import 'package:cryptowallet/screens/token.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/web3dart.dart';

class TransferToken extends StatefulWidget {
  var data;
  TransferToken({this.data});

  @override
  _TransferTokenState createState() => _TransferTokenState();
}

class _TransferTokenState extends State<TransferToken> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  var isSending = false;
  var percentCharge = 3;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: StreamBuilder(stream: () async* {
              while (true) {
                await Future.delayed(Duration(seconds: 2));
                if (widget.data['contractAddress'] != null) {
                  var seedPhrase = (await SharedPreferences.getInstance())
                      .getString('mmemomic');
                  var response = await getCryptoKeys(seedPhrase);
                  final client = web3.Web3Client(
                    widget.data['rpc'],
                    Client(),
                  );

                  final credentials = await client.credentialsFromPrivateKey(
                      response['eth_wallet_privateKey']);

                  final contract = web3.DeployedContract(
                      web3.ContractAbi.fromJson(
                          widget.data['isNFT'] != null ? erc721Abi : erc20Abi,
                          widget.data['name']),
                      web3.EthereumAddress.fromHex(
                          widget.data['contractAddress']));

                  final decimalsFunction = contract.function('decimals');

                  final decimals = (await client.call(
                          contract: contract,
                          function: decimalsFunction,
                          params: []))
                      .first;

                  ContractFunction transfer = widget.data['isNFT'] != null
                      ? contract
                          .findFunctionsByName('safeTransferFrom')
                          .toList()[0]
                      : contract.function('transfer');

                  Uint8List contractData = widget.data['isNFT'] != null
                      ? transfer.encodeCall([
                          web3.EthereumAddress.fromHex(
                              response['eth_wallet_address']),
                          web3.EthereumAddress.fromHex(
                              widget.data['recipient']),
                          BigInt.from(widget.data['tokenId'])
                        ])
                      : transfer.encodeCall([
                          web3.EthereumAddress.fromHex(
                              widget.data['recipient']),
                          BigInt.from(double.parse(widget.data['amount']) *
                              pow(10, double.parse(decimals.toString())))
                        ]);

                  final transactionFee = await getTransactionFee(
                    widget.data['rpc'],
                    contractData,
                    web3.EthereumAddress.fromHex(
                        response['eth_wallet_address']),
                    web3.EthereumAddress.fromHex(
                        widget.data['contractAddress']),
                  );
                  var userBalance = (await client.getBalance(
                              EthereumAddress.fromHex(
                                  response['eth_wallet_address'])))
                          .getInWei
                          .toDouble() /
                      pow(10, 18);

                  var blockChainCost = transactionFee / pow(10, 18);
                  var ourCharge = (blockChainCost * percentCharge / 100);
                  var totalCost = blockChainCost + ourCharge;

                  yield {
                    'transactionFee': totalCost,
                    'userBalance': userBalance,
                    'ourCharge': ourCharge
                  };
                  return;
                } else if (widget.data['default'] != null) {
                  if (widget.data['default'] == 'BTC') {
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');

                    var getBitCoinDetails =
                        await getBitCoinFromMemnomic(seedPhrase);
                    var bitCoinBalance = (await getBitcoinAddressDetails(
                        getBitCoinDetails['address']))['final_balance'];

                    var fee = jsonDecode(await getBitCoinTransactionFee(
                        getBitCoinDetails['address'],
                        getBitCoinDetails['private_key'],
                        double.parse(widget.data['amount'])));
                    var feeInBitcoin;
                    if (fee['fee'] != null) {
                      feeInBitcoin = fee['fee'] / pow(10, 8);
                    } else {
                      feeInBitcoin = 0;
                    }
                    yield {
                      'transactionFee': feeInBitcoin,
                      'userBalance': bitCoinBalance,
                      'ourCharge': feeInBitcoin
                    };
                    return;
                  }
                  if (widget.data['default'] == 'BTCTEST') {
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');

                    var getBitCoinDetails = await getBitCoinFromMemnomic(
                        seedPhrase,
                        istestnet: true);
                    var bitCoinBalance = (await getBitcoinAddressDetails(
                        getBitCoinDetails['address'],
                        istestnet: true))['final_balance'];

                    var fee = jsonDecode(await getBitCoinTransactionFee(
                        getBitCoinDetails['address'],
                        getBitCoinDetails['private_key'],
                        double.parse(widget.data['amount']),
                        istestnet: true));

                    var feeInBitcoin;
                    if (fee['fee'] != null) {
                      feeInBitcoin = fee['fee'] / pow(10, 8);
                    } else {
                      feeInBitcoin = 0;
                    }
                    yield {
                      'transactionFee': feeInBitcoin,
                      'userBalance': bitCoinBalance,
                      'ourCharge': feeInBitcoin
                    };
                    return;
                  } else if (widget.data['default'] == 'LTC') {
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');

                    var getLitecoinDetails =
                        await getLiteCoinFromMemnomic(seedPhrase);
                    var litecoinBalance = (await getLitecoinAddressDetails(
                        getLitecoinDetails['address']))['final_balance'];

                    var fee = jsonDecode(await getLitecoinTransactionFee(
                        getLitecoinDetails['address'],
                        getLitecoinDetails['private_key'],
                        double.parse(widget.data['amount'])));

                    var feeInLitecoin;
                    if (fee['fee'] != null) {
                      feeInLitecoin = fee['fee'] / pow(10, 8);
                    } else {
                      feeInLitecoin = 0;
                    }
                    yield {
                      'transactionFee': feeInLitecoin,
                      'userBalance': litecoinBalance,
                      'ourCharge': 0
                    };
                    return;
                  } else if (widget.data['default'] == 'DOGE') {
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');

                    var getDogecoinDetails =
                        await getDogeCoinFromMemnomic(seedPhrase);
                    var DogecoinBalance = (await getDogecoinAddressDetails(
                        getDogecoinDetails['address']))['final_balance'];

                    var fee = jsonDecode(await getDogecoinTransactionFee(
                        getDogecoinDetails['address'],
                        getDogecoinDetails['private_key'],
                        double.parse(widget.data['amount'])));

                    var feeInDogecoin;
                    if (fee['fee'] != null) {
                      feeInDogecoin = fee['fee'] / pow(10, 8);
                    } else {
                      feeInDogecoin = 0;
                    }
                    yield {
                      'transactionFee': feeInDogecoin,
                      'userBalance': DogecoinBalance,
                      'ourCharge': 0
                    };
                    return;
                  } else {
                    var seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');
                    var response = await getCryptoKeys(seedPhrase);
                    final client = web3.Web3Client(
                      widget.data['rpc'],
                      Client(),
                    );
                    final credentials = await client.credentialsFromPrivateKey(
                        response['eth_wallet_privateKey']);

                    final gasPrice = await client.getGasPrice();
                    final gasUnit = await client.estimateGas(
                        gasPrice: gasPrice,
                        sender: web3.EthereumAddress.fromHex(
                            response['eth_wallet_address']),
                        to: web3.EthereumAddress.fromHex(
                            widget.data['recipient']),
                        value: web3.EtherAmount.inWei(
                            BigInt.from(double.parse(widget.data['amount']))));

                    final transactionFee =
                        gasPrice.getValueInUnit(web3.EtherUnit.wei) *
                            gasUnit.toDouble();

                    var userBalance = (await client.getBalance(
                                EthereumAddress.fromHex(
                                    response['eth_wallet_address'])))
                            .getInWei
                            .toDouble() /
                        pow(10, 18);

                    var blockChainCost = transactionFee / pow(10, 18);
                    var ourCharge = (blockChainCost * percentCharge / 100);
                    var totalCost =
                        blockChainCost + ourCharge; // 5 percent gain for us

                    yield {
                      'transactionFee': totalCost,
                      'userBalance': userBalance,
                      'ourCharge': ourCharge
                    };
                    return;
                  }
                }
                yield {'transactionFee': 0, 'userBalance': 0};
              }
            }(), builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(snapshot.error);
              }
              return Column(
                children: [
                  Row(
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
                        'Transfer',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(
                        width: 10,
                      )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    '${widget.data['isNFT'] != null ? '' : '-'}${widget.data['isNFT'] != null ? '' : widget.data['amount']} ${widget.data['symbol']}',
                    style: TextStyle(fontSize: 25),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asset',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${widget.data['name']} (${widget.data['symbol']})',
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'From',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      StreamBuilder(stream: () async* {
                        while (true) {
                          var seedPhrase =
                              (await SharedPreferences.getInstance())
                                  .getString('mmemomic');
                          if (widget.data['default'] == 'BTC') {
                            var getBitCoinDetails =
                                await getBitCoinFromMemnomic(seedPhrase);
                            yield {'address': getBitCoinDetails['address']};
                            await Future.delayed(Duration(minutes: 1));
                            return;
                          }
                          if (widget.data['default'] == 'BTCTEST') {
                            var getBitCoinDetails =
                                await getBitCoinFromMemnomic(seedPhrase,
                                    istestnet: true);
                            yield {'address': getBitCoinDetails['address']};
                            await Future.delayed(Duration(minutes: 1));
                            return;
                          }
                          if (widget.data['default'] == 'LTC') {
                            var getLitecoinDetails =
                                await getLiteCoinFromMemnomic(seedPhrase);
                            yield {'address': getLitecoinDetails['address']};
                            await Future.delayed(Duration(minutes: 1));
                            return;
                          }
                          if (widget.data['default'] == 'DOGE') {
                            var getDogecoinDetails =
                                await getDogeCoinFromMemnomic(seedPhrase);
                            yield {'address': getDogecoinDetails['address']};
                            await Future.delayed(Duration(minutes: 1));
                            return;
                          }
                          yield {
                            'address': (await getCryptoKeys(
                                seedPhrase))['eth_wallet_address']
                          };
                          await Future.delayed(Duration(minutes: 1));
                        }
                      }(), builder: (context, snapshot) {
                        return Flexible(
                          child: Text(
                            snapshot.hasData
                                ? (snapshot.data as Map)['address']
                                : '0x...',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      })
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'To',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${widget.data['recipient']}',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Network Fee',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      widget.data['default'] != null
                          ? Flexible(
                              child: Text(
                                '${snapshot.hasData ? (snapshot.data as Map)['transactionFee'] : '0'}  ${widget.data['default']}',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : Container(),
                      widget.data['network'] != null
                          ? Flexible(
                              child: Text(
                                '${snapshot.hasData ? (snapshot.data as Map)['transactionFee'] : '0'}  ${getBlockChains()[widget.data['network']]['symbol']}',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : Container()
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: double.infinity,
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      color: Colors.blue,
                      onPressed: !snapshot.hasData ||
                              (snapshot.data as Map)['userBalance'] == null ||
                              (snapshot.data as Map)['userBalance'] <= 0
                          ? null
                          : () async {
                              var pinEntered = await prompt(
                                context,
                                title: const Text('Your pin is required'),
                                isSelectedInitialValue: false,
                                textOK: const Text('Ok'),
                                textCancel: const Text('Cancel'),
                                hintText: 'Please enter your pin',
                                validator: (String value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your pin';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                autoFocus: true,
                                obscureText: true,
                                obscuringCharacter: '*',
                                showPasswordIcon: true,
                                barrierDismissible: true,
                                textCapitalization: TextCapitalization.words,
                                textAlign: TextAlign.center,
                              );

                              var localAuth = LocalAuthentication();
                              bool didAuthenticate = false;
                              bool userEnteredPinCorrectly = false;
                              var pref = await SharedPreferences.getInstance();
                              if (await authenticateIsAvailable()) {
                                didAuthenticate = await localAuth.authenticate(
                                    localizedReason:
                                        'Please authenticate to transfer token');
                              } else {
                                userEnteredPinCorrectly =
                                    pref.getString(userUnlockPasscodeKey) ==
                                        pinEntered.trim();
                              }

                              if (didAuthenticate || userEnteredPinCorrectly) {
                                if (isSending) return;
                                setState(() {
                                  isSending = true;
                                });
                                try {
                                  print(widget.data);
                                  if (widget.data['contractAddress'] != null) {
                                    var pref =
                                        (await SharedPreferences.getInstance());
                                    final client = web3.Web3Client(
                                      widget.data['rpc'],
                                      Client(),
                                    );

                                    var seedPhrase = pref.getString('mmemomic');
                                    var response =
                                        await getCryptoKeys(seedPhrase);
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

                                    final decimalsFunction =
                                        contract.function('decimals');

                                    final decimals = (await client.call(
                                            contract: contract,
                                            function: decimalsFunction,
                                            params: []))
                                        .first;
                                    ContractFunction transfer =
                                        widget.data['isNFT'] != null
                                            ? contract
                                                .findFunctionsByName(
                                                    'safeTransferFrom')
                                                .toList()[0]
                                            : contract.function('transfer');

                                    List _parameters = widget.data['isNFT'] !=
                                            null
                                        ? [
                                            web3.EthereumAddress.fromHex(
                                                response['eth_wallet_address']),
                                            web3.EthereumAddress.fromHex(
                                                widget.data['recipient']),
                                            BigInt.from(widget.data['tokenId'])
                                          ]
                                        : [
                                            web3.EthereumAddress.fromHex(
                                                widget.data['recipient']),
                                            BigInt.from(double.parse(
                                                widget.data['amount']))
                                          ];

                                    final gasPrice = await client.getGasPrice();
                                    final nonce =
                                        await client.getTransactionCount(
                                            web3.EthereumAddress.fromHex(
                                                response[
                                                    'eth_wallet_address']));

                                    final ourTrans =
                                        await client.signTransaction(
                                            credentials,
                                            web3.Transaction(
                                              nonce: nonce,
                                              from: web3.EthereumAddress
                                                  .fromHex(response[
                                                      'eth_wallet_address']),
                                              to: web3.EthereumAddress.fromHex(
                                                  admin),
                                              value: web3.EtherAmount.inWei(
                                                  BigInt.from((snapshot.data
                                                          as Map)['ourCharge'] *
                                                      pow(10, 18))),
                                              gasPrice: gasPrice,
                                            ),
                                            chainId: widget.data['chainId']);
                                    final trans = await client.signTransaction(
                                        credentials,
                                        Transaction.callContract(
                                          nonce: nonce + 1,
                                          contract: contract,
                                          function: transfer,
                                          parameters: _parameters,
                                        ),
                                        chainId: widget.data['chainId']);

                                    (await client.sendRawTransaction(ourTrans));

                                    var transactionHash = (await client
                                        .sendRawTransaction(trans));
                                    _scaffoldKey.currentState.showSnackBar(
                                        SnackBar(content: Text('Token Sent')));

                                    NotificationApi.showNotification(
                                        title: '${widget.data['symbol']} Sent',
                                        body:
                                            '${widget.data['isNFT'] != null ? widget.data['tokenId'] : widget.data['amount']} ${widget.data['symbol']} sent to ${web3.EthereumAddress.fromHex(widget.data['recipient']).toString()}',
                                        id: nonce);

                                    if (widget.data['isNFT'] == null) {
                                      var transactionDetails =
                                          await client.getTransactionByHash(
                                              transactionHash);
                                      String formattedDate =
                                          DateFormat("yyyy-MM-dd HH:mm:ss")
                                              .format(DateTime.now());
                                      var mapData = {
                                        'time': formattedDate,
                                        'from':
                                            transactionDetails.from.toString(),
                                        'to': web3.EthereumAddress.fromHex(
                                                widget.data['recipient'])
                                            .toString(),
                                        'value':
                                            double.parse(widget.data['amount']),
                                        'decimal':
                                            double.parse(decimals.toString()),
                                        'transactionHash':
                                            transactionDetails.hash
                                      };

                                      if (pref.getString(
                                              '${widget.data['contractAddress']} Details') ==
                                          null) {
                                        pref.setString(
                                            '${widget.data['contractAddress']} Details',
                                            jsonEncode([mapData]));
                                      } else {
                                        List jsonData = jsonDecode(pref.getString(
                                            '${widget.data['contractAddress']} Details'));
                                        jsonData.add(mapData);

                                        pref.setString(
                                            '${widget.data['contractAddress']} Details',
                                            jsonEncode(jsonData));
                                      }
                                    }

                                    await client.dispose();
                                  } else if (widget.data['default'] != null) {
                                    if (widget.data['default'] == 'BTC') {
                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');
                                      var getBitCoinDetails =
                                          await getBitCoinFromMemnomic(
                                              seedPhrase);

                                      var transaction = jsonDecode(
                                          await sendBitCoin(
                                              getBitCoinDetails['address'],
                                              widget.data['recipient'],
                                              getBitCoinDetails['private_key'],
                                              double.parse(
                                                  widget.data['amount'])));
                                      if (transaction['txid'] != null) {
                                        _scaffoldKey.currentState.showSnackBar(
                                            SnackBar(
                                                content: Text('Token Sent')));

                                        var getBitcoinDetails =
                                            await getBitCoinFromMemnomic(
                                                seedPhrase);

                                        String formattedDate =
                                            DateFormat("yyyy-MM-dd HH:mm:ss")
                                                .format(DateTime.now());

                                        var mapData = {
                                          'time': formattedDate,
                                          'from': getBitcoinDetails['address'],
                                          'to': widget.data['recipient'],
                                          'value': double.parse(
                                                  widget.data['amount']) *
                                              pow(10, 8),
                                          'decimal': 8,
                                          'transactionHash': transaction['txid']
                                        };

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '${widget.data['amount']} ${widget.data['symbol']} sent to ${mapData['to']}',
                                        );
                                        var pref = await SharedPreferences
                                            .getInstance();
                                        if (pref.getString(
                                                '${widget.data['default']} Details') ==
                                            null) {
                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode([mapData]));
                                        } else {
                                          List jsonData = jsonDecode(pref.getString(
                                              '${widget.data['default']} Details'));
                                          jsonData.add(mapData);

                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode(jsonData));
                                        }
                                      } else {
                                        throw Exception('Sending Failed');
                                      }
                                    } else if (widget.data['default'] ==
                                        'BTCTEST') {
                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');
                                      var getBitCoinDetails =
                                          await getBitCoinFromMemnomic(
                                              seedPhrase,
                                              istestnet: true);

                                      var transaction = jsonDecode(
                                          await sendBitCoin(
                                              getBitCoinDetails['address'],
                                              widget.data['recipient'],
                                              getBitCoinDetails['private_key'],
                                              double.parse(
                                                  widget.data['amount']),
                                              istestnet: true));

                                      if (transaction['txid'] != null) {
                                        _scaffoldKey.currentState.showSnackBar(
                                            SnackBar(
                                                content: Text('Token Sent')));

                                        var getBitcoinDetails =
                                            await getBitCoinFromMemnomic(
                                                seedPhrase,
                                                istestnet: true);

                                        String formattedDate =
                                            DateFormat("yyyy-MM-dd HH:mm:ss")
                                                .format(DateTime.now());

                                        var mapData = {
                                          'time': formattedDate,
                                          'from': getBitcoinDetails['address'],
                                          'to': widget.data['recipient'],
                                          'value': double.parse(
                                                  widget.data['amount']) *
                                              pow(10, 8),
                                          'decimal': 8,
                                          'transactionHash': transaction['txid']
                                        };

                                        print(mapData);

                                        await NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '${widget.data['amount']} ${widget.data['symbol']} sent to ${mapData['to']}',
                                        );
                                        var pref = await SharedPreferences
                                            .getInstance();
                                        if (pref.getString(
                                                '${widget.data['default']} Details') ==
                                            null) {
                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode([mapData]));
                                        } else {
                                          List jsonData = jsonDecode(pref.getString(
                                              '${widget.data['default']} Details'));
                                          jsonData.add(mapData);

                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode(jsonData));
                                        }
                                      } else {
                                        throw Exception('Sending Failed');
                                      }
                                    } else if (widget.data['default'] ==
                                        'LTC') {
                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');
                                      var getLitecoinDetails =
                                          await getLiteCoinFromMemnomic(
                                              seedPhrase);

                                      var transaction = jsonDecode(
                                          await sendLiteCoin(
                                              getLitecoinDetails['address'],
                                              widget.data['recipient'],
                                              getLitecoinDetails['private_key'],
                                              double.parse(
                                                  widget.data['amount'])));
                                      if (transaction['txid'] != null) {
                                        _scaffoldKey.currentState.showSnackBar(
                                            SnackBar(
                                                content: Text('Token Sent')));

                                        var getLitecoinDetails =
                                            await getLiteCoinFromMemnomic(
                                                seedPhrase);

                                        String formattedDate =
                                            DateFormat("yyyy-MM-dd HH:mm:ss")
                                                .format(DateTime.now());

                                        var mapData = {
                                          'time': formattedDate,
                                          'from': getLitecoinDetails['address'],
                                          'to': widget.data['recipient'],
                                          'decimal': 8,
                                          'value': double.parse(
                                                  widget.data['amount']) *
                                              pow(10, 8),
                                          'transactionHash': transaction['txid']
                                        };

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '${widget.data['amount']} ${widget.data['symbol']} sent to ${mapData['to']}',
                                        );
                                        var pref = await SharedPreferences
                                            .getInstance();
                                        if (pref.getString(
                                                '${widget.data['default']} Details') ==
                                            null) {
                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode([mapData]));
                                        } else {
                                          List jsonData = jsonDecode(pref.getString(
                                              '${widget.data['default']} Details'));
                                          jsonData.add(mapData);

                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode(jsonData));
                                        }
                                      } else {
                                        throw Exception('Sending Failed');
                                      }
                                    } else if (widget.data['default'] ==
                                        'DOGE') {
                                      var seedPhrase = (await SharedPreferences
                                              .getInstance())
                                          .getString('mmemomic');
                                      var getDogecoinDetails =
                                          await getDogeCoinFromMemnomic(
                                              seedPhrase);

                                      var transaction = jsonDecode(
                                          await sendDogeCoin(
                                              getDogecoinDetails['address'],
                                              widget.data['recipient'],
                                              getDogecoinDetails['private_key'],
                                              double.parse(
                                                  widget.data['amount'])));
                                      if (transaction['txid'] != null) {
                                        _scaffoldKey.currentState.showSnackBar(
                                            SnackBar(
                                                content: Text('Token Sent')));

                                        var getDogecoinDetails =
                                            await getDogeCoinFromMemnomic(
                                                seedPhrase);

                                        String formattedDate =
                                            DateFormat("yyyy-MM-dd HH:mm:ss")
                                                .format(DateTime.now());

                                        var mapData = {
                                          'time': formattedDate,
                                          'from': getDogecoinDetails['address'],
                                          'to': widget.data['recipient'],
                                          'value': double.parse(
                                                  widget.data['amount']) *
                                              pow(10, 8),
                                          'decimal': 8,
                                          'transactionHash': transaction['txid']
                                        };

                                        NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '${widget.data['amount']} ${widget.data['symbol']} sent to ${mapData['to']}',
                                        );
                                        var pref = await SharedPreferences
                                            .getInstance();
                                        if (pref.getString(
                                                '${widget.data['default']} Details') ==
                                            null) {
                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode([mapData]));
                                        } else {
                                          List jsonData = jsonDecode(pref.getString(
                                              '${widget.data['default']} Details'));
                                          jsonData.add(mapData);

                                          pref.setString(
                                              '${widget.data['default']} Details',
                                              jsonEncode(jsonData));
                                        }
                                      } else {
                                        throw Exception('Sending Failed');
                                      }
                                    } else {
                                      final client = web3.Web3Client(
                                        widget.data['rpc'],
                                        Client(),
                                      );

                                      var pref =
                                          await SharedPreferences.getInstance();
                                      var seedPhrase =
                                          pref.getString('mmemomic');
                                      var response =
                                          await getCryptoKeys(seedPhrase);

                                      final credentials = await client
                                          .credentialsFromPrivateKey(response[
                                              'eth_wallet_privateKey']);
                                      final gasPrice =
                                          await client.getGasPrice();

                                      final nonce =
                                          await client.getTransactionCount(
                                              web3.EthereumAddress.fromHex(
                                                  response[
                                                      'eth_wallet_address']));
                                      final ourTrans =
                                          await client.signTransaction(
                                              credentials,
                                              web3.Transaction(
                                                nonce: nonce,
                                                from: web3.EthereumAddress
                                                    .fromHex(response[
                                                        'eth_wallet_address']),
                                                to: web3.EthereumAddress
                                                    .fromHex(admin),
                                                value: web3.EtherAmount.inWei(
                                                    BigInt.from(
                                                        (snapshot.data as Map)[
                                                                'ourCharge'] *
                                                            pow(10, 18))),
                                                gasPrice: gasPrice,
                                              ),
                                              chainId: widget.data['chainId']);

                                      final trans =
                                          await client.signTransaction(
                                              credentials,
                                              web3.Transaction(
                                                nonce: nonce + 1,
                                                from: web3.EthereumAddress
                                                    .fromHex(response[
                                                        'eth_wallet_address']),
                                                to: web3.EthereumAddress
                                                    .fromHex(widget
                                                        .data['recipient']),
                                                value: web3.EtherAmount.inWei(
                                                    BigInt.from(double.parse(
                                                            widget.data[
                                                                'amount']) *
                                                        pow(10, 18))),
                                                gasPrice: gasPrice,
                                              ),
                                              chainId: widget.data['chainId']);

                                      var ourTransHash = (await client
                                          .sendRawTransaction(ourTrans));
                                      var transactionHash = (await client
                                          .sendRawTransaction(trans));
                                      _scaffoldKey.currentState.showSnackBar(
                                          SnackBar(
                                              content: Text('Token Sent')));
                                      var transactionDetails =
                                          await client.getTransactionByHash(
                                              transactionHash);
                                      String formattedDate =
                                          DateFormat("yyyy-MM-dd HH:mm:ss")
                                              .format(DateTime.now());

                                      var mapData = {
                                        'time': formattedDate,
                                        'from':
                                            transactionDetails.from.toString(),
                                        'to': transactionDetails.to.toString(),
                                        'value': transactionDetails
                                            .value.getInWei
                                            .toDouble(),
                                        'decimal': 18,
                                        'transactionHash':
                                            transactionDetails.hash
                                      };

                                      var amountInEther = double.parse(
                                              mapData['value'].toString()) /
                                          pow(10, 18);

                                      NotificationApi.showNotification(
                                          title:
                                              '${widget.data['symbol']} Sent',
                                          body:
                                              '${amountInEther} ${widget.data['symbol']} sent to ${mapData['to']}',
                                          id: nonce);

                                      if (pref.getString(
                                              '${widget.data['default']} Details') ==
                                          null) {
                                        pref.setString(
                                            '${widget.data['default']} Details',
                                            jsonEncode([mapData]));
                                      } else {
                                        List jsonData = jsonDecode(pref.getString(
                                            '${widget.data['default']} Details'));
                                        jsonData.add(mapData);

                                        pref.setString(
                                            '${widget.data['default']} Details',
                                            jsonEncode(jsonData));
                                      }
                                      await client.dispose();
                                    }
                                  }
                                  setState(() {
                                    isSending = false;
                                  });
                                } catch (e) {
                                  print(e);
                                  setState(() {
                                    isSending = false;
                                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                                        content: Text(
                                            'Could not send Token, Check your available balance')));
                                  });
                                }
                              } else {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                    content: Text('Authentication failed')));
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: isSending
                            ? Container(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                snapshot.hasError
                                    ? 'Error, try again later'
                                    : 'Send',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

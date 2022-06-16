import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptowallet/components/AppLogOut.dart';
import 'package:cryptowallet/screens/createPin.dart';
import 'package:cryptowallet/screens/main_screen.dart';
import 'package:cryptowallet/screens/recovery_pharse.dart';
import 'package:cryptowallet/screens/setCurrency.dart';
import 'package:cryptowallet/screens/showDappBookmarks.dart';
import 'package:cryptowallet/screens/view_seedPhrases.dart';
import 'package:cryptowallet/screens/wallet_connect.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';

import '../main.dart';

class Settings extends StatefulWidget {
  final isDarkMode;
  Settings({this.isDarkMode, Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () async {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (ctx) => setCurrency()));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.money),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Currency',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  var localAuth = LocalAuthentication();
                  var pref = await SharedPreferences.getInstance();
                  if (await authenticateIsAvailable()) {
                    bool didAuthenticate = await localAuth.authenticate(
                        localizedReason:
                            'Please authenticate to show saved bookmark');

                    print(didAuthenticate);
                    if (didAuthenticate) {
                      if (pref.getString('bookMarks') != null) {
                        var bookMarkJson =
                            jsonDecode(pref.getString('bookMarks')) as Map;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) =>
                                    showDappBookmarks(data: bookMarkJson)));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => showDappBookmarks(data: {})));
                      }
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => enterPin(
                                  isEnterPin: true,
                                  route: 'bookmark',
                                )));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.bookmark),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'BookMarks',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  var localAuth = LocalAuthentication();

                  bool didAuthenticate = false;

                  if (await authenticateIsAvailable()) {
                    didAuthenticate = await localAuth.authenticate(
                        localizedReason:
                            'Please authenticate to show seed phrase');
                    String seedPhrase = (await SharedPreferences.getInstance())
                        .getString('mmemomic');
                    if (didAuthenticate) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => RecoveryPhrase(
                                  data: seedPhrase, verify: false)));
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => enterPin(
                                  isEnterPin: true,
                                  route: 'showSeedPhrase',
                                ))));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.vpn_key),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Show Seed Phrase',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  var localAuth = LocalAuthentication();
                  var seedPhrases = (await SharedPreferences.getInstance())
                      .getString('seedPhrases');
                  if (await authenticateIsAvailable()) {
                    bool didAuthenticate = await localAuth.authenticate(
                        localizedReason: 'Please authenticate to show wallet');

                    if (didAuthenticate) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => ViewSeedPhrase(
                                  data: (jsonDecode(seedPhrases) as List))));
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => enterPin(
                                  isEnterPin: true,
                                  route: 'viewWallet',
                                )));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.remove_red_eye),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'View Wallets',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => MainScreen(
                        add: true,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.add),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Import Wallet',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  var localAuth = LocalAuthentication();
                  var seedPhrases = (await SharedPreferences.getInstance())
                      .getString('seedPhrases');
                  if (await authenticateIsAvailable()) {
                    bool didAuthenticate = await localAuth.authenticate(
                        localizedReason: 'Please authenticate to change pin');

                    if (didAuthenticate) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => enterPin(
                                    isEnterPin: true,
                                    route: 'changePin',
                                  )));
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => enterPin(
                                  isEnterPin: true,
                                  route: 'changePin',
                                )));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.pin),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Change pin',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              InkWell(
                onTap: () async {
                  var localAuth = LocalAuthentication();
                  if (await authenticateIsAvailable()) {
                    bool didAuthenticate = await localAuth.authenticate(
                        localizedReason: 'Please authenticate to show wallet');

                    if (didAuthenticate) {
                      ByteData bytes = await rootBundle.load('assets/logo.png');
                      var buffer = bytes.buffer;
                      var logoImageBase64 =
                          base64.encode(Uint8List.view(buffer));
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                        return WalletConnect(
                            title: "Wallet Connect",
                            logoImageBase64: logoImageBase64);
                      }));
                    }
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => enterPin(
                                  isEnterPin: true,
                                  route: 'useWalletConnect',
                                )));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/walletconnect-logo.png', width: 30),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Wallet Connect',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

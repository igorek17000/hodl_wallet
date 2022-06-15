import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptowallet/screens/main_screen.dart';
import 'package:cryptowallet/screens/recovery_pharse.dart';
import 'package:cryptowallet/screens/showDappBookmarks.dart';
import 'package:cryptowallet/screens/view_seedPhrases.dart';
import 'package:cryptowallet/screens/wallet_connect.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class enterPin extends StatefulWidget {
  bool isEnterPin;
  String route;
  enterPin({this.isEnterPin, this.route});

  @override
  State<enterPin> createState() => _enterPinState();
}

class _enterPinState extends State<enterPin> {
  var pinController = TextEditingController();
  var pinController2 = TextEditingController();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  var enterPinController = TextEditingController();
  bool isConfirming = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          child: Padding(
            child: Container(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  widget.isEnterPin != null
                      ? Text(
                          'Enter your passcode',
                          style: TextStyle(fontSize: 22),
                        )
                      : Text(
                          isConfirming
                              ? 'Verify passcode'
                              : 'Enter a new passcode',
                          style: TextStyle(fontSize: 22),
                        ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    autofocus: true,
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value?.trim() == '')
                        return 'Pin is required';
                      else
                        return null;
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                    obscureText: true,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    controller: isConfirming ? pinController2 : pinController,
                    maxLength: 4,
                    style: TextStyle(
                      fontSize: 25,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintStyle: const TextStyle(fontSize: 25),
                      hintText: '* * * *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                    ),
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
                        onPressed: (isConfirming &&
                                    pinController2.text.trim().length == 4) ||
                                (!isConfirming &&
                                    pinController.text.trim().length == 4)
                            ? () async {
                                var pref =
                                    await SharedPreferences.getInstance();
                                if (widget.isEnterPin != null &&
                                    widget.route != null) {
                                  if (pref.getString(userUnlockPasscodeKey) ==
                                      pinController.text.trim()) {
                                    switch (widget.route) {
                                      case 'changePin':
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (ctx) => enterPin()));
                                        break;
                                      case 'bookmark':
                                        if (pref.getString('bookMarks') !=
                                            null) {
                                          var bookMarkJson = jsonDecode(
                                                  pref.getString('bookMarks'))
                                              as Map;
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (ctx) =>
                                                      showDappBookmarks(
                                                          data: bookMarkJson)));
                                        } else {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (ctx) =>
                                                      showDappBookmarks(
                                                          data: {})));
                                        }
                                        break;
                                      case 'showSeedPhrase':
                                        String seedPhrase =
                                            (await SharedPreferences
                                                    .getInstance())
                                                .getString('mmemomic');
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (ctx) =>
                                                    RecoveryPhrase(
                                                        data: seedPhrase,
                                                        verify: false)));
                                        break;
                                      case 'viewWallet':
                                        var seedPhrases =
                                            (await SharedPreferences
                                                    .getInstance())
                                                .getString('seedPhrases');
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (ctx) =>
                                                    ViewSeedPhrase(
                                                        data: (jsonDecode(
                                                                seedPhrases)
                                                            as List))));
                                        break;
                                      case 'useWalletConnect':
                                        ByteData bytes = await rootBundle
                                            .load('assets/logo.png');
                                        var buffer = bytes.buffer;
                                        var logoImageBase64 = base64
                                            .encode(Uint8List.view(buffer));
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (ctx) {
                                          return WalletConnect(
                                              title: "Wallet Connect",
                                              logoImageBase64: logoImageBase64);
                                        }));
                                        break;
                                    }
                                  } else {
                                    _scaffoldKey.currentState.showSnackBar(
                                        SnackBar(
                                            content: Text('invalid passcode')));
                                  }
                                  return;
                                }
                                if (isConfirming) {
                                  if (pinController.text.trim() ==
                                      pinController2.text.trim()) {
                                    await pref.setString(userUnlockPasscodeKey,
                                        pinController2.text.trim());
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (ctx) => MainScreen()),
                                        (route) => false);
                                  } else {
                                    _scaffoldKey.currentState.showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Passcode do not match')));
                                    pinController.clear();
                                    pinController2.clear();
                                    setState(() {
                                      isConfirming = false;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    isConfirming = true;
                                  });
                                }
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: isConfirming
                              ? Text(
                                  'Save',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                )
                              : Text(
                                  'Confirm',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                        ),
                      ))
                ],
              ),
            ),
            padding: EdgeInsets.all(25),
          ),
        ),
      ),
    );
  }
}

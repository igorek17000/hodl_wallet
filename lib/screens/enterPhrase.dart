import 'dart:convert';

import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnterPhrase extends StatefulWidget {
  var add;
  EnterPhrase({this.add});
  @override
  State<EnterPhrase> createState() => _EnterPhraseState();
}

class _EnterPhraseState extends State<EnterPhrase> {
  var seedPhraseController = TextEditingController();
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  maxLines: 5,
                  controller: seedPhraseController,
                  decoration: InputDecoration(
                    hintText: 'Enter Seed Phrase',
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
                    onPressed: () async {
                      try {
                        const defaultSeedPhraseLength = 12;
                        if (seedPhraseController.text.trim() == '') return;
                        if (seedPhraseController.text
                                .trim()
                                .split(' ')
                                .length !=
                            defaultSeedPhraseLength) {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content:
                                  Text('seed phrase can only be 12 words')));
                          return;
                        }
                        var seedPhrases =
                            (await SharedPreferences.getInstance())
                                .getString('seedPhrases');

                        if (seedPhrases != null &&
                            (jsonDecode(seedPhrases) as List)
                                .contains(seedPhraseController.text.trim())) {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text('seed phrase already imported')));
                          return;
                        }

                        if (seedPhrases == null) {
                          (await SharedPreferences.getInstance()).setString(
                              'seedPhrases',
                              jsonEncode([seedPhraseController.text.trim()]));
                        } else {
                          var decodedSeedPhrase =
                              jsonDecode(seedPhrases) as List;

                          (await SharedPreferences.getInstance()).setString(
                              'seedPhrases',
                              jsonEncode(decodedSeedPhrase
                                ..add(seedPhraseController.text.trim())));
                        }
                        (await SharedPreferences.getInstance()).setString(
                            'mmemomic', seedPhraseController.text.trim());

                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (ctx) => Wallet()),
                            (r) => false);
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        'SAVE',
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

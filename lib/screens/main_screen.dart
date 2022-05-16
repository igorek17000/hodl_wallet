import 'package:cryptowallet/screens/enterPhrase.dart';
import 'package:cryptowallet/screens/recovery_pharse.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  var add;
  MainScreen({this.add});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: StreamBuilder(stream: () async* {
        if (widget.add != null) {
          yield false;
          return;
        }
        yield (await SharedPreferences.getInstance()).get('mmemomic') != null;
      }(), builder: (context, snapshot) {
        return snapshot.data == true
            ? Wallet()
            : Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 100,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: double.infinity,
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        color: Colors.blue,
                        onPressed: () {
                          String mmemnomic = bip39.generateMnemonic();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => RecoveryPhrase(
                                      data: mmemnomic, add: true)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            'CREATE A WALLET',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => EnterPhrase(add: true)));
                      },
                      child: Container(
                        width: double.infinity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              'IMPORT SEED PHRASE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
      })),
    );
  }
}

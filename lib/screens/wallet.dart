import 'package:cryptowallet/screens/settings.dart';
import 'package:cryptowallet/screens/swap.dart';
import 'package:cryptowallet/screens/wallet_main_body.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import './private_sale.dart';
import 'package:flutter/material.dart';

class Wallet extends StatefulWidget {
  @override
  _WalletState createState() => _WalletState();
}

bool isDarkMode = true;

class _WalletState extends State<Wallet> {
  var currentIndex_ = 0;
  @override
  void initState() {
    super.initState();
  }

  var pages = [
    WalletMainBody(),
    private_sale(),
    Settings(isDarkMode: isDarkMode),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: appBackground,
          currentIndex: currentIndex_,
          onTap: (index) {
            setState(() {
              currentIndex_ = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_balance_wallet,
                size: 30,
              ),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.swap_horiz,
                size: 40,
              ),
              label: 'Swap',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings,
                size: 30,
              ),
              label: 'Settings',
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIndex_,
          children: pages,
        ));
  }
}

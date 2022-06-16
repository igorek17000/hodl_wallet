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
  PageController pageController;
  var currentIndex_ = 0;
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
  }

  _onTapped(int index) {
    setState(() {
      currentIndex_ = index;
    });
    pageController.animateToPage(index,
        duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex_ = index;
    });
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
          onTap: _onTapped,
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
        body: PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          children: pages,
        ));
  }
}

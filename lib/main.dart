import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cryptowallet/components/AppSignIn.dart';
import 'package:cryptowallet/components/AppVerifyLogin.dart';
import 'package:cryptowallet/screens/confirm_seed_phrase.dart';
import 'package:cryptowallet/screens/createPin.dart';
import 'package:cryptowallet/utils/rpcUrls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                scaffoldBackgroundColor: appBackground,
                brightness: Brightness.dark,
                primarySwatch: Colors.deepPurple
                /* light theme settings */
                ),
            darkTheme: ThemeData(
                scaffoldBackgroundColor: appBackground,
                brightness: Brightness.dark,
                primarySwatch: Colors.deepPurple

                /* dark theme settings */
                ),
            themeMode: currentMode,
            home: MyHomePage(),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen(
        splashIconSize: 100,
        backgroundColor: Colors.black26,
        splash: 'assets/logo.png',
        nextScreen: FutureBuilder(
          future: () async {
            var pref = await SharedPreferences.getInstance();
            return (pref.getString(userUnlockPasscodeKey) != null);
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == true)
                return MainScreen();
              else
                return enterPin();
            }
            return enterPin();
          },
        ),
        splashTransition: SplashTransition.slideTransition,
      ),
    );
  }
}

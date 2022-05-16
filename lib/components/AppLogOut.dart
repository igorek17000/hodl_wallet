import 'package:cryptowallet/components/AppSignIn.dart';
import 'package:cryptowallet/screens/main_screen.dart';
import 'package:cryptowallet/screens/wallet.dart';
import 'package:cryptowallet/utils/constants.dart';
import 'package:flutter/material.dart';
import '../utils/Urls.dart';
import '../utils/get_cookie.dart';
import '../utils/httpProxy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AppLogout {
  static logOut(context) async {
    var logOutPref = await SharedPreferences.getInstance();
    var userVerified = logOutPref.getString(USER_VERIFIED);

    var usefulResponseHeaders = await getSessionCookie();
    await useHttpProxy().get(
        Uri.parse(
            '${Urls.ROOT_URL}/tech/logout?csrf_token=${usefulResponseHeaders[CSRF_TOKEN_HEADER_NAME]}'),
        headers: {
          'Cookie':
              '$SESSION_COOKIE_NAME=${usefulResponseHeaders[SESSION_COOKIE_NAME]}; $USER_VERIFIED=$userVerified'
        });
    logOutPref.remove(USER_VERIFIED);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => AppSignIn(),
        ),
        (r) => false);
  }
}

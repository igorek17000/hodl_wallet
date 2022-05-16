import 'package:cryptowallet/utils/constants.dart';

import 'Urls.dart';
import 'httpProxy.dart';

getSessionCookie() async {
  var rawHeaders = (await useHttpProxy().head(Uri.parse(Urls.ROOT_URL))).headers;
  String rawCookie = rawHeaders['set-cookie'];
  if (rawCookie != null) {
    int index = rawCookie.indexOf(';');
    var rawCookieMap =
        ((index == -1) ? rawCookie : rawCookie.substring(0, index)).split('=');
    if (rawCookieMap[0] == SESSION_COOKIE_NAME) {
      return {
        SESSION_COOKIE_NAME: rawCookieMap[1],
        CSRF_TOKEN_HEADER_NAME: rawHeaders[CSRF_TOKEN_HEADER_NAME]
      };
    }
  }
}

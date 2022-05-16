import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

IOClient useHttpProxy() {
  var httpClient = HttpClient();

  var debug = false;

  if (debug)
    (httpClient..badCertificateCallback = (cert, host, port) => true)
      ..findProxy = (uri) {
        return "PROXY 192.168.137.1:8888";
      };

  return IOClient(httpClient);
}

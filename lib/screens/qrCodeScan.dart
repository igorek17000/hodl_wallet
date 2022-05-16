import 'dart:io';

import 'package:cryptowallet/screens/sendToken.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class qrCodeScan extends StatefulWidget {
  var routeKey;
  var data;
  var seedPhrase;
  qrCodeScan({this.routeKey, this.data, this.seedPhrase});
  @override
  _qrCodeScanState createState() => _qrCodeScanState();
}

class _qrCodeScanState extends State<qrCodeScan> {
  var result;
  var controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller.pauseCamera();
      } else if (Platform.isIOS) {
        controller.resumeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 400, height: 400, child: _buildQrView(context));
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      Widget routes = {
        'sendToken': SendToken(
          addressData: scanData.code,
          data: widget.data,
          seedPhrase: widget.seedPhrase,
        )
      }[widget.routeKey];
      controller.dispose();
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => routes));
    });
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    if (controller != null) controller.dispose();
    super.dispose();
  }
}

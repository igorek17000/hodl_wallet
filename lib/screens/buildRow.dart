import 'package:flutter/material.dart';

import '../utils/rpcUrls.dart';

Widget buildRow(String imageAsset, String name) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(height: 2, color: appBackground),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            CircleAvatar(backgroundImage: AssetImage(imageAsset)),
            SizedBox(width: 12),
            Text(name),
            Spacer(),
          ],
        ),
      ],
    ),
  );
}

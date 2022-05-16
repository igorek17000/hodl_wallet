import 'package:cryptowallet/screens/dapp.dart';
import 'package:flutter/material.dart';

class showDappBookmarks extends StatefulWidget {
  var data;
  showDappBookmarks({this.data});
  @override
  State<showDappBookmarks> createState() => _showDappBookmarksState();
}

class _showDappBookmarksState extends State<showDappBookmarks> {
  @override
  Widget build(BuildContext context) {
    var bookmarkWidgets = <Widget>[];
    for (String key in (widget.data as Map).keys) {
      bookmarkWidgets.add(Container(
        width: double.infinity,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (ctx) => dapp(data: key)));
          },
          child: Text(key),
        ),
      ));
      bookmarkWidgets.add(Divider());
    }

    if (bookmarkWidgets.isEmpty) {
      bookmarkWidgets.add(Text('No bookmark saved yet'));
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BookMarks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 40,
                )
              ]..addAll(bookmarkWidgets),
            ),
          ),
        ),
      ),
    );
  }
}

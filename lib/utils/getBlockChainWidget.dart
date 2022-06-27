import 'package:cryptowallet/utils/format_money.dart';
import 'package:flutter/material.dart';

class getBlockChainWidget extends StatefulWidget {
  var image;
  var name;
  var priceWithCurrency;
  var cryptoChange;
  var cryptoAmount;
  getBlockChainWidget(
      {Key key,
      AssetImage image,
      String name,
      String priceWithCurrency,
      double cryptoChange,
      Widget cryptoAmount})
      : super(key: key) {
    this.image = image;
    this.name = name;
    this.priceWithCurrency = priceWithCurrency;
    this.cryptoChange = cryptoChange;
    this.cryptoAmount = cryptoAmount;
  }

  @override
  State<getBlockChainWidget> createState() => _getBlockChainWidgetState();
}

class _getBlockChainWidgetState extends State<getBlockChainWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: widget.image,
              ),
              SizedBox(
                width: 10,
              ),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.priceWithCurrency,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    formatMoney(widget.cryptoChange) + '%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: (widget.cryptoChange < 0)
                                            ? Color(0xffeb6a61)
                                            : Color(0xff01aa78)),
                                  )
                                ],
                              ),
                              widget.cryptoAmount
                            ],
                          )),
                        ],
                      ),
                    ]),
              )
            ],
          ),
        ),
      ]),
    );
    ;
  }
}

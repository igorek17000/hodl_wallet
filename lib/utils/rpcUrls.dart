import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http_parser/http_parser.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:local_auth/local_auth.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:bitcoin_flutter/src/models/networks.dart' as NETWORKS;
import 'package:bip32/bip32.dart' as bip32;
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:hex/hex.dart';

const NFTImageFieldName = 'myImage';

Future<bool> authenticateIsAvailable() async {
  var localAuth = LocalAuthentication();
  final isAvailable = await localAuth.canCheckBiometrics;
  final isDeviceSupported = await localAuth.isDeviceSupported();
  return isAvailable && isDeviceSupported;
}

final appBackground = Color(0xff060c24);

Map getBlockChains() {
  Map blockChains = {
    'Ethereum': {
      "rpc": 'https://mainnet.infura.io/v3/53163c736f1d4ba78f0a39ffda8d87b4',
      'chainId': 1,
      'block explorer': 'https://etherscan.io',
      'symbol': 'ETH',
    },
    'Smart Chain': {
      "rpc": 'https://bsc-dataseed.binance.org/',
      'chainId': 56,
      'block explorer': 'https://bscscan.com',
      'symbol': 'BNB',
      'image': 'assets/smartchain.png'
    },
    'Avalanche': {
      "rpc": 'https://api.avax.network/ext/bc/C/rpc',
      'chainId': 43114,
      'block explorer': 'https://snowtrace.io',
      'symbol': 'AVAX',
      'image': 'assets/avalanche.jpg'
    },
    'Fantom': {
      "rpc": 'https://rpc.ftm.tools/',
      'chainId': 250,
      'block explorer': 'https://ftmscan.com',
      'symbol': 'FTM',
      'image': 'assets/fantom.png'
    },
    'Huobi Eco Chain': {
      "rpc": 'https://http-mainnet-node.huobichain.com/',
      'chainId': 128,
      'block explorer': 'https://hecoinfo.com',
      'symbol': 'HT',
      'image': 'assets/huobi.png'
    },
    'Polygon Matic': {
      "rpc": 'https://polygon-rpc.com',
      'chainId': 137,
      'block explorer': 'https://polygonscan.com',
      'symbol': 'MATIC',
      'image': 'assets/polygon.png'
    },
    'Kucoin Chain': {
      "rpc": 'https://rpc-mainnet.kcc.network',
      'chainId': 321,
      'block explorer': 'https://explorer.kcc.io',
      'symbol': 'KCS',
      'image': 'assets/kucoin.png'
    },
    'Elastos': {
      "rpc": 'https://api.elastos.io/eth',
      'chainId': 20,
      'block explorer': 'https://explorer.elaeth.io',
      'symbol': 'ELA',
      'image': 'assets/elastos.png'
    },
    'xDai': {
      "rpc": 'https://rpc.xdaichain.com/',
      'chainId': 100,
      'block explorer': 'https://blockscout.com/xdai/mainnet',
      'symbol': 'XDAI',
      'image': 'assets/xdai.jpg'
    },
    'Ubiq': {
      "rpc": 'https://rpc.octano.dev/',
      'chainId': 8,
      'block explorer': 'https://ubiqscan.io',
      'symbol': 'UBQ',
      'image': 'assets/ubiq.png'
    },
    'Celo': {
      "rpc": 'https://rpc.ankr.com/celo',
      'chainId': 42220,
      'block explorer': 'https://explorer.celo.org',
      'symbol': 'CELO',
      'image': 'assets/celo.png'
    },
    'Fuse': {
      "rpc": 'https://rpc.fuse.io',
      'chainId': 122,
      'block explorer': 'https://explorer.fuse.io/',
      'symbol': 'FUSE',
      'image': 'assets/fuse.png'
    },
  };

  if (!kReleaseMode) {
    blockChains['Smart Chain(Testnet)'] = {
      "rpc": 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      'chainId': 97,
      'block explorer': 'https://testnet.bscscan.com',
      'symbol': 'BNB',
      'image': 'assets/smartchain.png'
    };
    blockChains['Ethereum(Rinkeby)'] = {
      "rpc": 'https://rinkeby.infura.io/v3/53163c736f1d4ba78f0a39ffda8d87b4',
      'chainId': 4,
      'block explorer': 'https://rinkeby.etherscan.io',
      'symbol': 'ETH',
    };
  }

  return blockChains;
}

const coinGeckCryptoSymbolToID = {
  "BTC": "bitcoin",
  "ETH": "ethereum",
  "BNB": "binancecoin",
  "AVAX": "avalanche-2",
  "FTM": "fantom",
  "HT": "huobi-token",
  "MATIC": "matic-network",
  "KCS": "kucoin-shares",
  "ELA": "elastos",
  "XDAI": "xdai",
  "UBQ": "ubiq",
  "CELO": "celo",
  "FUSE": "fuse-network-token",
  "LTC": "litecoin",
  "DOGE": "dogecoin"
};
const appBaseUrl = 'https://memnormic-phrase-generator.herokuapp.com/';
const appCreateNFT = '${appBaseUrl}create-nft';
const resolveEns = "${appBaseUrl}resolve-ens/";
const dappBrowserInitialUrl = 'https://google.com';

Future resolveCryptoNameService(
    {String cryptoDomainName, String rpc, String currency}) async {
  // send get request
  try {
    final response = await http.post(Uri.parse(resolveEns + cryptoDomainName),
        body: jsonEncode(
          {'rpc': rpc, 'currency': currency},
        ),
        headers: {
          'Content-Type': 'application/json',
        });
    // return json decode response
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'msg': 'Error resolving ens'};
  }
}

Future calculateKey(String mnemonic) async {
  return jsonDecode((await get(
          Uri.parse("${appBaseUrl}create-wallet?memornic_phrase=" + mnemonic)))
      .body);
}

Future<bool> isInternetConnected() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  } on SocketException catch (_) {
    return false;
  }
}

Future<Map> getLiteCoinFromMemnomic(String mnemonic) async {
  var storedKey = await SharedPreferences.getInstance();
  var keyName = 'litecoinDetail';
  if (storedKey.getString(keyName) != null) {
    var mmenomicMapping = (jsonDecode(storedKey.getString(keyName)) as List);
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
    var keys = calculateLitecoinKey(mnemonic);
    storedKey.setString(keyName,
        jsonEncode(mmenomicMapping..add({'key': keys, 'mmenomic': mnemonic})));
    return keys;
  } else {
    var keys = calculateLitecoinKey(mnemonic);
    storedKey.setString(
        keyName,
        jsonEncode([
          {'key': keys, 'mmenomic': mnemonic}
        ]));
    return keys;
  }
}

Future<Map> getBitCoinFromMemnomic(String mnemonic, {bool istestnet}) async {
  var storedKey = await SharedPreferences.getInstance();
  var keyName = istestnet != null && istestnet == true
      ? 'bitcoinDetailTestNet'
      : 'bitcoinDetail';
  if (storedKey.getString(keyName) != null) {
    var mmenomicMapping = (jsonDecode(storedKey.getString(keyName)) as List);
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
    var keys = calculateBitCoinKey(mnemonic, istestnet: istestnet);
    storedKey.setString(keyName,
        jsonEncode(mmenomicMapping..add({'key': keys, 'mmenomic': mnemonic})));
    return keys;
  } else {
    var keys = calculateBitCoinKey(mnemonic, istestnet: istestnet);
    storedKey.setString(
        keyName,
        jsonEncode([
          {'key': keys, 'mmenomic': mnemonic}
        ]));
    return keys;
  }
}

Future<Map> getDogeCoinFromMemnomic(String mnemonic) async {
  var storedKey = await SharedPreferences.getInstance();
  var keyName = 'dogeDetail';
  if (storedKey.getString(keyName) != null) {
    var mmenomicMapping = (jsonDecode(storedKey.getString(keyName)) as List);
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
    var keys = calculateDogeCoinKey(mnemonic);
    storedKey.setString(keyName,
        jsonEncode(mmenomicMapping..add({'key': keys, 'mmenomic': mnemonic})));
    return keys;
  } else {
    var keys = calculateDogeCoinKey(mnemonic);
    storedKey.setString(
        keyName,
        jsonEncode([
          {'key': keys, 'mmenomic': mnemonic}
        ]));
    return keys;
  }
}

Map calculateBitCoinKey(String seedPhrase, {bool istestnet}) {
  final seed = bip39.mnemonicToSeed(seedPhrase);
  final root = bip32.BIP32.fromSeed(seed);
  final node = istestnet != null && istestnet == true
      ? root.derivePath("m/44'/0'/0'/0/0")
      : root.derivePath("m/84'/0'/0'/0/0");

  var address;
  if (istestnet != null && istestnet == true) {
    address = P2PKH(
            data: PaymentData(
              pubkey: node.publicKey,
            ),
            network: NETWORKS.testnet)
        .data
        .address;
  } else {
    address = P2WPKH(
      data: PaymentData(
        pubkey: node.publicKey,
      ),
    ).data.address;
  }

  print(HEX.encode(node.privateKey));

  return {'address': address, 'private_key': HEX.encode(node.privateKey)};
}

NETWORKS.NetworkType litecoin = NETWORKS.NetworkType(
    messagePrefix: '\x19Litecoin Signed Message:\n',
    bech32: 'ltc',
    bip32: NETWORKS.Bip32Type(public: 0x019da462, private: 0x019d9cfe),
    pubKeyHash: 0x30,
    scriptHash: 0x32,
    wif: 0xb0);
NETWORKS.NetworkType dogeCoin = NETWORKS.NetworkType(
    messagePrefix: '\x19Dogecoin Signed Message:\n',
    bip32: NETWORKS.Bip32Type(public: 0x02facafd, private: 0x02fac398),
    pubKeyHash: 0x1e,
    scriptHash: 0x16,
    wif: 0x9e);

Map calculateLitecoinKey(String seedPhrase) {
  final seed = bip39.mnemonicToSeed(seedPhrase);
  final root = bip32.BIP32.fromSeed(seed);
  final node = root.derivePath("m/84'/2'/0'/0/0");
  var address = P2WPKH(
          data: PaymentData(
            pubkey: node.publicKey,
          ),
          network: litecoin)
      .data
      .address;
  return {'address': address, 'private_key': HEX.encode(node.privateKey)};
}

Future getLitecoinTransactionFee(
    String address, String private_key, double litoshisToSend) async {
  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'network': 'LTC',
            'private_key': private_key,
            'amount': litoshisToSend,
            'getFee': true,
            'senderAddress': address
          })))
      .body;
}

Future getDogecoinTransactionFee(
    String address, String private_key, double satoshisToSend) async {
  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'network': 'DOGE',
            'private_key': private_key,
            'amount': satoshisToSend,
            'getFee': true,
            'senderAddress': address
          })))
      .body;
}

Map calculateDogeCoinKey(String seedPhrase) {
  final seed = bip39.mnemonicToSeed(seedPhrase);
  final root = bip32.BIP32.fromSeed(seed);
  final node = root.derivePath("m/44'/3'/0'/0/0");
  var address = P2PKH(
          data: PaymentData(
            pubkey: node.publicKey,
          ),
          network: dogeCoin)
      .data
      .address;
  return {'address': address, 'private_key': HEX.encode(node.privateKey)};
}

Future<Map> getDogecoinAddressDetails(String address) async {
  var pref = await SharedPreferences.getInstance();
  var key = 'dogeAddress';
  try {
    var data = (await get(Uri.parse(
            'https://sochain.com/api/v2/get_address_balance/DOGE/${address}')))
        .body;
    pref.setString(key, data);

    return {
      'final_balance':
          double.parse(jsonDecode(data)['data']['confirmed_balance'])
    };
  } catch (e) {
    if (pref.getString(key) != null) {
      return {
        'final_balance': double.parse(
            jsonDecode(pref.getString(key))['data']['confirmed_balance'])
      };
    } else {
      return {'final_balance': 0};
    }
  }
}

Future<Map> getBitcoinAddressDetails(String address, {istestnet}) async {
  var pref = await SharedPreferences.getInstance();
  var key = 'bitCoinAddress';
  try {
    var data = (await get(Uri.parse(
            'https://sochain.com/api/v2/get_address_balance/${istestnet != null && istestnet == true ? 'BTCTEST' : 'BTC'}/${address}')))
        .body;
    pref.setString(key, data);

    return {
      'final_balance':
          double.parse(jsonDecode(data)['data']['confirmed_balance'])
    };
  } catch (e) {
    if (pref.getString(key) != null) {
      return {
        'final_balance': double.parse(
            jsonDecode(pref.getString(key))['data']['confirmed_balance'])
      };
    } else {
      return {'final_balance': 0};
    }
  }
}

Future getBitCoinTransactionFee(
    String senderAddress, String private_key, double bitCoinToSend,
    {istestnet}) async {
  var data = jsonEncode({
    'network': 'BTC',
    'private_key': private_key,
    'amount': bitCoinToSend,
    'getFee': true,
    'senderAddress': senderAddress,
  });

  if (istestnet != null && istestnet == true) {
    data = jsonEncode({
      'private_key': private_key,
      'amount': bitCoinToSend,
      'getFee': true,
      'senderAddress': senderAddress
    });
  }
  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'}, body: data))
      .body;
}

Future sendBitCoin(String senderAddressString, recipientAddress,
    String private_key, double bitCoinToSend,
    {istestnet}) async {
  var data = jsonEncode({
    'network': 'BTC',
    'private_key': private_key,
    'amount': bitCoinToSend,
    'senderAddress': senderAddressString,
    'recipient': recipientAddress
  });

  if (istestnet != null && istestnet == true) {
    data = jsonEncode({
      'private_key': private_key,
      'amount': bitCoinToSend,
      'senderAddress': senderAddressString,
      'recipient': recipientAddress
    });
  }

  print(data);

  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'}, body: data))
      .body;
}

Future sendLiteCoin(String senderAddress, String recipientAddress,
    String private_key, double litoshi) async {
  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'network': 'LTC',
            'private_key': private_key,
            'amount': litoshi,
            'sendAddress': senderAddress,
            'recipient': recipientAddress
          })))
      .body;
}

Future sendDogeCoin(String senderAddress, String recipientAddress,
    String private_key, double sashoshi) async {
  return (await post(Uri.parse('${appBaseUrl}sendBitcoin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'network': 'DOGE',
            'private_key': private_key,
            'amount': sashoshi,
            'sendAddress': senderAddress,
            'recipient': recipientAddress
          })))
      .body;
}

Future<Map> getLitecoinAddressDetails(String address) async {
  var pref = await SharedPreferences.getInstance();
  var key = 'litecoinAddress';
  try {
    var data = (await get(Uri.parse(
            'https://sochain.com/api/v2/get_address_balance/LTC/${address}')))
        .body;
    pref.setString(key, data);

    return {
      'final_balance':
          double.parse(jsonDecode(data)['data']['confirmed_balance'])
    };
  } catch (e) {
    if (pref.getString(key) != null) {
      return {
        'final_balance': double.parse(
            jsonDecode(pref.getString(key))['data']['confirmed_balance'])
      };
    } else {
      return {'final_balance': 0};
    }
  }
}

Future<String> getCryptoPrice() async {
  var allCrypto = "";
  var currentIndex = 0;
  var listOfCoinGeckoValue = coinGeckCryptoSymbolToID.values;
  for (var value in listOfCoinGeckoValue) {
    // remove the last comma
    if (currentIndex == listOfCoinGeckoValue.length - 1) {
      allCrypto += value;
    } else {
      allCrypto += value + ",";
    }
    currentIndex++;
  }

  var storedKey = await SharedPreferences.getInstance();
  try {
    String defaultCurrency = storedKey.getString('defaultCurrency') ?? "usd";
    var responseBody = (await get(Uri.parse(
            'https://api.coingecko.com/api/v3/simple/price?ids=${allCrypto}&vs_currencies=${defaultCurrency}&include_24hr_change=true')))
        .body;


    await storedKey.setString('cryptoPrices', responseBody);
    return responseBody;
  } catch (e) {
    if (storedKey.getString('cryptoPrices') != null) {
      return storedKey.getString('cryptoPrices');
    }
    return null;
  }
}

Future<double> getERC20TokenBalance(Map element) async {
  final client = web3.Web3Client(
    element['rpc'],
    Client(),
  );

  final pref = await SharedPreferences.getInstance();

  var elementBalanceKey =
      '${element['rpc'].toString().toLowerCase()}${element['contractAddress'].toString().toLowerCase()} balance';

  try {
    final contract = web3.DeployedContract(
        web3.ContractAbi.fromJson(erc20Abi, 'MetaCoin'),
        web3.EthereumAddress.fromHex(element['contractAddress']));

    var seedPhrase = pref.getString('mmemomic');
    var response = await getCryptoKeys(seedPhrase);

    final balanceFunction = contract.function('balanceOf');

    final decimalsFunction = contract.function('decimals');

    final decimals = (await client
            .call(contract: contract, function: decimalsFunction, params: []))
        .first
        .toString();

    final balance = (await client.call(
            contract: contract,
            function: balanceFunction,
            params: [EthereumAddress.fromHex(response['eth_wallet_address'])]))
        .first
        .toString();
    await pref.setString(
        elementBalanceKey,
        jsonEncode({
          'balance': balance,
          'decimals': decimals,
        }));
    return double.parse(balance) / pow(10, double.parse(decimals));
  } catch (e) {
    if (pref.getString(elementBalanceKey) != null) {
      var crytoBalance = jsonDecode(pref.getString(elementBalanceKey));
      return double.parse(crytoBalance['balance']) /
          pow(10, double.parse(crytoBalance['decimals']));
    } else {
      return 0;
    }
  }
}

Future<double> getCryptoChange(String symbol) async {
  var storedKey = await SharedPreferences.getInstance();
  try {
    var dataResponse = jsonDecode((await get(Uri.parse(
            'https://api.binance.com/api/v1/ticker/24hr?symbol=${symbol}USDT')))
        .body) as Map;

    var change = double.tryParse(dataResponse['priceChangePercent']);

    await storedKey.setDouble('${symbol}Change', change);
    return change;
  } catch (e) {
    if (storedKey.getDouble('${symbol}Change') != null) {
      return storedKey.getDouble('${symbol}Change');
    }
    return 0;
  }
}

Future<double> getTransactionFee(String rpc, Uint8List data,
    web3.EthereumAddress sender, web3.EthereumAddress to,
    {value}) async {
  final client = web3.Web3Client(
    rpc,
    Client(),
  );
  if (value != null) {
    value = web3.EtherAmount.inWei(BigInt.from(value));
  }
  final gasPrice = await client.getGasPrice();
  final gasUnit = await client.estimateGas(
      gasPrice: gasPrice, sender: sender, to: to, data: data, value: value);

  return gasPrice.getValueInUnit(web3.EtherUnit.wei) * gasUnit.toDouble();
}

Future<Map> getCryptoKeys(String mnemonic) async {
  var storedKey = await SharedPreferences.getInstance();
  if (storedKey.getString('keys') != null) {
    var mmenomicMapping = (jsonDecode(storedKey.getString('keys')) as List);
    for (int i = 0; i < mmenomicMapping.length; i++) {
      if (mmenomicMapping[i]['mmenomic'] == mnemonic) {
        return mmenomicMapping[i]['key'];
      }
    }
    var keys = await calculateKey(mnemonic);
    storedKey.setString('keys',
        jsonEncode(mmenomicMapping..add({'key': keys, 'mmenomic': mnemonic})));
    return keys;
  } else {
    var keys = await calculateKey(mnemonic);
    storedKey.setString(
        'keys',
        jsonEncode([
          {'key': keys, 'mmenomic': mnemonic}
        ]));
    return keys;
  }
}

Future<String> getCurrencyJson() async {
  return await rootBundle.loadString('json/currencies.json');
}

Future<num> getCurrencyPriceFromUSD(String currencySymbol) async {
  var pref = await SharedPreferences.getInstance();
  try {
    var response = (jsonDecode((await get(Uri.parse(
            'https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=${currencySymbol.toUpperCase()}')))
        .body) as Map)[currencySymbol];

    pref.setString('${currencySymbol}/USD', response.toString());
    return response;
  } catch (e) {
    if (pref.getString('${currencySymbol}/USD') != null) {
      return double.parse(pref.getString('${currencySymbol}/USD'));
    } else
      return null;
  }
}

upload(File imageFile, String fileName, MediaType imageMediaType, uploadURL,
    Map fieldsMap) async {
  try {
    var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse(uploadURL);

    var request = http.MultipartRequest("POST", uri);
    for (var key in fieldsMap.keys) {
      request.fields[key] = fieldsMap[key];
    }

    var multipartFile = http.MultipartFile(fileName, stream, length,
        filename: basename(imageFile.path), contentType: imageMediaType);

    request.files.add(multipartFile);
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  } catch (e) {
    print('failed upload' + e.toString());
  }
}

Future<double> getEthBalance({rpcUrl}) async {
  var sharedPreferencesInst = await SharedPreferences.getInstance();
  try {
    var seedPhrase = sharedPreferencesInst.getString('mmemomic');
    var response = await getCryptoKeys(seedPhrase);
    await sharedPreferencesInst.setString(
        'privateKey', response['eth_wallet_privateKey']);

    var httpClient = Client();
    var ethClient = Web3Client(rpcUrl, httpClient);

    double ethBalance = (await ethClient.getBalance(
                EthereumAddress.fromHex(response['eth_wallet_address'])))
            .getInWei
            .toDouble() /
        pow(10, 18);

    sharedPreferencesInst.setDouble(rpcUrl, ethBalance);

    return ethBalance;
  } catch (e) {
    if (sharedPreferencesInst.getDouble(rpcUrl) != null) {
      return sharedPreferencesInst.getDouble(rpcUrl);
    } else {
      return 0;
    }
  }
}

final privateSaleDataKey = "privateSaleKey";

final Duration forFetch = Duration(seconds: 30);

const convertionRate = 0.03;

const buyCryptoLink = 'https://www.moonpay.com';
const bitCoinScanUrl = 'https://www.blockchain.com/btc/address/';
const followTwitterAccount = 'http://twitter.com';
const retweetPost = 'http://twitter.com';
const joinDiscord = 'https://discord.com/';
const joinTelegram = 'http://telegram.org';
const private_saleAddr = '0x0000000000000000000000000000000000000000';
const admin = '0x6Acf5505DF3Eada0BF0547FAb88a85b1A2e03F15';
const grey = Colors.grey;
const userUnlockPasscodeKey = 'userUnlockPasscode';

/** custom name and address for app token */
const walletAbbr = 'HDL';
const walletName = ' HODL Wallet';
const walletURL = "https://hodlverse.app";
const walletIconURL = "https://hodlverse.app/game/logo.png";
const tokenContractAddress = kReleaseMode
    ? '0x677676c090c7CD76976E40285666e2D0A0108852'
    : '0x12Ffd42ddC7E7597AaD957E0B1a8cDd02416Da53';
const tokenNFTContractAddress = kReleaseMode
    ? '0x1Ac44321888CE192B94060759ccCBaEc910c2018'
    : '0x7e707C310F30Ce5832D9d3078E88B0f1A00886AA';

const walletContractNetworkMainNet = 'Smart Chain';
const walletContractNetworkTestNet = 'Smart Chain(Testnet)';

const walletContractNetwork =
    kReleaseMode ? walletContractNetworkMainNet : walletContractNetworkTestNet;

const walletNFTContractNetworkMainNet = 'Smart Chain';
const walletNFTContractNetworkTestNet = 'Smart Chain(Testnet)';

const walletNFTContractNetwork =
    kReleaseMode ? walletContractNetworkMainNet : walletContractNetworkTestNet;
/** end of custom name and address for app token */
const erc721Abi =
    '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"TOKEN_LIMIT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address payable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"priceInWei","type":"uint256"}],"name":"allowBuy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"buy","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"createTokenId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"disallowBuy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMintingPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"mintedNFTPrices","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"mintingPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_mintingPrice","type":"uint256"}],"name":"setMintingPrice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"baseURL","type":"string"}],"name":"setTokenBaseURL","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokenBaseURL","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"tokenForSale","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalItemForSale","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"trans","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}]''';
const erc20Abi =
    '''[{"constant":false,"inputs":[{"name":"_isAirdropRunning","type":"bool"}],"name":"setAirdropActivation","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_refer","type":"address"}],"name":"getAirdrop","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleCap","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getBalance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleTot","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"privateSaletokensSold","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_saleChunk","type":"uint256"},{"name":"_salePrice","type":"uint256"},{"name":"_saleCap","type":"uint256"},{"name":"_sDivisionInt","type":"uint256"}],"name":"startSale","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"viewSale","outputs":[{"name":"SaleCap","type":"uint256"},{"name":"SaleCount","type":"uint256"},{"name":"ChunkSize","type":"uint256"},{"name":"SalePrice","type":"uint256"},{"name":"privateSaletokensSold","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_refer","type":"address"}],"name":"tokenSale","outputs":[{"name":"success","type":"bool"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[],"name":"sDivisionInt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"saleChunk","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"tran","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_airdropAmt","type":"uint256"},{"name":"_airdropCap","type":"uint256"},{"name":"_aDivisionInt","type":"uint256"}],"name":"startAirdrop","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"isSaleRunning","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"airdropCap","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"to","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"txnToken","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"tokens","type":"uint256"},{"name":"data","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"airdropAmt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"viewAirdrop","outputs":[{"name":"DropCap","type":"uint256"},{"name":"DropCount","type":"uint256"},{"name":"DropAmount","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenOwner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"airdropTot","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_isSaleRunning","type":"bool"}],"name":"setSaleActivation","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"aDivisionInt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"salePrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"isAirdropRunning","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"tokenOwner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"tokens","type":"uint256"}],"name":"Approval","type":"event"}]''';
const coinbaseApiKey = '76668e58-4186-46a5-8478-5b16cd96d3c6';
const email = 'naxtrust.global@gmail.com';
const red = Color(0xffeb6a61);
const green = Color(0xff01aa78);

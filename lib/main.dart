import 'package:flutter/material.dart';

import 'package:darttonconnect/exceptions.dart';
import 'package:darttonconnect/logger.dart';
import 'package:darttonconnect/ton_connect.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                fixedSize: MaterialStateProperty.all(const Size(200, 30)))),
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initialize TonConnect.
  final TonConnect connector = TonConnect(
      'https://gist.githubusercontent.com/romanovichim/e81d599a6f3798bb9f74ab1970a8b376/raw/43e00b0abc824ef272ac6d0f8083d21456602adf/gistfiletest.txt');
  Map<String, String>? walletConnectionSource;
  String? universalLink;

  @override
  void initState() {
    // Override default initState method to call restoreConnection
    // method after screen reloading.
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!connector.connected) {
        restoreConnection();
      }
    });
  }

  /// Create connection and generate QR code to connect a wallet.
  void initialConnect() async {
    const walletConnectionSource = {
      "universalUrl": 'https://app.tonkeeper.com/ton-connect',
      "bridgeUrl": 'https://bridge.tonapi.io/bridge'
    };

    final universalLink = await connector.connect(walletConnectionSource);
    updateQRCode(universalLink);

    connector.onStatusChange((walletInfo) {
      logger.i('Произошло изменение подключения');
    });
  }

  /// Restore connection from memory.
  void restoreConnection() {
    connector.restoreConnection();
  }

  void updateQRCode(String newData) {
    setState(() => universalLink = newData);
  }

  /// Disconnect from current wallet.
  void disconnect() {
    if (connector.connected) {
      connector.disconnect();
    } else {
      logger.i("Сначала коннект, потом дисконект");
    }
  }

  /// Send transaction with specified data.
  void sendTrx() async {
    if (!connector.connected) {
      logger.i("Сначала коннект, потом дисконект");
    } else {
      const transaction = {
        "validUntil": 1918097354,
        "messages": [
          {
            "address":
                "0:575af9fc97311a11f423a1926e7fa17a93565babfd65fe39d2e58b8ccb38c911",
            "amount": "20000000",
          }
        ]
      };

      try {
        await connector.sendTransaction(transaction);
      } catch (e) {
        if (e is UserRejectsError) {
          logger.d(
              'You rejected the transaction. Please confirm it to send to the blockchain');
        } else {
          logger.d('Unknown error happened $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: initialConnect,
                child: const Text('Create initial connect')),
            const SizedBox(height: 15),
            ElevatedButton(
                onPressed: disconnect, child: const Text('Disconnect')),
            const SizedBox(height: 15),
            ElevatedButton(onPressed: sendTrx, child: const Text('Sendtxes')),
            const SizedBox(height: 15),
            if (universalLink != null)
              QrImageView(
                data: universalLink!,
                version: QrVersions.auto,
                size: 320,
                gapless: false,
              )
          ],
        ),
      ),
    ));
  }
}

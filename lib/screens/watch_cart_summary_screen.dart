import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';

class WatchCartSummaryScreen extends StatefulWidget {
  const WatchCartSummaryScreen({super.key});

  @override
  State<WatchCartSummaryScreen> createState() => _WatchCartSummaryScreenState();
}

class _WatchCartSummaryScreenState extends State<WatchCartSummaryScreen> {
  int totalItems = 0;
  String totalPrice = '0.00';

  @override
  void initState() {
    super.initState();

    WatchConnectivity().messageStream.listen((message) {
      if (message.containsKey('totalItems') && message.containsKey('totalPrice')) {
        setState(() {
          totalItems = message['totalItems'];
          totalPrice = message['totalPrice'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AmbientMode(
      builder: (context, mode, child) => child!,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Cart Summary", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text("Items: $totalItems", style: const TextStyle(fontSize: 16)),
              Text("Total: \$$totalPrice", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

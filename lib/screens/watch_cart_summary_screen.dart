import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider_sample/screens/watch_cart_list_screen.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/service/encrypt_decrypt_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class WatchCartSummaryScreen extends StatefulWidget {
  const WatchCartSummaryScreen({super.key});

  @override
  State<WatchCartSummaryScreen> createState() => _WatchCartSummaryScreenState();
}

class _WatchCartSummaryScreenState extends State<WatchCartSummaryScreen> {
  int totalItems = 0;
  String totalPrice = '0.00';
  bool isLoading = true;

  final _encryptionService = EncryptDecryptService();

  @override
  void initState() {
    super.initState();
    listenToIncomingMessages();
    loadCachedCartSummary();
  }

  void listenToIncomingMessages() {
    WatchConnectivity().messageStream.listen((message) async {
      debugPrint("[WatchCartSummary] Received message: $message");

      if (message.containsKey('totalItems') && message.containsKey('totalPrice')) {
        final totalItemsValue = message['totalItems'];
        final totalPriceValue = message['totalPrice'];

        if (totalItemsValue is int && totalPriceValue is String) {
          if (mounted) {
            setState(() {
              totalItems = totalItemsValue;
              totalPrice = totalPriceValue;
              isLoading = false;
            });
            showCartNotificationOnWatch(totalItems, totalPrice);
          }

          final prefs = await SharedPreferences.getInstance();
          final encrypted = _encryptionService.encryptData(jsonEncode({
            'totalItems': totalItemsValue,
            'totalPrice': totalPriceValue,
          }));
          await prefs.setString('cartSummary', encrypted);

          debugPrint("[WatchCartSummary] Saved encrypted cart summary to storage.");
        } else {
          debugPrint("[WatchCartSummary] Invalid types: totalItems=${totalItemsValue.runtimeType}, totalPrice=${totalPriceValue.runtimeType}");
        }
      } else {
        debugPrint("[WatchCartSummary] Incomplete or unrelated message: $message");
      }
    });
  }

  Future<void> loadCachedCartSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('cartSummary');

    debugPrint("[WatchCartSummary] Attempting to load cart summary from prefs...");
    debugPrint("[WatchCartSummary] Encrypted summary: $encrypted");

    if (encrypted != null) {
      try {
        final decrypted = _encryptionService.decryptData(encrypted);
        debugPrint("[WatchCartSummary] Decrypted summary: $decrypted");
        final data = jsonDecode(decrypted);

        if (mounted) {
          setState(() {
            totalItems = data['totalItems'];
            totalPrice = data['totalPrice'];
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('[WatchCartSummary] Decryption or parsing failed: $e');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      debugPrint("[WatchCartSummary] No cart summary found in SharedPreferences.");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> showCartNotificationOnWatch(int items, String price) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'watch_cart_channel',
      'Watch Cart Alerts',
      channelDescription: 'Notifications for cart updates on watch',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Cart Updated',
      '$items items totaling \$$price in your cart.',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AmbientMode(
      builder: (context, mode, child) => child!,
      child: Scaffold(
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Cart Summary",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Items: $totalItems",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Total: \$$totalPrice",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WatchCartListScreen(),
                    ),
                  );
                },
                child: const Text("Cart List"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../utils/service/encrypt_decrypt_service.dart';

class WatchCartListScreen extends StatefulWidget {
  const WatchCartListScreen({super.key});

  @override
  State<WatchCartListScreen> createState() => _WatchCartListScreenState();
}

class _WatchCartListScreenState extends State<WatchCartListScreen> {
  final WatchConnectivity _watch = WatchConnectivity();
  final _encryptionService = EncryptDecryptService();
  List<dynamic> cartItems = [];
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageSubscription = _watch.messageStream.listen((message) {
      debugPrint('[WatchCartList] Received message: $message');
      handleIncomingMessage(message);
    });

    loadCartFromPrefs();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  String decryptData(String encryptedData) {
    final decrypted = _encryptionService.decryptData(encryptedData);
    return decrypted;
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedCartList = prefs.getString('flutter.cartItems');

    if (encryptedCartList != null) {
      try {
        final decryptedCartList = decryptData(encryptedCartList);
        final decodedCartList = jsonDecode(decryptedCartList);
        setState(() {
          cartItems = decodedCartList;
        });
        debugPrint('Loaded cart items from prefs: $cartItems');
      } catch (e) {
        debugPrint('Decryption or parsing error (cartItems): $e');
      }
    } else {
      debugPrint('No cartItems found in SharedPreferences.');
    }
  }

  Future<void> deleteCartItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cartItems.removeAt(index);
    });

    final cartString = jsonEncode(cartItems);
    final encryptedCartString = _encryptionService.encryptData(cartString);
    await prefs.setString('flutter.cartItems', encryptedCartString);

    debugPrint('Cart item deleted and storage updated.');
  }

  void handleIncomingMessage(Map<String, dynamic> message) async {
    debugPrint('[WatchCartList] Received message: $message');

    if (message['type'] == 'cartList' && message['data'] is String) {
      try {
        final decrypted = _encryptionService.decryptData(message['data']);
        final List decoded = jsonDecode(decrypted);
        final prefs = await SharedPreferences.getInstance();
        final encryptedCartString = _encryptionService.encryptData(jsonEncode(decoded));
        await prefs.setString('flutter.cartItems', encryptedCartString);
        debugPrint('[WatchCartList] Decrypted and saved cart list with ${decoded.length} items.');
      } catch (e) {
        debugPrint('[WatchCartList] Failed to decode cartList: $e');
      }
    } else {
      debugPrint('[WatchCartList] Unrecognized or incomplete message: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 18),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Your Cart',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: cartItems.isEmpty
                    ? const Center(child: Text('No items in cart.'))
                    : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Price: \$${item['price'] ?? 0.0}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () => deleteCartItem(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

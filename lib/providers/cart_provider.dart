import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../models/product.dart';
import '../utils/service/encrypt_decrypt_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];
  final _encryptionService = EncryptDecryptService();
  final WatchConnectivity _watch = WatchConnectivity();

  List<Product> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice => _items.fold(0.0, (sum, p) => sum + p.price);

  CartProvider() {
    loadCartFromPrefs().then((_) {
      sendCartSummaryToWatch();
    });
  }


  void addToCart(Product product) {
    if (!_items.any((p) => p.id == product.id)) {
      _items.add(product);
      saveCartToPrefs();
      sendCartSummaryToWatch();
      notifyListeners();
      saveCartSummaryToPrefs();
      showCartNotification(product.title);
    }
  }

  void removeFromCart(Product product) {
    _items.removeWhere((p) => p.id == product.id);
    saveCartToPrefs();
    sendCartSummaryToWatch();
    notifyListeners();
    saveCartSummaryToPrefs();
  }

  void clearCart() {
    _items.clear();
    saveCartToPrefs();
    sendCartSummaryToWatch();
    notifyListeners();
    saveCartSummaryToPrefs();
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> jsonList = _items.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    final encryptedCart = _encryptionService.encryptData(jsonString);
    await prefs.setString('cartItems', encryptedCart);

    final summary = {
      'totalItems': itemCount,
      'totalPrice': totalPrice.toStringAsFixed(2),
    };
    final summaryString = jsonEncode(summary);
    final encryptedSummary = _encryptionService.encryptData(summaryString);
    await prefs.setString('cartSummary', encryptedSummary);
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedCart = prefs.getString('cartItems');

    if (encryptedCart != null) {
      try {
        final decryptedCart = _encryptionService.decryptData(encryptedCart);
        final List<dynamic> decoded = jsonDecode(decryptedCart);
        _items.clear();
        for (var item in decoded) {
          _items.add(Product.fromJson(item));
        }
        notifyListeners();
        sendCartSummaryToWatch();
      } catch (e) {
        debugPrint('Decryption or parsing error (cartItems): $e');
      }
    }
  }

  Future<void> sendCartSummaryToWatch() async {
    final isSupported = await _watch.isSupported;
    final isReachable = await _watch.isReachable;

    debugPrint('📡 Watch supported: $isSupported, reachable: $isReachable');


    final summary = {
      'totalItems': itemCount,
      'totalPrice': totalPrice.toStringAsFixed(2),
    };

    final prefs = await SharedPreferences.getInstance();
    final encrypted = _encryptionService.encryptData(jsonEncode(summary));
    await prefs.setString('cartSummary', encrypted);

    if (isSupported && isReachable) {
      try {
        await _watch.sendMessage(summary);
      } catch (e) {
        debugPrint('Error sending message to watch: $e');
      }
    }
  }


  Future<Map<String, dynamic>?> getCartSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedSummary = prefs.getString('cartSummary');

    if (encryptedSummary != null) {
      try {
        final decrypted = _encryptionService.decryptData(encryptedSummary);
        return jsonDecode(decrypted);
      } catch (e) {
        debugPrint('Decryption or parsing error (cartSummary): $e');
      }
    }
    return null;
  }

  Future<void> saveCartSummaryToPrefs() async {
    final isSupported = await _watch.isSupported;
    final isReachable = await _watch.isReachable;

    final summary = {
      'totalItems': itemCount,
      'totalPrice': totalPrice.toStringAsFixed(2),
    };

    if (isSupported && isReachable) {
      try {
        await _watch.sendMessage({
          'type': 'saveSummary',
          'data': summary,
        });
        debugPrint(' Sent summary to watch for saving.');
      } catch (e) {
        debugPrint(' Failed to send summary to watch: $e');
      }
    } else {
      debugPrint(' Watch not reachable or supported.');
    }
  }

  Future<void> showCartNotification(String productName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'cart_channel_id',
      'Cart Notifications',
      channelDescription: 'Notifications when products are added to cart',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '🛒 Item Added to Cart',
      '$productName has been added to your cart.',
      platformChannelSpecifics,
    );
  }


}

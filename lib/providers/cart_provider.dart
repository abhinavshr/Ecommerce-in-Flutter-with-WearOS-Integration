import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../models/product.dart';
import '../utils/service/encrypt_decrypt_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class CartAction {
  final String type; // 'add' or 'remove'
  final Product product;
  final DateTime timestamp;

  CartAction({required this.type, required this.product, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'type': type,
    'product': product.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };

  static CartAction fromJson(Map<String, dynamic> json) => CartAction(
    type: json['type'],
    product: Product.fromJson(json['product']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];
  final List<CartAction> _actionHistory = [];
  final _encryptionService = EncryptDecryptService();
  final WatchConnectivity _watch = WatchConnectivity();

  List<Product> get items => _items;
  List<CartAction> get actionHistory => _actionHistory;

  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0.0, (sum, p) => sum + p.price);

  CartProvider() {
    loadCartFromPrefs().then((_) {
      loadActionHistory();
      sendCartSummaryToWatch();
    });
  }

  void addToCart(Product product) {
    if (!_items.any((p) => p.id == product.id)) {
      _items.add(product);
      _logAction('add', product);
      notifyListeners();
      saveCartToPrefs();
      sendCartSummaryToWatch();
      saveCartSummaryToPrefs();
      showCartNotification(product.title);
      sendCartListToWatch();
    }
  }

  void removeFromCart(Product product) {
    final exists = _items.any((p) => p.id == product.id);
    _items.removeWhere((p) => p.id == product.id);

    if (exists) {
      _logAction('remove', product);
      saveCartToPrefs();
      sendCartSummaryToWatch();
      saveCartSummaryToPrefs();
      sendCartListToWatch();
      notifyListeners();
      showRemoveCartNotification(product.title);
    }
  }

  void clearCart() {
    _items.clear();
    saveCartToPrefs();
    sendCartSummaryToWatch();
    saveCartSummaryToPrefs();
    sendCartListToWatch();
    notifyListeners();
  }

  void _logAction(String type, Product product) {
    final action = CartAction(
      type: type,
      product: product,
      timestamp: DateTime.now(),
    );
    _actionHistory.insert(0, action);
    if (_actionHistory.length > 5) {
      _actionHistory.removeLast();
    }
    saveActionHistory();
  }

  Future<void> saveActionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final logList = _actionHistory.map((a) => a.toJson()).toList();
    final jsonString = jsonEncode(logList);
    await prefs.setString('cartActionHistory', jsonString);
  }

  Future<void> loadActionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cartActionHistory');
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _actionHistory.clear();
        _actionHistory.addAll(decoded.map((e) => CartAction.fromJson(e)));
      } catch (e) {
        debugPrint('Failed to load action history: $e');
      }
    }
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

  Future<void> sendCartListToWatch() async {
    final isSupported = await _watch.isSupported;
    final isReachable = await _watch.isReachable;

    if (isSupported && isReachable) {
      try {
        if (_items.isNotEmpty) {
          final cartData = _items.map((p) => p.toJson()).toList();
          final cartDataJson = jsonEncode(cartData);
          final encryptedCartData = _encryptionService.encryptData(cartDataJson);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cartItems', encryptedCartData);

          await _watch.sendMessage({
            'type': 'cartList',
            'data': encryptedCartData,
          });
        }
      } catch (e) {
        debugPrint('Error sending encrypted cart list to watch: $e');
      }
    }
  }

  Future<void> sendCartSummaryToWatch() async {
    final isSupported = await _watch.isSupported;
    final isReachable = await _watch.isReachable;

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
      } catch (e) {
        debugPrint('Failed to send summary to watch: $e');
      }
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
      'Item Added to Cart',
      '$productName has been added to your cart.',
      platformChannelSpecifics,
    );
  }

  Future<void> showRemoveCartNotification(String productName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'cart_channel_id',
      'Cart Notifications',
      channelDescription: 'Notifications when products are removed from cart',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      'Item Removed from Cart',
      '$productName has been removed from your cart.',
      platformChannelSpecifics,
    );
  }
}

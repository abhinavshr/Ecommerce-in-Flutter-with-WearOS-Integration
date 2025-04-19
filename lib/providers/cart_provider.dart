import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice => _items.fold(0.0, (sum, p) => sum + p.price);

  CartProvider() {
    loadCartFromPrefs();
  }

  void addToCart(Product product) {
    if (!_items.any((p) => p.id == product.id)) {
      _items.add(product);
      saveCartToPrefs();
      sendCartSummaryToWatch();
      notifyListeners();
    }
  }

  void removeFromCart(Product product) {
    _items.removeWhere((p) => p.id == product.id);
    saveCartToPrefs();
    sendCartSummaryToWatch();
    notifyListeners();
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
    _items.map((p) => p.toJson()).toList();
    await prefs.setString('cartItems', jsonEncode(jsonList));
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedCart = prefs.getString('cartItems');

    if (cachedCart != null) {
      final List<dynamic> decoded = jsonDecode(cachedCart);
      _items.clear();
      for (var item in decoded) {
        _items.add(Product.fromJson(item));
      }
      notifyListeners();
      sendCartSummaryToWatch();
    }
  }

  Future<void> sendCartSummaryToWatch() async {
    final isSupported = await WatchConnectivity().isSupported;
    final isReachable = await WatchConnectivity().isReachable;

    if (isSupported && isReachable) {
      final summary = {
        'totalItems': itemCount,
        'totalPrice': totalPrice.toStringAsFixed(2),
      };

      await WatchConnectivity().sendMessage(summary);
    }
  }



}

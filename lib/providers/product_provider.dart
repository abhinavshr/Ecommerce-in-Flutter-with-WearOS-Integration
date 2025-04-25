import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../utils/service/encrypt_decrypt_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  final _encryptionService = EncryptDecryptService();

  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedData = prefs.getString('cachedProducts');
    debugPrint("encryptedData:$encryptedData");

    if (encryptedData != null) {
      try {
        final decryptedData = _encryptionService.decryptData(encryptedData);
        final List<dynamic> jsonData = json.decode(decryptedData);
        _products = jsonData.map((item) => Product.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Decryption failed: $e");
        await _fetchFromApi(prefs);
      }
    } else {
      await _fetchFromApi(prefs);
    }
  }

  Future<void> _fetchFromApi(SharedPreferences prefs) async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products'));

      if (response.statusCode == 200) {
        final List productsJson = json.decode(response.body)['products'];
        _products = productsJson.map((json) => Product.fromJson(json)).toList();

        // Cache the data after successful fetch
        final List<Map<String, dynamic>> jsonList =
        _products.map((product) => product.toJson()).toList();
        final jsonString = json.encode(jsonList);
        final encryptedString = _encryptionService.encryptData(jsonString);
        await prefs.setString('cachedProducts', encryptedString);

        notifyListeners();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      debugPrint("Error fetching products from API: $e");
    }
  }

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/products'));
    if (response.statusCode == 200) {
      final List productsJson = json.decode(response.body)['products'];
      _products = productsJson.map((json) => Product.fromJson(json)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load products');
    }
  }
  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

}

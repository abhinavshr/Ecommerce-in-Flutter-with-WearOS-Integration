import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'cart_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('cachedProducts');

    if (cachedData != null) {
      final List<dynamic> jsonData = jsonDecode(cachedData);
      final List<Product> cachedProducts =
      jsonData.map((item) => Product.fromJson(item)).toList();

      Provider.of<ProductProvider>(context, listen: false)
          .setProducts(cachedProducts);
    } else {
      await Provider.of<ProductProvider>(context, listen: false).fetchProducts();

      final products =
          Provider.of<ProductProvider>(context, listen: false).products;

      final List<Map<String, dynamic>> jsonList =
      products.map((product) => product.toJson()).toList();
      await prefs.setString('cachedProducts', jsonEncode(jsonList));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              )
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (ctx, index) {
                final Product product = products[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(product.thumbnail,
                        width: 60, fit: BoxFit.cover),
                    title: Text(product.title),
                    subtitle: Text(product.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: ElevatedButton(
                      onPressed: () {
                        cart.addToCart(product);
                      },
                      child: const Text("Add to Cart"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

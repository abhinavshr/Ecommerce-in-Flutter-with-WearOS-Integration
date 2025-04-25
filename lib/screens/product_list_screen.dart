import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_sample/utils/service/encrypt_decrypt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart'; // Import the cached network image package

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _isLoading = true;
  final _encryptionService = EncryptDecryptService();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedData = prefs.getString('cachedProducts');

    if (encryptedData != null) {
      try {
        final decryptedData = _encryptionService.decryptData(encryptedData);
        final List<dynamic> jsonData = jsonDecode(decryptedData);
        final List<Product> cachedProducts =
        jsonData.map((item) => Product.fromJson(item)).toList();

        Provider.of<ProductProvider>(context, listen: false)
            .setProducts(cachedProducts);
      } catch (e) {
        await Provider.of<ProductProvider>(context, listen: false)
            .fetchProducts();
      }
    } else {
      await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    }

    final products =
        Provider.of<ProductProvider>(context, listen: false).products;

    final List<Map<String, dynamic>> jsonList =
    products.map((product) => product.toJson()).toList();

    final jsonString = jsonEncode(jsonList);
    final encryptedString = _encryptionService.encryptData(jsonString);
    await prefs.setString('cachedProducts', encryptedString);

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
              leading: SizedBox(
                width: 60,
                height: 60,
                child: CachedNetworkImage(
                  imageUrl: product.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              title: Text(product.title),
              subtitle: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import this

import '../providers/cart_provider.dart';
import '../models/product.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              if (cartProvider.itemCount > 0) {
                cartProvider.clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared!')),
                );
              }
            },
          ),
        ],
      ),
      body: cartProvider.itemCount == 0
          ? const Center(child: Text('No items in cart'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.itemCount,
              itemBuilder: (context, index) {
                final product = cartProvider.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                    title: Text(product.title),
                    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () {
                        cartProvider.removeFromCart(product);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: \$${cartProvider.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final Product product = items[i];
          return ListTile(
            leading: Image.network(product.thumbnail,
                width: 60, fit: BoxFit.cover),
            title: Text(product.title),
            subtitle: Text('\$${product.price}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                cart.removeFromCart(product);
              },
            ),
          );
        },
      ),
    );
  }
}

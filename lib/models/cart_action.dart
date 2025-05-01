import 'package:provider_sample/models/product.dart';

class CartAction {
  final String type; // "add" or "remove"
  final Product product;
  final DateTime timestamp;

  CartAction({required this.type, required this.product, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'type': type,
    'product': product.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory CartAction.fromJson(Map<String, dynamic> json) {
    return CartAction(
      type: json['type'],
      product: Product.fromJson(json['product']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

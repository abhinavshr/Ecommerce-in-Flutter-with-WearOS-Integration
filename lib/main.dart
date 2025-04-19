import 'dart:async';
import 'package:flutter/material.dart';
import 'package:is_wear/is_wear.dart';
import 'package:provider/provider.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/product_list_screen.dart';
import 'screens/watch_cart_summary_screen.dart';

bool isWear = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  isWear = (await IsWear().check()) ?? false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cart App',
        home: isWear ? const WatchCartSummaryScreen() : const ProductListScreen(),
      ),
    );
  }
}

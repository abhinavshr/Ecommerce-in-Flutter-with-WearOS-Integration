import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:is_wear/is_wear.dart';
import 'package:provider/provider.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/product_list_screen.dart';
import 'screens/watch_cart_summary_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

bool isWear = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Detect if the device is a Wear OS device
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
        title: 'Shopping App',
        home: isWear ? const WatchCartSummaryScreen() : const ProductListScreen(),
      ),
    );
  }
}

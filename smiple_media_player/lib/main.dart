import 'package:flutter/material.dart';
import 'package:smiple_media_player/router/router_config.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter().appRouter,
      title: 'Simple Media Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

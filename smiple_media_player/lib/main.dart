// import 'package:flutter/material.dart';
// import 'package:smiple_media_player/router/router_config.dart';

// void main() {
//   runApp(const MainApp());
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       debugShowCheckedModeBanner: false,
//       routerConfig: AppRouter().appRouter,
//       title: 'Simple Media Player',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'router/router_config.dart';

void main() {
  runApp(const ProviderScope(child: MediaPlayerApp()));
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Media Player",
      theme: ThemeData.dark(),
      routerConfig: router,
    );
  }
}

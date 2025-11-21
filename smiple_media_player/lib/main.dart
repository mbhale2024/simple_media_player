import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'router/router_config.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    minimumSize: Size(800, 600),
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
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

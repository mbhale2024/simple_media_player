import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smiple_media_player/home_screen.dart';
import 'package:smiple_media_player/player_screen.dart';

class AppRouter {
  final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/player',
          builder: (BuildContext context, GoRouterState state) {
            return const PlayerScreen();
          },
        ),
      ],
    ),
  ],
);
}
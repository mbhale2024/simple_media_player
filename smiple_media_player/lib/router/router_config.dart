import 'package:go_router/go_router.dart';
import '../ui/home_screen.dart';
import '../ui/player/player_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final raw = state.uri.queryParameters['path'] ?? '';

        return PlayerScreen(filePath: raw);
      },
    ),
  ],
);

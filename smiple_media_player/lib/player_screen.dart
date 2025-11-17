import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Screen'),
      ),
      body: const Center(
        child: Text('This is the Player Screen'),
      ),
    );
  }
}
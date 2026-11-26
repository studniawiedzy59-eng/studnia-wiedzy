import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MoviraApp()));
}

class MoviraApp extends StatelessWidget {
  const MoviraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movira',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppGate(),
    );
  }
}

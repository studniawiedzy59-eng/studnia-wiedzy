import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/backend_config.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: backendUrl, anonKey: backendAnonKey);
    backendReady = true;
  } catch (_) {
    // The app still works fully offline without accounts.
  }
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

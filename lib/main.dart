import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: SeaboundApp(),
    ),
  );
}

class SeaboundApp extends ConsumerStatefulWidget {
  const SeaboundApp({super.key});

  @override
  ConsumerState<SeaboundApp> createState() => _SeaboundAppState();
}

class _SeaboundAppState extends ConsumerState<SeaboundApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      precacheImage(const AssetImage('assets/ui/home_bg.jpg'), context);
      precacheImage(const AssetImage('assets/ui/home.png'), context);
      precacheImage(const AssetImage('assets/ui/easter_egg.png'), context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Seabound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

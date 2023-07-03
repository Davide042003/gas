import 'package:gas/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(step: 0), // const HomeScreen()
        redirect: (context, state) async {
          const storage = FlutterSecureStorage();
          FlutterNativeSplash.remove();
          final user = await storage.read(key: 'user');
          if (user == null) {
            return '/onboarding';
          }
          return null;
        },
        routes: <GoRoute>[
        ]),
    GoRoute(
        path: '/onboarding', builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(step: 0)),
  ],
);

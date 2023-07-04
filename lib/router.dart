import 'package:gas/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(step: 0), // const HomeScreen()
        redirect: (context, state) async {
          FlutterNativeSplash.remove();
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return null;
          }else {
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

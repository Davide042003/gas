import 'package:gas/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

final GoRouter router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => HomeScreen(), // const HomeScreen()
        redirect: (context, state) async {
          FlutterNativeSplash.remove();
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return null;
          } else {
            return '/onboarding';
          }
        },
        routes: <GoRoute>[
          GoRoute(
            path: 'profile',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                  transitionDuration: const Duration(milliseconds: 200),
                  child: ProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return Stack(
                      children: <Widget>[
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: const Offset(0.0, 0.0),
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.linear,
                            ),
                          ),
                          child: child,
                        ),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.0),
                            end: const Offset(-1.0, 0.0),
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.linear,
                            ),
                          ),
                          child: HomeScreen(),
                        )
                      ],
                    );
                  });
            },
            routes: <GoRoute>[
              GoRoute(
                  path: 'editProfile',
                  pageBuilder: (context, state) {
                    return CustomTransitionPage(
                        transitionDuration: const Duration(milliseconds: 200),
                        child: ProfileScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return Stack(
                            children: <Widget>[
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: const Offset(0.0, 0.0),
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.linear,
                                  ),
                                ),
                                child: child,
                              ),
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.0),
                                  end: const Offset(-1.0, 0.0),
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.linear,
                                  ),
                                ),
                                child: ProfileScreen(),
                              )
                            ],
                          );
                        });
                  },
              )
            ]

          )
        ]),
    GoRoute(
        path: '/onboarding', builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(step: 0)),
  ],
);

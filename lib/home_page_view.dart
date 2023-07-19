import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gas/publish_post.dart';
import 'package:gas/home_screen.dart';

class HomePageView extends StatefulWidget {
  @override
  _HomePageViewState createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToInitialPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        reverse: true,
        controller: _pageController,
        physics: ClampingScrollPhysics(),
        children: [
          HomeScreen(),
          PublishPostPage(goToInitialPage: goToInitialPage,),
        ],
      ),
    );
  }
}